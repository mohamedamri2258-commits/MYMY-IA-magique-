import os
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.responses import HTMLResponse, PlainTextResponse
from pydantic import BaseModel
import google.generativeai as genai
import httpx

app = FastAPI(title="MYMY-IA-Magique Elite Multi-Model Engine", version="6.0")

# إعداد مفاتيح الـ API (يمكنك ضبطها في إعدادات Render)
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
CLAUDE_API_KEY = os.getenv("CLAUDE_API_KEY", "")
GROK_API_KEY = os.getenv("GROK_API_KEY", "")

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

class GenerationRequest(BaseModel):
    prompt: str
    model: str = "gemini" # gemini, claude, grok

@app.get("/", response_class=HTMLResponse)
def read_root():
    return """
    <!DOCTYPE html>
    <html lang="fr" dir="ltr" id="htmlRoot">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>MYMY-IA-Magique | PWA Elite</title>
        <link rel="manifest" href="/manifest.json">
        <meta name="theme-color" content="#0f172a">
        <style>
            body { background-color: #0f172a; color: #f8fafc; font-family: system-ui, -apple-system, sans-serif; margin: 0; padding: 15px; display: flex; flex-direction: column; align-items: center; min-height: 100vh; }
            .container { width: 100%; max-width: 650px; background: #1e293b; padding: 20px; border-radius: 12px; box-shadow: 0 10px 25px rgba(0,0,0,0.3); box-sizing: border-box; }
            .header-bar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; flex-wrap: wrap; gap: 10px; }
            h1 { color: #38bdf8; font-size: 20px; margin: 0; }
            .controls-group { display: flex; gap: 8px; }
            .select-box { background: #0f172a; color: #fff; border: 1px solid #475569; padding: 6px 10px; border-radius: 6px; cursor: pointer; font-size: 13px; }
            textarea { width: 100%; height: 110px; background: #0f172a; color: #fff; border: 1px solid #475569; border-radius: 8px; padding: 12px; font-size: 15px; margin-bottom: 10px; resize: none; box-sizing: border-box; }
            .actions-row { display: flex; gap: 10px; margin-bottom: 10px; flex-wrap: wrap; }
            .btn { background: #0ea5e9; color: white; border: none; padding: 10px 16px; font-size: 14px; border-radius: 8px; cursor: pointer; font-weight: bold; flex: 1; text-align: center; transition: background 0.2s; }
            .btn:hover { background: #0284c7; }
            .btn-secondary { background: #334155; }
            .btn-secondary:hover { background: #475569; }
            .file-input-wrapper { position: relative; overflow: hidden; display: inline-block; flex: 1; }
            .file-input-wrapper input[type=file] { font-size: 100px; position: absolute; left: 0; top: 0; opacity: 0; cursor: pointer; }
            .output { background: #0f172a; border: 1px solid #334155; padding: 15px; border-radius: 8px; margin-top: 15px; white-space: pre-wrap; min-height: 90px; font-size: 14px; word-break: break-all; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header-bar">
                <h1 id="uiTitle">✨ MYMY-IA-Magique</h1>
                <div class="controls-group">
                    <select class="select-box" id="modelSelect">
                        <option value="gemini">Gemini 1.5</option>
                        <option value="claude">Claude (Anthropic)</option>
                        <option value="grok">Grok (xAI)</option>
                    </select>
                    <select class="select-box" id="langSelect" onchange="changeLanguage()">
                        <option value="fr">FR</option>
                        <option value="en">EN</option>
                        <option value="ar">AR</option>
                    </select>
                </div>
            </div>
            <p id="uiSubtitle" style="color: #94a3b8; font-size: 13px; margin-top:0;">Plateforme multi-modèles et d'IA autonome</p>
            
            <textarea id="promptInput" placeholder="Écrivez votre commande ou décrivez votre projet ici..."></textarea>
            
            <div class="actions-row">
                <div class="btn btn-secondary file-input-wrapper">
                    <span id="btnAttach">📎 Attacher</span>
                    <input type="file" id="fileInput" onchange="handleFileSelect(event)">
                </div>
                <button class="btn btn-secondary" onclick="clearText()" id="btnModifier">🧹 Effacer</button>
                <button class="btn btn-secondary" onclick="downloadHtml()" id="btnDownload">💾 Télécharger HTML</button>
            </div>
            
            <button class="btn" onclick="executeTask()" id="btnExecute">Exécuter avec l'IA</button>
            
            <div class="output" id="outputResult">Le résultat s'affichera ici...</div>
        </div>

        <script>
            const texts = {
                fr: { title: "✨ MYMY-IA-Magique", subtitle: "Plateforme multi-modèles et d'IA autonome", placeholder: "Écrivez votre commande ou décrivez votre projet ici...", attach: "📎 Attacher", modifier: "🧹 Effacer", download: "💾 Télécharger HTML", execute: "Exécuter avec l'IA", waiting: "Traitement en cours... 🤖", result: "Le résultat s'affichera ici..." },
                en: { title: "✨ MYMY-IA-Magique", subtitle: "Multi-model Autonomous AI Platform", placeholder: "Type your command or describe your project here...", attach: "📎 Attach", modifier: "🧹 Clear", download: "💾 Download HTML", execute: "Execute with AI", waiting: "Processing... 🤖", result: "Result will appear here..." },
                ar: { title: "✨ MYMY-IA-Magique", subtitle: "منصة متعددة النماذج والذكاء الاصطناعي الخارق", placeholder: "اكتب أمرك البرمجي أو اطلب تطوير مشروعك هنا...", attach: "📎 إرفاق", modifier: "🧹 مسح", download: "💾 تحميل HTML", execute: "تنفيذ بالذكاء الاصطناعي", waiting: "جاري المعالجة... 🤖", result: "النتيجة ستظهر هنا..." }
            };

            function changeLanguage() {
                const lang = document.getElementById('langSelect').value;
                const root = document.getElementById('htmlRoot');
                root.dir = lang === 'ar' ? 'rtl' : 'ltr';
                root.lang = lang;
                
                document.getElementById('uiTitle').innerText = texts[lang].title;
                document.getElementById('uiSubtitle').innerText = texts[lang].subtitle;
                document.getElementById('promptInput').placeholder = texts[lang].placeholder;
                document.getElementById('btnAttach').innerText = texts[lang].attach;
                document.getElementById('btnModifier').innerText = texts[lang].modifier;
                document.getElementById('btnDownload').innerText = texts[lang].download;
                document.getElementById('btnExecute').innerText = texts[lang].execute;
            }

            function clearText() {
                document.getElementById('promptInput').value = '';
                document.getElementById('fileInput').value = '';
                const lang = document.getElementById('langSelect').value;
                document.getElementById('outputResult').innerText = texts[lang].result;
            }

            function handleFileSelect(event) {
                const file = event.target.files[0];
                if (file) {
                    const reader = new FileReader();
                    reader.onload = function(e) {
                        document.getElementById('promptInput').value += `\\n--- Fichier: ${file.name} ---\\n` + e.target.result;
                    };
                    reader.readAsText(file);
                }
            }

            function downloadHtml() {
                const content = document.getElementById('outputResult').innerText;
                const blob = new Blob([content], { type: 'text/html;charset=utf-8' });
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = 'mymy-ia-project.html';
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                URL.revokeObjectURL(url);
            }

            async function executeTask() {
                const prompt = document.getElementById('promptInput').value;
                const model = document.getElementById('modelSelect').value;
                const output = document.getElementById('outputResult');
                const lang = document.getElementById('langSelect').value;
                
                if(!prompt) { 
                    alert(lang === 'ar' ? 'الرجاء إدخال أمر أولاً' : 'Please enter a prompt first'); 
                    return; 
                }
                
                output.innerText = texts[lang].waiting;
                try {
                    const res = await fetch('/api/v1/execute', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ prompt: prompt, model: model })
                    });
                    const data = await res.json();
                    if(data.success) {
                        output.innerText = data.response;
                    } else {
                        output.innerText = 'Erreur: ' + (data.detail || 'Erreur inconnue');
                    }
                } catch(e) {
                    output.innerText = 'Erreur de connexion: ' + e.message;
                }
            }
        </script>
    </body>
    </html>
    """

