import os
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
import google.generativeai as genai

app = FastAPI(title="MYMY-IA-Magique Elite Engine", version="4.0")

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

class AdvancedRequest(BaseModel):
    prompt: str
    task_type: str

@app.get("/", response_class=HTMLResponse)
def read_root():
    return """
    <!DOCTYPE html>
    <html lang="ar" dir="rtl">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>MYMY-IA-Magique | منصة الذكاء الاصطناعي الخارقة</title>
        <style>
            body { background-color: #0f172a; color: #f8fafc; font-family: system-ui, -apple-system, sans-serif; margin: 0; padding: 20px; display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 100vh; }
            .container { width: 100%; max-width: 600px; background: #1e293b; padding: 20px; border-radius: 12px; box-shadow: 0 10px 25px rgba(0,0,0,0.3); }
            h1 { color: #38bdf8; text-align: center; font-size: 24px; }
            textarea { width: 100%; height: 120px; background: #0f172a; color: #fff; border: 1px solid #475569; border-radius: 8px; padding: 12px; font-size: 16px; margin-bottom: 10px; resize: none; box-sizing: border-box; }
            button { background: #0ea5e9; color: white; border: none; padding: 12px 20px; font-size: 16px; border-radius: 8px; cursor: pointer; width: 100%; font-weight: bold; }
            button:hover { background: #0284c7; }
            .output { background: #0f172a; border: 1px solid #334155; padding: 15px; border-radius: 8px; margin-top: 15px; white-space: pre-wrap; min-height: 80px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>✨ MYMY-IA-Magique</h1>
            <p style="text-align: center; color: #94a3b8; font-size: 14px;">منصة الهندسة البرمجية والذكاء الاصطناعي المتطورة</p>
            <textarea id="promptInput" placeholder="اكتب أمرك البرمجي أو اطلب تطوير مشروعك هنا..."></textarea>
            <button onclick="executeTask()">تنفيذ الأمر بالذكاء الاصطناعي</button>
            <div class="output" id="outputResult">النتيجة ستظهر هنا...</div>
        </div>
        <script>
            async function executeTask() {
                const prompt = document.getElementById('promptInput').value;
                const output = document.getElementById('outputResult');
                if(!prompt) { alert('الرجاء إدخال أمر أولاً'); return; }
                output.innerText = 'جاري المعالجة بواسطة الذكاء الاصطناعي... 🤖';
                try {
                    const res = await fetch('/api/v1/execute', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ prompt: prompt, task_type: 'general_development' })
                    });
                    const data = await res.json();
                    if(data.success) {
                        output.innerText = data.response;
                    } else {
                        output.innerText = 'خطأ: ' + (data.detail || 'حدث خطأ غير معروف');
                    }
                } catch(e) {
                    output.innerText = 'فشل الاتصال بالسيرفر: ' + e.message;
                }
            }
        </script>
    </body>
    </html>
    """

@app.post("/api/v1/execute")
def execute_advanced_task(req: AdvancedRequest):
    if not GEMINI_API_KEY:
        return {"success": False, "detail": "Gemini API Key is not configured on the server environment variables."}
    try:
        model = genai.GenerativeModel('gemini-1.5-flash')
        system_instructions = "You are MYMY-IA-Magique, an elite autonomous AI software engineering agent."
        response = model.generate_content(f"{system_instructions}\n\nTask: {req.prompt}")
        return {"success": True, "response": response.text}
    except Exception as e:
        return {"success": False, "detail": str(e)}
        
