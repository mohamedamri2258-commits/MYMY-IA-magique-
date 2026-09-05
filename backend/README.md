# Magique IA - Backend (Unified Cloud/Local) README

This scaffold provides a single FastAPI backend that supports two modes:
- Cloud mode: OpenAI for embeddings & LLM
- Local mode: Ollama for LLM and sentence-transformers for embeddings

Control the mode using the MODE env variable in backend/.env ("cloud" or "local").
You can also override the mode per-request by adding ?mode=local or ?mode=cloud to /api/upload and /api/query.

Setup (local):
1. Start Qdrant: docker compose -f backend/docker-compose.yml up -d
2. Create a Python venv and install dependencies:
   python -m venv .venv && source .venv/bin/activate
   pip install -r backend/requirements.txt
3. Create a .env file from backend/.env.example and set your variables
   - For cloud mode, set OPENAI_API_KEY
   - For local mode, ensure Ollama is running and LOCAL_EMBED_MODEL is set
4. Run the app:
   uvicorn backend.main:app --reload --port 8000
5. Health check: GET http://localhost:8000/api/health

Endpoints:
- POST /api/upload  (multipart form files=...)  Optional query param: ?mode=local
- POST /api/query   (json {query, top_k})        Optional query param: ?mode=local
- GET  /api/health

Notes:
- Ensure EMBED_VECTOR_SIZE matches the embedding model you use (1536 for OpenAI text-embedding-3-small, 384 for all-MiniLM-L6-v2).
- Ollama API behavior may differ by version; adjust call_ollama() if your Ollama returns a different JSON structure.
