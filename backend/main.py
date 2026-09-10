import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import google.generativeai as genai

app = FastAPI(title="MYMY-IA-Magique", version="3.0")

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

class AgentRequest(BaseModel):
    prompt: str
    task_type: str = "code"

@app.get("/")
def read_root():
    return {"status": "Online", "message": "MYMY-IA-Magique Agent Core is active!"}

@app.post("/api/agent/execute")
def execute_agent_task(req: AgentRequest):
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=400, detail="Gemini API Key is missing on the server.")
    try:
        model = genai.GenerativeModel('gemini-1.5-flash')
        system_prompt = (
            "You are MYMY-IA-Magique, an elite, autonomous AI personal assistant and software engineering agent. "
            "Your goal is to write clean, production-ready code, build full web application structures, "
            "or analyze files deeply based on user intent. Always provide clear, structured, and actionable technical outputs."
        )
        full_prompt = f"{system_prompt}\n\nUser Request: {req.prompt}"
        response = model.generate_content(full_prompt)
        return {
            "success": True,
            "task_type": req.task_type,
            "output": response.text
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 10000))
    uvicorn.run("backend.main:app", host="0.0.0.0", port=port)
