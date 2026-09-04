from fastapi import FastAPI, UploadFile, File, HTTPException
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

app = FastAPI(title="Magique IA - Backend (FastAPI) - Cloud")

# Configuration via environment
QDRANT_URL = os.getenv("QDRANT_URL", "http://localhost:6333")
QDRANT_API_KEY = os.getenv("QDRANT_API_KEY", "")
COLLECTION_NAME = os.getenv("QDRANT_COLLECTION", "magique_projects")
EMBED_MODEL = os.getenv("EMBED_MODEL", "text-embedding-3-small")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
LLM_MODEL = os.getenv("LLM_MODEL", "gpt-4o-mini")

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
            qdrant.create_collection(collection_name=COLLECTION_NAME, vectors_config=rest_models.VectorParams(size=1536, distance=rest_models.Distance.COSINE))
    except Exception as e:
        print("Qdrant client init failed:", e)
        qdrant = None


# --------- Helpers ---------

def chunk_text(text: str, chunk_size: int = 800, overlap: int = 100):
    """Very simple whitespace chunker by characters (approx)."""
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


async def compute_embedding(text: str) -> Optional[List[float]]:
    """Compute embedding using OpenAI if available. Return None on failure."""
    if openai is None:
        return None
    try:
        resp = openai.Embedding.create(input=text, model=EMBED_MODEL)
        return resp["data"][0]["embedding"]
    except Exception as e:
        print("Embedding error:", e)
        return None


# --------- Schemas ---------
class QueryRequest(BaseModel):
    query: str
    top_k: int = 5


# --------- Endpoints ---------
@app.post("/api/upload")
async def upload_files(files: List[UploadFile] = File(...)):
    """Upload files, chunk text files, compute embeddings, and upsert to Qdrant.
    Returns a summary with inserted points count.
    """
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
                emb = await compute_embedding(chunk)
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
async def query(req: QueryRequest):
    """Query the vector DB and call OpenAI with retrieved context (simple RAG).
    Returns the assistant answer plus sources.
    """
    if qdrant is None:
        raise HTTPException(status_code=500, detail="Qdrant client not configured on server.")
    if openai is None:
        raise HTTPException(status_code=500, detail="OpenAI client not available on server.")

    emb = await compute_embedding(req.query)
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
    return {"ok": True, "qdrant": qdrant is not None, "openai": openai is not None and OPENAI_API_KEY is not None}