@app.get("/manifest.json")
def get_manifest():
    return {
        "name": "MYMY-IA-Magique Elite",
        "short_name": "MYMY-IA",
        "start_url": "/",
        "display": "standalone",
        "background_color": "#0f172a",
        "theme_color": "#0f172a",
        "icons": [
            {
                "src": "https://img.icons8.com/fluents/192/artificial-intelligence.png",
                "sizes": "192x192",
                "type": "image/png"
            }
        ]
    }

@app.post("/api/v1/execute")
async def execute_advanced_task(req: GenerationRequest):
    try:
        if req.model == "gemini":
            if not GEMINI_API_KEY:
                raise HTTPException(status_code=400, detail="Gemini API Key is missing.")
            model = genai.GenerativeModel('gemini-1.5-flash')
            response = model.generate_content(f"You are MYMY-IA-Magique elite developer. Task: {req.prompt}")
            return {"success": True, "response": response.text}
            
        elif req.model == "claude":
            if not CLAUDE_API_KEY:
                raise HTTPException(status_code=400, detail="Claude API Key is missing on server environment variables.")
            async with httpx.AsyncClient() as client:
                resp = await client.post(
                    "https://api.anthropic.com/v1/messages",
                    headers={
                        "x-api-key": CLAUDE_API_KEY,
                        "anthropic-version": "2023-06-01",
                        "content-type": "application/json"
                    },
                    json={
                        "model": "claude-3-5-sonnet-20241022",
                        "max_tokens": 1024,
                        "messages": [{"role": "user", "content": req.prompt}]
                    },
                    timeout=30.0
                )
                data = resp.json()
                text = data["content"][0]["text"] if "content" in data else str(data)
                return {"success": True, "response": text}
                
        elif req.model == "grok":
            if not GROK_API_KEY:
                raise HTTPException(status_code=400, detail="Grok API Key is missing on server environment variables.")
            async with httpx.AsyncClient() as client:
                resp = await client.post(
                    "https://api.x.ai/v1/chat/completions",
                    headers={
                        "Authorization": f"Bearer {GROK_API_KEY}",
                        "content-type": "application/json"
                    },
                    json={
                        "model": "grok-beta",
                        "messages": [{"role": "user", "content": req.prompt}]
                    },
                    timeout=30.0
                )
                data = resp.json()
                text = data["choices"][0]["message"]["content"] if "choices" in data else str(data)
                return {"success": True, "response": text}
        else:
            raise HTTPException(status_code=400, detail="Invalid model selected.")
            
    except Exception as e:
        return {"success": False, "detail": str(e)}
        
        
