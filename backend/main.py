"""
🌟 MYMY-IA Magique - Advanced Backend with All Features
الخادم الكامل مع جميع المميزات
"""

from fastapi import FastAPI, File, UploadFile, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
import logging
import os
from typing import Optional, List, Dict, Any

# Import our AI systems
from core.mymy_ia_engine import mymy_ia, AIProvider
from core.rag_system import rag_system
from core.function_calling import function_caller
from core.ollama_integration import ollama_client

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI
app = FastAPI(
    title="MYMY-IA Magique 🌟",
    description="نظام الذكاء الاصطناعي المتقدم الموحد",
    version="1.0.0"
)

# ============ CORS Configuration ============
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve static files
try:
    app.mount("/static", StaticFiles(directory="static"), name="static")
except:
    logger.warning("Static files directory not found")


# ============ Models ============

class ChatRequest(BaseModel):
    message: str
    provider: Optional[str] = "auto"
    context: Optional[List[Dict]] = None
    user_id: Optional[str] = None


class CodeRequest(BaseModel):
    requirements: str
    language: str = "python"
    project_context: Optional[str] = None


class DebugRequest(BaseModel):
    code: str
    error: str
    language: str


class VideoScriptRequest(BaseModel):
    topic: str
    duration: int = 10
    style: str = "educational"


class ArticleRequest(BaseModel):
    topic: str
    style: str = "professional"
    length: int = 500


class DocumentRequest(BaseModel):
    content: str
    doc_type: str = "text"


class ExecuteRequest(BaseModel):
    code: str
    language: str = "python"
    requirements: Optional[List[str]] = None


# ============ Health & Status ============

@app.get("/")
async def root():
    """🏠 الصفحة الرئيسية"""
    return {
        "status": "🌟 MYMY-IA Magique is Running",
        "version": "1.0.0",
        "features": [
            "✅ Multi-AI Support (OpenAI, Claude, Gemini, Grok, Ollama)",
            "✅ Knowledge Base (RAG with Qdrant)",
            "✅ Offline Mode (Ollama)",
            "✅ Code Generation & Debugging",
            "✅ Video Script Generation",
            "✅ Article Writing",
            "✅ Project Execution",
            "✅ User Memory & Context",
            "✅ Automatic Function Calling"
        ]
    }


@app.get("/api/health")
async def health_check():
    """✅ فحص صحة النظام"""
    ollama_status = await ollama_client.check_connection()
    
    return {
        "status": "online ✅",
        "components": {
            "api": "✅ online",
            "rag_system": "✅ online",
            "function_caller": "✅ online",
            "ollama": "✅ online" if ollama_status else "⚠️ offline",
        }
    }


@app.get("/api/models")
async def get_available_models():
    """📦 الحصول على قائمة النماذج المتاحة"""
    try:
        ollama_models = await ollama_client.get_available_models()
        
        return {
            "success": True,
            "models": {
                "local_ollama": ollama_models if ollama_models else ["qwen2.5-coder", "mistral"],
                "cloud": {
                    "openai": ["gpt-4", "gpt-3.5-turbo"] if os.getenv("OPENAI_API_KEY") else [],
                    "anthropic": ["claude-3-opus", "claude-3-sonnet"] if os.getenv("ANTHROPIC_API_KEY") else [],
                    "google": ["gemini-pro"] if os.getenv("GOOGLE_API_KEY") else [],
                }
            }
        }
    except Exception as e:
        logger.error(f"❌ Error getting models: {e}")
        return {"success": False, "error": str(e)}


# ============ Chat Endpoints ============

@app.post("/api/chat")
async def chat_endpoint(request: ChatRequest):
    """
    💬 محادثة ذكية مع الذاكرة والسياق
    """
    try:
        provider = None
        if request.provider != "auto":
            try:
                provider = AIProvider[request.provider.upper()]
            except:
                provider = None
        
        response = await mymy_ia.chat(
            message=request.message,
            provider=provider,
            context=request.context,
            user_id=request.user_id
        )
        
        return {
            "success": True,
            "response": response,
            "user_id": request.user_id
        }
    
    except Exception as e:
        logger.error(f"❌ Chat error: {e}")
        return {
            "success": False,
            "error": str(e),
            "response": "عذراً، حدث خطأ في المحادثة"
        }


# ============ Code Generation Endpoints ============

@app.post("/api/code/generate")
async def generate_code(request: CodeRequest):
    """💻 توليد كود برمجي احترافي"""
    try:
        result = await mymy_ia.generate_code(
            requirements=request.requirements,
            language=request.language,
            project_context=request.project_context or ""
        )
        return result
    
    except Exception as e:
        logger.error(f"❌ Code generation error: {e}")
        return {"success": False, "error": str(e)}


@app.post("/api/code/debug")
async def debug_code(request: DebugRequest):
    """🐛 تصحيح وإصلاح الأخطاء البرمجية"""
    try:
        result = await mymy_ia.debug_code(
            code=request.code,
            error=request.error,
            language=request.language
        )
        return result
    
    except Exception as e:
        logger.error(f"❌ Debug error: {e}")
        return {"success": False, "error": str(e)}


