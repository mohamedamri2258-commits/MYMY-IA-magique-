import os
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
import google.generativeai as genai

app = FastAPI(title="MYMY-IA-Magique Elite Engine", version="5.0")

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
    <html lang="fr" dir="ltr" id="htmlRoot">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>MYMY-IA-Magique | Elite AI Platform</title>
        <style>
            body { background-color: #0f172a; color: #f8fafc; font-family: system-ui, -apple-system, sans-serif; margin: 0; padding: 15px; display: flex; flex-direction: column; align-items: center; min-height: 100vh; }
            .container { width: 100%; max-width: 650px; background: #1e293b; padding: 20px; border-radius: 12px; box-shadow: 0 10px 25px rgba(0,0,0,0.3); box-sizing: border-box; }
            .header-bar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; }
            h1 { color: #38bdf8; font-size: 22px; margin: 0; }
            .lang-select { background: #0f172a; color: #fff; border: 1px solid #475569; padding: 5px 10px; border-radius: 6px; cursor: pointer; }
            textarea { width: 100%; height: 110px; background: #0f172a; color: #fff; border: 1px solid #475569; border-radius: 8px; padding: 12px; font-size: 15px; margin-bottom: 10px; resize: none; box-sizing: border-box; }
            .actions-row { display: flex; gap: 10px; margin-bottom: 10px; flex-wrap: wrap; }
            .btn { background: #0ea5e9; color: white; border: none; padding: 10px 16px; font-size: 14px; border-radius: 8px; cursor: pointer; font-weight: bold; flex: 1; text-align: center; transition: background 0.2s; }
            .btn:hover { background: #0284c7; }
            .btn-secondary { background: #334155; }
            .btn-secondary:hover { background: #475569; }
            .file-input-wrapper { position: relative; overflow: hidden; display: inline-block; flex: 1; }
            .file-input-wrapper input[type=file] { font-size: 100px; position: absolute; left: 0; top: 0; opacity: 0; cursor: pointer; }
            .output { background: #0f172a; border: 1px solid #334155; padding: 15px; border-radius: 8px; margin-top: 15px; white-space: pre-wrap; min-height: 90px; font-size: 14px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header-bar">
                <h1 id="uiTitle">✨ MYMY-IA-Magique</h1>
                <select class="lang-select" id="langSelect" onchange="changeLanguage()">
                    <option value="fr">Français</option>
                    <option value="en">English</option>
                    <option value="ar">العربية</option>
                </select>
            </div>
            <p id="uiSubtitle" style="color: #94a3b8; font-size: 13px; margin-top:0;">Plateforme d'ingénierie logicielle et d'IA autonome</p>
            
            <textarea id="promptInput" placeholder="Écrivez votre commande ou décrivez votre projet ici..."></textarea>
            
            <div class="actions-row">
                <div class="btn btn-secondary file-input-wrapper">
                    <span id="btnAttach">📎 Attacher un fichier</span>
                    <input type="file" id="fileInput" onchange="handleFileSelect(event)">
                </div>
                <button class="btn btn-secondary" onclick="clearText()" id="btnModifier">🧹 Effacer/Modifier</button>
            </div>
            
            <button class="btn" onclick="executeTask()" id="btnExecute">Exécuter avec l'IA</button>
            
            <div class="output" id="outputResult">Le résultat s'affichera ici...</div>
        </div>

        <script>
            const texts = {
                fr: { title: "✨ MYMY-IA-Magique", subtitle: "Plateforme d'ingénierie logicielle et d'IA autonome", placeholder: "Écrivez votre commande ou décrivez votre projet ici...", attach: "📎 Attacher un fichier", modifier: "🧹 Effacer/Modifier", execute: "Exécuter avec l'IA", waiting: "Traitement en cours par l'IA... 🤖", result: "Le résultat s'affichera ici..." },
                en: { title: "✨ MYMY-IA-Magique", subtitle: "Autonomous Software Engineering & AI Platform", placeholder: "Type your command or describe your project here...", attach: "📎 Attach File", modifier: "🧹 Clear/Edit", execute: "Execute with AI", waiting: "Processing with AI... 🤖", result: "Result will appear here..." },
                ar: { title: "✨ MYMY-IA-Magique", subtitle: "منصة الهندسة البرمجية والذكاء الاصطناعي المتطورة", placeholder: "اكتب أمرك البرمجي أو اطلب تطوير مشروعك هنا...", attach: "📎 إرفاق ملف", modifier: "🧹 مسح / تعديل", execute: "تنفيذ الأمر بالذكاء الاصطناعي", waiting: "جاري المعالجة بواسطة الذكاء الاصطناعي... 🤖", result: "النتيجة ستظهر هنا..." }
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
                document.getElementById('btnExecute').innerText = texts[lang].execute;
                document.getElementById('outputResult').innerText = texts[lang].result;
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
                    const lang = document.getElementById('langSelect').value;
                    document.getElementById('promptInput').value += (lang === 'ar' ? ` [ملف مرفق: ${file.name}]` : ` [Attached file: ${file.name}]`);
                }
            }

            async function executeTask() {
                const prompt = document.getElementById('promptInput').value;
                const output = document.getElementById('outputResult');
                const lang = document.getElementById('langSelect').value;
                
                if(!prompt) { 
                    alert(lang === 'ar' ? 'الرجاء إدخال أمر أولاً' : (lang === 'en' ? 'Please enter a prompt first' : "Veuillez d'entrer une commande d'abord")); 
                    return; 
                }
                
                output.innerText = texts[lang].waiting;
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
        
