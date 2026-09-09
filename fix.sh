pkill -9 -f python3; pkill -9 -f uvicorn

rm -rf storage backend/storage .qdrant backend/.qdrant qdrant_storage qdrant_data /tmp/qdrant*

printf "MODE=local\nEMBED_VECTOR_SIZE=384\n" > backend/.env
printf "MODE=local\nEMBED_VECTOR_SIZE=384\n" > .env

EMBED_VECTOR_SIZE=384 MODE=local python3 -m uvicorn backend.main:app --port 8000