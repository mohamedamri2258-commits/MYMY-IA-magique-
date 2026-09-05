feat(unified): support cloud (OpenAI) and local (Ollama) modes in a single backend

- backend/main.py: unified mode determined by MODE env or per-request ?mode=local
- backend/requirements.txt: add sentence-transformers and torch for local embeddings
- backend/.env.example: unified configuration for both modes
- backend/README.md: updated instructions
- MAGIQUE_IA_STUDIO.html: UI select to choose backend mode and pass mode as query param to backend

