"""
🧠 RAG System - قاعدة المعرفة الذكية
Retrieval Augmented Generation with Qdrant Vector Database
"""

import os
from typing import List, Dict, Any
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct
from sentence_transformers import SentenceTransformer
import uuid
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

class RAGSystem:
    """نظام قاعدة المعرفة والذاكرة المتقدم"""
    
    def __init__(self):
        """تهيئة نظام RAG"""
        self.qdrant_url = os.getenv("QDRANT_URL", "http://localhost:6333")
        self.vector_size = int(os.getenv("EMBED_VECTOR_SIZE", "384"))
        
        # الاتصال بـ Qdrant
        self.client = QdrantClient(url=self.qdrant_url)
        
        # نموذج التضمين المحلي (بدون الحاجة للإنترنت)
        self.embedding_model = SentenceTransformer(
            'sentence-transformers/all-MiniLM-L6-v2'
        )
        
        # تهيئة المجموعات
        self._initialize_collections()
        
        logger.info("✅ RAG System initialized successfully")
    
    def _initialize_collections(self):
        """إنشاء مجموعات Qdrant للتخزين"""
        collections = [
            "projects",      # المشاريع والكود
            "documents",     # المستندات والملفات
            "user_memory",   # ذاكرة المستخدم والتفضيلات
            "conversations", # السجلات الحوارية
            "errors",        # قاعدة الأخطاء المحفوظة
        ]
        
        for collection_name in collections:
            try:
                self.client.get_collection(collection_name)
                logger.info(f"📦 Collection '{collection_name}' exists")
            except:
                # إنشاء مجموعة جديدة
                self.client.create_collection(
                    collection_name=collection_name,
                    vectors_config=VectorParams(
                        size=self.vector_size,
                        distance=Distance.COSINE
                    ),
                )
                logger.info(f"✨ Collection '{collection_name}' created")
    
    async def store_project(self, project_id: str, code: str, 
                           language: str, metadata: Dict[str, Any]):
        """حفظ مشروع في قاعدة المعرفة"""
        try:
            # تحويل الكود إلى vector
            embedding = self.embedding_model.encode(code).tolist()
            
            # حفظ في Qdrant
            point = PointStruct(
                id=str(uuid.uuid4()),
                vector=embedding,
                payload={
                    "project_id": project_id,
                    "code": code[:1000],  # حفظ أول 1000 حرف
                    "language": language,
                    "metadata": metadata,
                    "timestamp": datetime.utcnow().isoformat(),
                    "full_code_hash": hash(code),
                }
            )
            
            self.client.upsert(
                collection_name="projects",
                points=[point]
            )
            
            logger.info(f"💾 Project '{project_id}' stored in RAG")
            return {"status": "success", "id": point.id}
        
        except Exception as e:
            logger.error(f"❌ Error storing project: {e}")
            return {"status": "error", "message": str(e)}
    
    async def retrieve_similar_code(self, query: str, top_k: int = 3) -> List[Dict]:
        """البحث عن أكواد مشابهة في قاعدة المعرفة"""
        try:
            # تحويل الاستعلام إلى vector
            query_embedding = self.embedding_model.encode(query).tolist()
            
            # البحث في Qdrant
            results = self.client.search(
                collection_name="projects",
                query_vector=query_embedding,
                limit=top_k,
            )
            
            similar_codes = []
            for result in results:
                similar_codes.append({
                    "id": result.id,
                    "score": result.score,
                    "language": result.payload.get("language"),
                    "code_preview": result.payload.get("code", "")[:500],
                    "metadata": result.payload.get("metadata"),
                    "timestamp": result.payload.get("timestamp"),
                })
            
            logger.info(f"🔍 Found {len(similar_codes)} similar codes")
            return similar_codes
        
        except Exception as e:
            logger.error(f"❌ Error retrieving similar code: {e}")
            return []
    
    async def store_document(self, doc_id: str, content: str, 
                            doc_type: str, source: str):
        """حفظ مستند أو ملف تم تحليله"""
        try:
            embedding = self.embedding_model.encode(content).tolist()
            
            point = PointStruct(
                id=str(uuid.uuid4()),
                vector=embedding,
                payload={
                    "doc_id": doc_id,
                    "content": content[:2000],
                    "type": doc_type,
                    "source": source,
                    "timestamp": datetime.utcnow().isoformat(),
                }
            )
            
            self.client.upsert(
                collection_name="documents",
                points=[point]
            )
            
            logger.info(f"📄 Document '{doc_id}' stored")
            return {"status": "success", "id": point.id}
        
        except Exception as e:
            logger.error(f"❌ Error storing document: {e}")
            return {"status": "error", "message": str(e)}
    
    async def search_documents(self, query: str, top_k: int = 5) -> List[Dict]:
        """البحث في المستندات المحفوظة"""
        try:
            query_embedding = self.embedding_model.encode(query).tolist()
            
            results = self.client.search(
                collection_name="documents",
                query_vector=query_embedding,
                limit=top_k,
            )
            
            documents = []
            for result in results:
                documents.append({
                    "id": result.id,
                    "score": result.score,
                    "type": result.payload.get("type"),
                    "source": result.payload.get("source"),
                    "content_preview": result.payload.get("content", "")[:300],
                    "timestamp": result.payload.get("timestamp"),
                })
            
            return documents
        
        except Exception as e:
            logger.error(f"❌ Error searching documents: {e}")
            return []
    
    async def remember_user_preference(self, user_id: str, preference: str, value: Any):
        """تذكر تفضيلات المستخدم"""
        try:
            embedding = self.embedding_model.encode(f"{preference}: {value}").tolist()
            
            point = PointStruct(
                id=str(uuid.uuid4()),
                vector=embedding,
                payload={
                    "user_id": user_id,
                    "preference": preference,
                    "value": str(value),
                    "timestamp": datetime.utcnow().isoformat(),
                }
            )
            
            self.client.upsert(
                collection_name="user_memory",
                points=[point]
            )
            
            logger.info(f"🧠 User preference saved for {user_id}")
            return True
        
        except Exception as e:
            logger.error(f"❌ Error saving preference: {e}")
            return False
    
    async def get_user_context(self, user_id: str) -> Dict[str, Any]:
        """استرجاع سياق المستخدم والتفضيلات المحفوظة"""
        try:
            results = self.client.scroll(
                collection_name="user_memory",
                limit=100,
                with_payload=True,
            )
            
            user_prefs = {}
            for point, _ in results[0]:
                if point.payload.get("user_id") == user_id:
                    pref = point.payload.get("preference")
                    value = point.payload.get("value")
                    user_prefs[pref] = value
            
            return user_prefs
        
        except Exception as e:
            logger.error(f"❌ Error getting user context: {e}")
            return {}
    
    async def store_error_solution(self, error_type: str, error_msg: str, 
                                   solution: str, language: str):
        """حفظ حل خطأ برمجي في قاعدة الأخطاء"""
        try:
            embedding = self.embedding_model.encode(
                f"{error_type}: {error_msg}"
            ).tolist()
            
            point = PointStruct(
                id=str(uuid.uuid4()),
                vector=embedding,
                payload={
                    "error_type": error_type,
                    "error_message": error_msg[:500],
                    "solution": solution[:1000],
                    "language": language,
                    "timestamp": datetime.utcnow().isoformat(),
                }
            )
            
            self.client.upsert(
                collection_name="errors",
                points=[point]
            )
            
            logger.info(f"🔧 Error solution stored for {error_type}")
            return True
        
        except Exception as e:
            logger.error(f"❌ Error storing solution: {e}")
            return False
    
    async def find_error_solution(self, error_msg: str, language: str) -> Dict:
        """البحث عن حل لخطأ برمجي معين"""
        try:
            query_embedding = self.embedding_model.encode(error_msg).tolist()
            
            results = self.client.search(
                collection_name="errors",
                query_vector=query_embedding,
                limit=1,
            )
            
            if results:
                result = results[0]
                return {
                    "error_type": result.payload.get("error_type"),
                    "solution": result.payload.get("solution"),
                    "confidence": result.score,
                    "language": result.payload.get("language"),
                }
            
            return {"error_type": "Unknown", "solution": None}
        
        except Exception as e:
            logger.error(f"❌ Error finding solution: {e}")
            return {}
    
    async def clear_old_data(self, days: int = 30):
        """حذف البيانات القديمة (أكثر من X أيام)"""
        try:
            from datetime import timedelta
            cutoff_time = (datetime.utcnow() - timedelta(days=days)).isoformat()
            
            # حذف من المشاريع
            self.client.delete(
                collection_name="projects",
                points_selector={"filter": {"key": "timestamp", "range": {"lte": cutoff_time}}}
            )
            
            logger.info(f"🧹 Cleaned up data older than {days} days")
            return True
        
        except Exception as e:
            logger.error(f"❌ Error cleaning up data: {e}")
            return False


# إنشاء instance عام
rag_system = RAGSystem()
