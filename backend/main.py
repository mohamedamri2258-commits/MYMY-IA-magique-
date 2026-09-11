import os
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
import google.generativeai as genai
import anthropic
import requests

app = FastAPI(title="MYMY-IA-Magique Elite Engine", version="4.5")

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
CLAUDE_API_KEY = os.getenv("CLAUDE_API_KEY", "")
GROK_API_KEY = os.getenv("GROK_API_KEY", "")

if GEMINI_API_KEY:
    try:
        genai.configure(api_key=GEMINI_API_KEY)
    except Exception:
        pass

class AdvancedRequest(BaseModel):
    prompt: str
    task_type: str = "general"
    model: str = "gemini"
    project_context: str = "" # مخصص لتعديل أو إضافة ملاحظات للمشاريع السابقة

@app.post("/api/v1/execute")
def execute_advanced_task(req: AdvancedRequest):
    try:
        combined_prompt = req.prompt
        if req.project_context:
            combined_prompt = f"Context/Previous Project:\n{req.project_context}\n\nModification/New Request:\n{req.prompt}"

        # 1. Gemini
        if req.model == "gemini":
            if not GEMINI_API_KEY:
                raise HTTPException(status_code=400, detail="مفتاح Gemini API غير موجود في إعدادات Render البيئية.")
            model = genai.GenerativeModel('gemini-1.5-flash')
            response = model.generate_content(combined_prompt)
            return {"success": True, "response": response.text, "model": "Gemini"}

        # 2. Claude
        elif req.model == "claude":
            if not CLAUDE_API_KEY:
                raise HTTPException(status_code=400, detail="مفتاح Claude API غير موجود في إعدادات Render البيئية.")
            client = anthropic.Anthropic(api_key=CLAUDE_API_KEY)
            message = client.messages.create(
                model="claude-3-5-sonnet-20241022",
                max_tokens=2048,
                messages=[{"role": "user", "content": combined_prompt}]
            )
            return {"success": True, "response": message.content[0].text, "model": "Claude"}

        # 3. Grok
        elif req.model == "grok":
            if not GROK_API_KEY:
                raise HTTPException(status_code=400, detail="مفتاح Grok API غير موجود في إعدادات Render البيئية.")
            headers = {"Authorization": f"Bearer {GROK_API_KEY}", "Content-Type": "application/json"}
            payload = {"model": "grok-beta", "messages": [{"role": "user", "content": combined_prompt}], "stream": False}
            res = requests.post("https://api.x.ai/v1/chat/completions", json=payload, headers=headers)
            if res.status_code != 200:
                raise HTTPException(status_code=500, detail=f"Grok Error: {res.text}")
            return {"success": True, "response": res.json()["choices"][0]["message"]["content"], "model": "Grok"}

        # 4. Ollama المحلي
        elif req.model == "ollama":
            ollama_url = os.getenv("OLLAMA_HOST", "http://localhost:11434/api/generate")
            payload = {"model": "llama3", "prompt": combined_prompt, "stream": False}
            try:
                res = requests.post(ollama_url, json=payload, timeout=10)
                if res.status_code != 200:
                    raise Exception(res.text)
                answer = res.json().get("response", "")
                return {"success": True, "response": answer, "model": "Ollama (Local)"}
            except Exception as e:
                return {"success": True, "response": "⚠️ تنبيه: لم يتم العثور على خادم Ollama المحلي على هذا الجهاز/الشبكة. تأكد من تشغيل التطبيق محلياً للاتصال به، أو استخدم النماذج السحابية حالياً.", "model": "Ollama (Offline)"}

        else:
            raise HTTPException(status_code=400, detail="النموذج المحدد غير معروف.")

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# تقديم الواجهة من ملف index.html المستقل
if os.path.exists("index.html"):
    from fastapi.responses import HTMLResponse
    @app.get("/", response_class=HTMLResponse)
    def serve_frontend():
        with open("index.html", "r", encoding="utf-8") as f:
            return f.read()
            
