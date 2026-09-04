from fastapi import FastAPI, UploadFile, File, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import uuid
import json
from typing import List, Optional

# External clients
try:
    from qdrant_client import QdrantClient
    from qdrant_client.http.models import PointStruct
    from qdrant_client.http import models as rest_models
except Exception:
    QdrantClient = None

try:
    import openai
except Exception:
    openai = None

import requests

app = FastAPI(title="Magique IA - Backend (FastAPI) - Unified Cloud/Local")

# Add CORS middleware so the frontend served from another origin can call the API during testing
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # for local testing; restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration via environment
QDRANT_URL = os.getenv("QDRANT_URL", "http://localhost:6333")
QDRANT_API_KEY = os.getenv("QDRANT_API_KEY", "")
COLLECTION_NAME = os.getenv("QDRANT_COLLECTION", "magique_projects")

# MODE: 'cloud' for OpenAI, 'local' for Ollama + sentence-transformers
MODE = os.getenv("MODE", "cloud")

# OpenAI settings
EMBED_MODEL = os.getenv("EMBED_MODEL", "text-embedding-3-small")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
LLM_MODEL = os.getenv("LLM_MODEL", "gpt-4o-mini")

# Local LLM (Ollama) settings
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama-3")

# Embedding vector size must match the model used
# For OpenAI text-embedding-3-small -> 1536
# For sentence-transformers all-MiniLM-L6-v2 -> 384
EMBED_VECTOR_SIZE = int(os.getenv("EMBED_VECTOR_SIZE", "1536"))

if openai and OPENAI_API_KEY:
    openai.api_key = OPENAI_API_KEY

# Simple local storage for uploaded files
STORAGE_PATH = os.getenv("STORAGE_PATH", "./storage")
os.makedirs(STORAGE_PATH, exist_ok=True)

# Initialize Qdrant client if available
qdrant = None
if QDRANTClient:
    try:
        qdrant = QdrantClient(url=QDRANT_URL, api_key=QDRANT_API_KEY or None)
        # Ensure collection exists (creates if missing)
        try:
            qdrant.get_collection(COLLECTION_NAME)
        except Exception:
            qdrant.create_collection(collection_name=COLLECTION_NAME, vectors_config=rest_models.VectorParams(size=EMBED_VECTOR_SIZE, distance=rest_models.Distance.COSINE))
    except Exception as e:
        print("Qdrant client init failed:", e)
        qdrant = None


# --------- Helpers ---------

def chunk_text(text: str, chunk_size: int = 800, overlap: int = 100):
    """Very simple character chunker (approx)."""
    text = text.replace("\r\n", "\n")
    start = 0
    chunks = []
    L = len(text)
    while start < L:
        end = start + chunk_size
        chunk = text[start:end]
        chunks.append(chunk)
        start = end - overlap
        if start < 0:
            start = 0
    return chunks


# Local embedding using sentence-transformers
_local_embedding_model = None

def get_local_embedding_model():
    global _local_embedding_model
    if _local_embedding_model is None:
        try:
            from sentence_transformers import SentenceTransformer
            _local_embedding_model = SentenceTransformer(os.getenv('LOCAL_EMBED_MODEL', 'all-MiniLM-L6-v2'))
        except Exception as e:
            print('Failed to load local embedding model:', e)
            _local_embedding_model = None
    return _local_embedding_model


async def compute_embedding(text: str, mode_override: Optional[str] = None) -> Optional[List[float]]:
    """Compute embedding using OpenAI (cloud) or sentence-transformers (local) depending on MODE or mode_override."""
    mode = (mode_override or MODE).lower()
    if mode == 'local':
        model = get_local_embedding_model()
        if model is None:
            return None
        try:
            vec = model.encode(text).tolist()
            return vec
        except Exception as e:
            print('Local embedding error:', e)
            return None
    else:
        # cloud (OpenAI)
        if openai is None:
            return None
        try:
            resp = openai.Embedding.create(input=text, model=EMBED_MODEL)
            return resp["data"][0]["embedding"]
        except Exception as e:
            print("OpenAI embedding error:", e)
            return None


# Local LLM via Ollama

