"""
🖥️ Ollama Integration - العمل المحلي بدون إنترنت
Local LLM Support with Offline Capabilities
"""

import os
import json
import subprocess
import httpx
import asyncio
import logging
from typing import Optional, Dict, Any, AsyncGenerator

logger = logging.getLogger(__name__)

class OllamaClient:
    """عميل Ollama للعمل المحلي بدون الحاجة للإنترنت"""
    
    def __init__(self):
        self.base_url = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
        self.default_model = os.getenv("LOCAL_LLM_MODEL", "qwen2.5-coder")
        self.client = httpx.AsyncClient(timeout=300)
        
        logger.info(f"🖥️ Ollama Client initialized - Model: {self.default_model}")
    
    async def check_connection(self) -> bool:
        """التحقق من الاتصال بـ Ollama"""
        try:
            response = await self.client.get(f"{self.base_url}/api/tags")
            return response.status_code == 200
        except Exception as e:
            logger.warning(f"⚠️ Ollama connection failed: {e}")
            return False
    
    async def pull_model(self, model_name: str) -> bool:
        """تحميل نموذج من مكتبة Ollama"""
        try:
            logger.info(f"📥 Pulling model: {model_name}")
            
            async with self.client.stream(
                "POST",
                f"{self.base_url}/api/pull",
                json={"name": model_name},
            ) as response:
                async for line in response.aiter_lines():
                    if line:
                        data = json.loads(line)
                        status = data.get("status", "")
                        logger.info(f"  {status}")
            
            logger.info(f"✅ Model {model_name} pulled successfully")
            return True
        except Exception as e:
            logger.error(f"❌ Error pulling model: {e}")
            return False
    
    async def generate(self, prompt: str, model: Optional[str] = None,
                      stream: bool = False) -> str:
        """توليد نص باستخدام نموذج محلي"""
        try:
            model = model or self.default_model
            
            if stream:
                return await self._generate_streaming(prompt, model)
            else:
                return await self._generate_text(prompt, model)
        except Exception as e:
            logger.error(f"❌ Error generating text: {e}")
            return f"خطأ في توليد النص: {str(e)}"
    
    async def _generate_text(self, prompt: str, model: str) -> str:
        """توليد نص بدون streaming"""
        try:
            response = await self.client.post(
                f"{self.base_url}/api/generate",
                json={
                    "model": model,
                    "prompt": prompt,
                    "stream": False,
                    "options": {
                        "temperature": 0.7,
                        "top_k": 40,
                        "top_p": 0.9,
                        "num_predict": 2000,
                    }
                },
            )
            
            if response.status_code == 200:
                data = response.json()
                return data.get("response", "")
            else:
                logger.error(f"❌ Ollama error: {response.text}")
                return ""
        except Exception as e:
            logger.error(f"❌ Error in text generation: {e}")
            return ""
    
    async def _generate_streaming(self, prompt: str, model: str) -> AsyncGenerator:
        """توليد نص مع streaming"""
        try:
            async with self.client.stream(
                "POST",
                f"{self.base_url}/api/generate",
                json={
                    "model": model,
                    "prompt": prompt,
                    "stream": True,
                    "options": {
                        "temperature": 0.7,
                        "top_k": 40,
                        "top_p": 0.9,
                        "num_predict": 2000,
                    }
                },
            ) as response:
                async for line in response.aiter_lines():
                    if line:
                        data = json.loads(line)
                        yield data.get("response", "")
        except Exception as e:
            logger.error(f"❌ Streaming error: {e}")
            yield f"خطأ: {str(e)}"
    
    async def generate_code(self, requirements: str, language: str = "python") -> str:
        """توليد كود برمجي متخصص"""
        try:
            prompt = f"""أنت مهندس برمجة محترف. اكتب كود {language} يحقق المتطلبات التالية:

المتطلبات:
{requirements}

الكود:"""
            
            return await self._generate_text(prompt, "qwen2.5-coder")
        except Exception as e:
            logger.error(f"❌ Error generating code: {e}")
            return ""
    
    async def debug_code(self, code: str, error: str, language: str) -> str:
        """تصحيح وإصلاح أخطاء برمجية"""
        try:
            prompt = f"""أنت محقق أخطاء برمجية محترف.

لغة البرمجة: {language}

الكود:
```
{code}
```

الخطأ:
{error}

الحل والكود المصحح:"""
            
            return await self._generate_text(prompt, "qwen2.5-coder")
        except Exception as e:
            logger.error(f"❌ Error debugging code: {e}")
            return ""
    
    async def translate_text(self, text: str, source_lang: str, 
                            target_lang: str) -> str:
        """ترجمة النصوص"""
        try:
            prompt = f"""ترجم النص التالي من {source_lang} إلى {target_lang}.

النص الأصلي:
{text}

الترجمة:"""
            
            return await self._generate_text(prompt, self.default_model)
        except Exception as e:
            logger.error(f"❌ Translation error: {e}")
            return ""
    
    async def summarize_text(self, text: str, max_length: int = 500) -> str:
        """تلخيص النصوص الطويلة"""
        try:
            prompt = f"""اكتب ملخص مختصر للنص التالي (بحد أقصى {max_length} كلمة):

النص:
{text}

الملخص:"""
            
            return await self._generate_text(prompt, self.default_model)
        except Exception as e:
            logger.error(f"❌ Summarization error: {e}")
            return ""
    
    async def analyze_sentiment(self, text: str) -> Dict[str, Any]:
        """تحليل الشعور والمشاعر في النص"""
        try:
            prompt = f"""حلل شعور النص التالي وأعد النتيجة بصيغة JSON:
{{
    "sentiment": "positive/negative/neutral",
    "confidence": 0.0-1.0,
    "keywords": []
}}

النص:
{text}

النتيجة JSON:"""
            
            response = await self._generate_text(prompt, self.default_model)
            return json.loads(response) if response else {}
        except Exception as e:
            logger.error(f"❌ Sentiment analysis error: {e}")
            return {}
    
    async def get_available_models(self) -> list:
        """الحصول على قائمة النماذج المتاحة"""
        try:
            response = await self.client.get(f"{self.base_url}/api/tags")
            if response.status_code == 200:
                data = response.json()
                models = [model["name"] for model in data.get("models", [])]
                logger.info(f"📦 Available models: {models}")
                return models
            return []
        except Exception as e:
            logger.error(f"❌ Error getting models: {e}")
            return []
    
    async def optimize_prompt(self, prompt: str) -> str:
        """تحسين الـ prompt لنتائج أفضل"""
        try:
            enhancement = f"""حسن الـ prompt التالي لنتائج أفضل من AI:

Prompt الأصلي:
{prompt}

Prompt المحسّن:"""
            
            return await self._generate_text(enhancement, self.default_model)
        except Exception as e:
            logger.error(f"❌ Error optimizing prompt: {e}")
            return prompt


# إنشاء instance عام
ollama_client = OllamaClient()
