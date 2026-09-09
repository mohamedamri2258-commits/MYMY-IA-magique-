import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from qdrant_client import QdrantClient
from qdrant_client.http import models
import google.generativeai as genai

app = FastAPI(title="MYMY-IA-Magique", version="2.0")

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

    client = None
    try:
        client = QdrantClient(host=os.getenv("QDRANT_HOST", "localhost"), port=int(os.getenv("QDRANT_PORT", 6333)))
        except:
            pass

            class DataItem(BaseModel):
                id: int
                    text: str
                        category: str
                            metadata: dict = {}

                            class SearchQuery(BaseModel):
                                query_text: str
                                    limit: int = 5

                                    @app.get("/")
                                    def read_root():
                                        return {"status": "Online", "message": "Engine is running"}

                                        @app.post("/api/store")
                                        def store_data(item: DataItem):
                                            if not client:
                                                    raise HTTPException(status_code=500, detail="Qdrant not initialized")
                                                        
                                                            col_name = "mymy_erp_memory"
                                                                cols = [c.name for c in client.get_collections().collections]
                                                                    if col_name not in cols:
                                                                            client.create_collection(
                                                                                        collection_name=col_name,
                                                                                                    vectors_config=models.VectorParams(size=4, distance=models.Distance.COSINE)
                                                                                                            )
                                                                                                                
                                                                                                                    client.upsert(
                                                                                                                            collection_name=col_name,
                                                                                                                                    points=[
                                                                                                                                                models.PointStruct(
                                                                                                                                                                id=item.id,
                                                                                                                                                                                vector=[0.1, 0.2, 0.3, 0.4],
                                                                                                                                                                                                payload={"text": item.text, "category": item.category, "metadata": item.metadata}
                                                                                                                                                                                                            )
                                                                                                                                                                                                                    ]
                                                                                                                                                                                                                        )
                                                                                                                                                                                                                            return {"success": True, "id": item.id}

                                                                                                                                                                                                                            @app.post("/api/search")
                                                                                                                                                                                                                            def search_data(search: SearchQuery):
                                                                                                                                                                                                                                if not client:
                                                                                                                                                                                                                                        raise HTTPException(status_code=500, detail="Qdrant not initialized")
                                                                                                                                                                                                                                            
                                                                                                                                                                                                                                                col_name = "mymy_erp_memory"
                                                                                                                                                                                                                                                    try:
                                                                                                                                                                                                                                                            cols = [c.name for c in client.get_collections().collections]
                                                                                                                                                                                                                                                                    if col_name not in cols:
                                                                                                                                                                                                                                                                                return {"results": []}
                                                                                                                                                                                                                                                                                        
                                                                                                                                                                                                                                                                                                records, _ = client.scroll(collection_name=col_name, limit=search.limit, with_payload=True)
                                                                                                                                                                                                                                                                                                        matched = []
                                                                                                                                                                                                                                                                                                                texts = []
                                                                                                                                                                                                                                                                                                                        for r in records:
                                                                                                                                                                                                                                                                                                                                    p = r.payload
                                                                                                                                                                                                                                                                                                                                                txt = p.get("text", "")
                                                                                                                                                                                                                                                                                                                                                            if search.query_text.lower() in txt.lower():
                                                                                                                                                                                                                                                                                                                                                                            matched.append({"id": r.id, "text": txt, "category": p.get("category"), "metadata": p.get("metadata")})
                                                                                                                                                                                                                                                                                                                                                                                            texts.append(txt)
                                                                                                                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                                                                                                                            insights = "No AI key"
                                                                                                                                                                                                                                                                                                                                                                                                                    if GEMINI_API_KEY and texts:
                                                                                                                                                                                                                                                                                                                                                                                                                                try:
                                                                                                                                                                                                                                                                                                                                                                                                                                                model = genai.GenerativeModel('gemini-1.5-flash')
                                                                                                                                                                                                                                                                                                                                                                                                                                                                res = model.generate_content(f"Analyze: {' '.join(texts)} for query: {search.query_text}")
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                insights = res.text
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            except:
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            insights = "AI error"

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    return {"success": True, "results": matched, "ai_insights": insights}
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        except Exception as e:
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                raise HTTPException(status_code=500, detail=str(e))
                                                                                                                                                                                                                                                                                                                                                                                                                                