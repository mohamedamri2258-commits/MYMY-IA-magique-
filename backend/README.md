# Magique IA - Backend (Cloud) README

This scaffold provides a minimal FastAPI backend that integrates with Qdrant (local) and OpenAI (embeddings + ChatCompletion).

Setup (local):
1. Start Qdrant: docker compose -f backend/docker-compose.yml up -d
2. Create a Python venv and install dependencies:
   python -m venv .venv && source .venv/bin/activate
   pip install -r backend/requirements.txt
3. Create a .env file from backend/.env.example and set your OPENAI_API_KEY
4. Run the app:
   uvicorn backend.main:app --reload --port 8000
5. Health check: GET http://localhost:8000/api/health

Endpoints:
- POST /api/upload  (multipart form files=...)
- POST /api/query   (json {query, top_k})
- GET  /api/health

