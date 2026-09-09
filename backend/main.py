import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from qdrant_client import QdrantClient
from qdrant_client.http import models

app = FastAPI(title="MYMY-IA-Magique Core Engine", version="1.0")

QDRANT_HOST = os.getenv("QDRANT_HOST", "localhost")
QDRANT_PORT = int(os.getenv("QDRANT_PORT", 6333))

try:
    client = QdrantClient(host=QDRANT_HOST, port=QDRANT_PORT)
    except Exception as e:
        client = None

        class DataItem(BaseModel):
            id: int
                text: str
                    category: str
                        metadata: dict = {}

                        @app.get("/")
                        def read_root():
                            return {"status": "Online", "message": "Core Engine Online"}

                            @app.post("/api/store")
                            def store_data(item: DataItem):
                                if not client:
                                        raise HTTPException(status_code=500, detail="Qdrant client is not initialized")
                                            
                                                collection_name = "mymy_erp_memory"
                                                    
                                                        collections = [col.name for col in client.get_collections().collections]
                                                            if collection_name not in collections:
                                                                    client.create_collection(
                                                                                collection_name=collection_name,
                                                                                            vectors_config=models.VectorParams(size=4, distance=models.Distance.COSINE)
                                                                                                    )
                                                                                                        
                                                                                                            dummy_vector = [0.1, 0.2, 0.3, 0.4]
                                                                                                                
                                                                                                                    client.upsert(
                                                                                                                            collection_name=collection_name,
                                                                                                                                    points=[
                                                                                                                                                models.PointStruct(
                                                                                                                                                                id=item.id,
                                                                                                                                                                                vector=dummy_vector,
                                                                                                                                                                                                payload={"text": item.text, "category": item.category, "metadata": item.metadata}
                                                                                                                                                                                                            )
                                                                                                                                                                                                                    ]
                                                                                                                                                                                                                        )
                                                                                                                                                                                                                            return{"success": True, "message": "Data stored successfully", "id": item.id}
                                        