def call_ollama(prompt: str) -> str:
    try:
        url = OLLAMA_URL.rstrip('/') + '/api/generate'
        payload = {
            "model": OLLAMA_MODEL,
            "prompt": prompt,
            "max_tokens": 800,
            "temperature": 0.2
        }
        r = requests.post(url, json=payload, timeout=30)
        r.raise_for_status()
        data = r.json()
        # Ollama responses may vary; attempt common keys
        if isinstance(data, dict):
            # common structure: { 'id':..., 'object':..., 'model':..., 'choices': [{'text': '...'}] }
            if 'choices' in data and isinstance(data['choices'], list) and data['choices']:
                c = data['choices'][0]
                # Ollama may return 'message' or 'text'
                if isinstance(c, dict):
                    return c.get('text') or c.get('message') or json.dumps(c)
            # or some Ollama returns {'generated_text': '...'}
            if 'generated_text' in data:
                return data['generated_text']
        return json.dumps(data)
    except Exception as e:
        print('Ollama call failed:', e)
        return ''


# --------- Schemas ---------
class QueryRequest(BaseModel):
    query: str
    top_k: int = 5


# --------- Endpoints ---------
@app.post("/api/upload")
async def upload_files(request: Request, files: List[UploadFile] = File(...)):
    """Upload files, chunk text files, compute embeddings, and upsert to Qdrant.
    Mode can be overridden per-request with ?mode=local or ?mode=cloud
    Returns a summary with inserted points count.
    """
    mode_override = request.query_params.get('mode')
    if qdrant is None:
        raise HTTPException(status_code=500, detail="Qdrant client not configured on server.")

    inserted = 0
    for f in files:
        contents = await f.read()
        fname = f.filename
        path = os.path.join(STORAGE_PATH, f"{uuid.uuid4()}_{fname}")
        with open(path, "wb") as fh:
            fh.write(contents)

        # Try treat as text
        try:
            text = contents.decode("utf-8")
        except Exception:
            text = None

        if text:
            chunks = chunk_text(text)
            points = []
            for i, chunk in enumerate(chunks):
                emb = await compute_embedding(chunk, mode_override=mode_override)
                if emb is None:
                    continue
                pid = f"{uuid.uuid4()}"
                payload = {"file": fname, "chunk_index": i, "text": chunk}
                points.append(PointStruct(id=pid, vector=emb, payload=payload))
            # Upsert
            if points:
                qdrant.upsert(collection_name=COLLECTION_NAME, points=points)
                inserted += len(points)

    return {"status": "ok", "inserted_chunks": inserted}


@app.post("/api/query")
async def query(request: Request, req: QueryRequest):
    """Query the vector DB and call the LLM with retrieved context (RAG).
    Mode can be overridden per-request with ?mode=local or ?mode=cloud
    Returns the assistant answer plus sources.
    """
    mode_override = request.query_params.get('mode')
    if qdrant is None:
        raise HTTPException(status_code=500, detail="Qdrant client not configured on server.")

    emb = await compute_embedding(req.query, mode_override=mode_override)
    if emb is None:
        raise HTTPException(status_code=500, detail="Failed to compute query embedding.")

    hits = qdrant.search(collection_name=COLLECTION_NAME, query_vector=emb, limit=req.top_k, with_payload=True)
    context_texts = []
    sources = []
    for h in hits:
        payload = h.payload or {}
        txt = payload.get("text") or ""
        file = payload.get("file")
        idx = payload.get("chunk_index")
        context_texts.append(f"--- Source: {file} (chunk {idx})\n{txt}")
        sources.append({"file": file, "chunk_index": idx, "score": getattr(h, 'score', None)})

    # Build prompt
    system_prompt = "Tu es l'assistant Magique IA. Utilise les sources fournies pour répondre de manière concise en français."
    context = "\n\n".join(context_texts[: req.top_k])
    user_message = f"Question: {req.query}\n\nContexte:\n{context}"

    mode = (mode_override or MODE).lower()
    answer = ''
    if mode == 'local':
        # call local LLM (Ollama)
        prompt = system_prompt + "\n\n" + user_message
        answer = call_ollama(prompt)
    else:
        # cloud OpenAI
        if openai is None:
            raise HTTPException(status_code=500, detail="OpenAI client not available on server.")
        try:
            completion = openai.ChatCompletion.create(
                model=LLM_MODEL,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message},
                ],
                max_tokens=800,
                temperature=0.2,
            )
            answer = completion["choices"][0]["message"]["content"]
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"LLM call failed: {e}")

    return {"answer": answer, "sources": sources}


@app.get("/api/health")
async def health():
    return {
        "ok": True,
        "qdrant": qdrant is not None,
        "openai_configured": openai is not None and OPENAI_API_KEY is not None,
        "mode": MODE,
        "ollama_url": OLLAMA_URL,
        "embed_vector_size": EMBED_VECTOR_SIZE,
    }