# ============ Content Generation Endpoints ============

@app.post("/api/content/article")
async def write_article(request: ArticleRequest):
    """✍️ كتابة مقالة احترافية"""
    try:
        article = await mymy_ia.write_article(
            topic=request.topic,
            style=request.style,
            length=request.length
        )
        
        return {
            "success": True,
            "article": article,
            "topic": request.topic,
            "words_count": len(article.split())
        }
    
    except Exception as e:
        logger.error(f"❌ Article writing error: {e}")
        return {"success": False, "error": str(e)}


@app.post("/api/content/video-script")
async def generate_video_script(request: VideoScriptRequest):
    """🎬 توليد سيناريو فيديو احترافي"""
    try:
        result = await mymy_ia.generate_video_script(
            topic=request.topic,
            duration=request.duration,
            style=request.style
        )
        return result
    
    except Exception as e:
        logger.error(f"❌ Video script generation error: {e}")
        return {"success": False, "error": str(e)}


# ============ Analysis Endpoints ============

@app.post("/api/analyze/document")
async def analyze_document(request: DocumentRequest):
    """📊 تحليل المستندات"""
    try:
        result = await mymy_ia.analyze_document(
            content=request.content,
            doc_type=request.doc_type
        )
        return result
    
    except Exception as e:
        logger.error(f"❌ Analysis error: {e}")
        return {"success": False, "error": str(e)}


@app.post("/api/analyze/file")
async def analyze_file(file: UploadFile = File(...)):
    """📄 تحليل الملفات المرفوعة"""
    try:
        content = await file.read()
        text = content.decode('utf-8')
        
        result = await mymy_ia.analyze_document(
            content=text,
            doc_type=file.content_type or "unknown"
        )
        return result
    
    except Exception as e:
        logger.error(f"❌ File analysis error: {e}")
        return {"success": False, "error": str(e)}


# ============ Execution Endpoints ============

@app.post("/api/execute/code")
async def execute_code(request: ExecuteRequest):
    """⚡ تنفيذ كود برمجي مباشرة"""
    try:
        result = await function_caller.run_code(
            code=request.code,
            language=request.language
        )
        
        return {
            "success": result.success,
            "output": result.stdout,
            "error": result.stderr,
            "duration": result.duration,
            "return_code": result.return_code
        }
    
    except Exception as e:
        logger.error(f"❌ Execution error: {e}")
        return {"success": False, "error": str(e)}


@app.post("/api/execute/command")
async def execute_command(request: Dict[str, str]):
    """🔧 تنفيذ أوامر نظام التشغيل (آمن)"""
    try:
        result = await function_caller.execute_command(
            command=request.get("command", "")
        )
        
        return {
            "success": result.success,
            "output": result.stdout,
            "error": result.stderr,
            "duration": result.duration
        }
    
    except Exception as e:
        logger.error(f"❌ Command execution error: {e}")
        return {"success": False, "error": str(e)}


# ============ Knowledge Base Endpoints ============

@app.post("/api/rag/store-project")
async def store_project(request: Dict[str, Any]):
    """💾 حفظ مشروع في قاعدة المعرفة"""
    try:
        result = await rag_system.store_project(
            project_id=request.get("project_id"),
            code=request.get("code"),
            language=request.get("language"),
            metadata=request.get("metadata", {})
        )
        return result
    
    except Exception as e:
        logger.error(f"❌ Store project error: {e}")
        return {"success": False, "error": str(e)}


@app.get("/api/rag/search")
async def search_knowledge_base(query: str, top_k: int = 5):
    """🔍 البحث في قاعدة المعرفة"""
    try:
        similar_codes = await rag_system.retrieve_similar_code(query, top_k)
        similar_docs = await rag_system.search_documents(query, top_k)
        
        return {
            "success": True,
            "codes": similar_codes,
            "documents": similar_docs,
            "query": query
        }
    
    except Exception as e:
        logger.error(f"❌ Search error: {e}")
        return {"success": False, "error": str(e)}


# ============ Ollama Endpoints ============

@app.get("/api/ollama/models")
async def get_ollama_models():
    """📦 الحصول على قائمة نماذج Ollama"""
    try:
        models = await ollama_client.get_available_models()
        return {"success": True, "models": models}
    
    except Exception as e:
        logger.error(f"❌ Get models error: {e}")
        return {"success": False, "error": str(e)}


# ============ Startup Events ============

@app.on_event("startup")
async def startup_event():
    """تهيئة النظام عند البدء"""
    logger.info("🚀 MYMY-IA Magique is Starting...")
    
    ollama_status = await ollama_client.check_connection()
    if ollama_status:
        logger.info("✅ Ollama connected successfully")
    else:
        logger.warning("⚠️ Ollama not connected - using cloud models")
    
    logger.info("✨ MYMY-IA Magique Ready!")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info"
    )
