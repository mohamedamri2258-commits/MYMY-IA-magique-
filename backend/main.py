from fastapi import FastAPI, Header, HTTPException, Request, Depends
from typing import Optional
import os

app = FastAPI(title="Magique IA - Backend Unifié")

# --- 1. نظام الأمان والمصادقة الرقمية ---
def verifier_droits_maintenance(x_device_model: Optional[str] = Header(None), request: Request = None):
    """
    قفل حقوق الصيانة والتعديل حصرياً لجهاز Infinix أو حاسوب الإدارة (PC).
    """
    admin_ip = "192.168.1.100"  # عنوان IP الخاص بحاسوب الإدارة
    client_ip = request.client.host
    
    is_infinix = x_device_model and "infinix" in x_device_model.lower()
    is_admin_pc = client_ip == admin_ip
    
    if not (is_infinix or is_admin_pc):
        raise HTTPException(
            status_code=403, 
            detail="Accès refusé. La maintenance est strictement réservée à l'appareil Infinix ou au PC administrateur."
        )
    return True

def autorisation_numerique(email_auth: Optional[str] = Header(None), request: Request = None):
    """
    زر المصادقة الرقمية عبر الإيميل أو IP (بديل للختم المادي).
    """
    client_ip = request.client.host
    valid_emails = ["admin@entreprise.com", "mohamed@entreprise.com"]
    
    if email_auth not in valid_emails and client_ip != "192.168.1.100":
        raise HTTPException(status_code=401, detail="Autorisation numérique requise (Email ou IP valide).")
    return True

# --- 2. نقاط الاتصال (Endpoints) للذكاء الاصطناعي ---
@app.post("/api/query")
async def traiter_requete_ia(query_data: dict, mode: str = "local"):
    """
    المحرك الأساسي للذكاء الاصطناعي (يدعم Ollama محلياً أو OpenAI سحابياً)
    """
    user_prompt = query_data.get('query', '')
    
    if mode == "local":
        # logic for local LLM (Ollama) & Qdrant retrieval
        reponse_ia = f"[Mode Local] Traitement de : {user_prompt}"
    else:
        # logic for cloud LLM (OpenAI)
        reponse_ia = f"[Mode Cloud] Traitement de : {user_prompt}"
        
    return {"response": reponse_ia, "status": "success"}

@app.post("/api/maintenance")
async def configurer_systeme(request: Request, x_device_model: str = Header(None)):
    """
    نقطة وصول خاصة بالصيانة (محمية).
    """
    verifier_droits_maintenance(x_device_model, request)
    return {"message": "Accès de maintenance accordé. Système prêt pour la mise à jour."}
    
