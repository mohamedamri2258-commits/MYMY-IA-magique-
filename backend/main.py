import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from qdrant_client import QdrantClient
from qdrant_client.http import models

app = FastAPI(title="MYMY-IA-Magique Core Engine", version="1.0")

# إعداد اتصال Qdrant (سواء كان محلياً أو سحابياً عبر متغيرات البيئة)
QDRANT_HOST = os.getenv("QDRANT_HOST", "localhost")
QDRANT_PORT = int(os.getenv("QDRANT_PORT", 6333))

try:
    client = QdrantClient(host=QDRANT_HOST, port=QDRANT_PORT)
    except Exception as e:
        client = None

        class DataItem(BaseModel):
            id: int
                text: str
                    category: str # مثل: مخازن، أكواد، مستندات، ERP
                        metadata: dict = {}

                        @app.get("/")
                        def read_root():
                            return {"status": "Online", "message": "النظام الذكي الشامل يعمل بنجاح على السحابة!"}

                            @app.post("/api/store")
                            def store_data(item: DataItem):
                                """قاعدة التخزين: حفظ النصوص أو البيانات لتسهيل البحث والتحليل لاحقاً"""
                                    if not client:
                                            raise HTTPException(status_code=500, detail="Qdrant client is not initialized")
                                                
                                                    collection_name = "mymy_erp_memory"
                                                        
                                                            # التأكد من وجود المجموعة في Qdrant
                                                                collections = [col.name for col in client.get_collections().collections]
                                                                    if collection_name not in collections:
                                                                            client.create_collection(
                                                                                        collection_name=collection_name,
                                                                                                    vectors_config=models.VectorParams(size=4, distance=models.Distance.COSINE)
                                                                                                            )
                                                                                                                
                                                                                                                    # محاكاة تخزين المتجهات (يمكن تطويرها لاحقاً لتوليد Embeddings حقيقية)
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
                                                                                                                                                                                                                                        return {"success": True, "message": "تم حفظ وتخزين البيانات في الذاكرة الذكية بنجاح", "id": item.id}