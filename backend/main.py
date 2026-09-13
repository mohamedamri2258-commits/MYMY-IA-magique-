from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="MYMY-IA API")

# إعدادات CORS للسماح للتطبيق والويب بالاتصال بالخادم بدون قيود
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ChatRequest(BaseModel):
    prompt: str

@app.get("/")
def read_root():
    return {"status": "online", "message": "MYMY-IA Backend is running"}

@app.get("/api/health")
def health_check():
    return {"status": "ok"}

@app.post("/api/chat")
def chat_endpoint(request: ChatRequest):
    if not request.prompt.strip():
        raise HTTPException(status_code=400, detail="Prompt cannot be empty")
    
    # معالجة الطلب والرد (يمكنك ربطه بمحرك الذكاء الاصطناعي الخاص بك)
    reply = f"تم استلام رسالتك بنجاح: {request.prompt}"
    return {"response": reply}
    
