"""
🌟 Multi-AI System - نظام الذكاء الاصطناعي الموحد
Unified AI Engine with Multiple Models Integration
"""

import os
import asyncio
import logging
from typing import Optional, Dict, Any, List
from enum import Enum

# Import AI integrations
from core.ollama_integration import ollama_client
from core.rag_system import rag_system
from core.function_calling import function_caller

logger = logging.getLogger(__name__)


class AIProvider(Enum):
    """مزودو خدمات الذكاء الاصطناعي"""
    OLLAMA = "ollama"           # 🖥️ محلي بدون إنترنت
    OPENAI = "openai"           # 🔵 ChatGPT-4/5
    ANTHROPIC = "anthropic"     # 🤖 Claude
    GOOGLE = "google"           # 🔍 Gemini
    GROQ = "groq"              # ⚡ Grok


class MyMYIAMagique:
    """
    نظام MYMY-IA Magique الذكي المتقدم
    
    المميزات:
    ✅ Multiple AI Models (OpenAI, Claude, Gemini, Grok, Ollama)
    ✅ Knowledge Base (RAG with Qdrant)
    ✅ Offline Mode (Ollama Local)
    ✅ Code Generation & Debugging
    ✅ Automatic Function Calling
    ✅ Video Script Generation
    ✅ Project Execution
    ✅ User Memory & Context
    """
    
    def __init__(self):
        self.primary_ai = os.getenv("MODE", "hybrid")  # cloud, local, hybrid
        self.rag = rag_system
        self.function_caller = function_caller
        self.ollama = ollama_client
        
        # Initialize API clients
        self._init_cloud_clients()
        
        logger.info("🌟 MYMY-IA Magique System Initialized")
    
    def _init_cloud_clients(self):
        """تهيئة عملاء API السحابية"""
        try:
            # OpenAI
            if os.getenv("OPENAI_API_KEY"):
                import openai
                openai.api_key = os.getenv("OPENAI_API_KEY")
                self.openai_client = openai
                logger.info("✅ OpenAI initialized")
        except Exception as e:
            logger.warning(f"⚠️ OpenAI initialization failed: {e}")
        
        try:
            # Anthropic (Claude)
            if os.getenv("ANTHROPIC_API_KEY"):
                import anthropic
                self.anthropic_client = anthropic.Anthropic(
                    api_key=os.getenv("ANTHROPIC_API_KEY")
                )
                logger.info("✅ Anthropic (Claude) initialized")
        except Exception as e:
            logger.warning(f"⚠️ Anthropic initialization failed: {e}")
        
        try:
            # Google Gemini
            if os.getenv("GOOGLE_API_KEY"):
                import google.generativeai as genai
                genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))
                self.gemini_client = genai
                logger.info("✅ Google Gemini initialized")
        except Exception as e:
            logger.warning(f"⚠️ Google Gemini initialization failed: {e}")
    
    async def chat(self, message: str, provider: Optional[AIProvider] = None,
                   context: List[Dict] = None, user_id: str = None) -> str:
        """
        💬 محادثة ذكية مع تذكر السياق والتفاصيل
        
        Args:
            message: الرسالة من المستخدم
            provider: مزود AI المطلوب
            context: السياق السابق
            user_id: معرف المستخدم
        
        Returns:
            استجابة من النظام الذكي
        """
        try:
            # استرجاع سياق المستخدم من الذاكرة
            if user_id:
                user_context = await self.rag.get_user_context(user_id)
                logger.info(f"🧠 Retrieved user context for {user_id}")
            
            # البحث عن استعلامات مشابهة
            similar = await self.rag.retrieve_similar_code(message, top_k=2)
            
            # اختيار أفضل AI
            if provider is None:
                provider = await self._select_best_ai(message)
            
            # بناء الـ prompt مع السياق
            enhanced_prompt = self._build_prompt(message, similar, context)
            
            # استدعاء AI المختار
            response = await self._call_ai(enhanced_prompt, provider)
            
            # حفظ الحوار في الذاكرة
            if user_id:
                await self.rag.remember_user_preference(
                    user_id, 
                    "last_conversation",
                    {"message": message, "response": response}
                )
            
            return response
        
        except Exception as e:
            logger.error(f"❌ Chat error: {e}")
            return f"عذراً، حدث خطأ: {str(e)}"
    
    async def generate_code(self, requirements: str, language: str = "python",
                           project_context: str = "") -> Dict[str, Any]:
        """
        💻 توليد كود برمجي احترافي
        
        Args:
            requirements: متطلبات البرنامج
            language: لغة البرمجة
            project_context: سياق المشروع
        
        Returns:
            كود مولد مع شروحات
        """
        try:
            # البحث عن أكواد مشابهة من المشاريع السابقة
            similar_projects = await self.rag.retrieve_similar_code(
                requirements, 
                top_k=3
            )
            
            # بناء prompt محسّن
            prompt = f"""أنت مهندس برمجة محترف جداً.

متطلبات المشروع:
{requirements}

لغة البرمجة: {language}

سياق المشروع:
{project_context}

المشاريع المشابهة السابقة:
{self._format_similar_projects(similar_projects)}

الكود الكامل والنظيف والفعّال:"""
            
            # اختيار أفضل AI للبرمجة (عادة Ollama qwen2.5-coder أو Claude)
            code = await self._call_ai(prompt, AIProvider.OLLAMA)
            
            # حفظ الكود في قاعدة المعرفة
            await self.rag.store_project(
                project_id=f"code_{hash(requirements)}",
                code=code,
                language=language,
                metadata={
                    "requirements": requirements,
                    "type": "generated_code"
                }
            )
            
            return {
                "success": True,
                "code": code,
                "language": language,
                "explanation": await self._generate_explanation(code, language),
                "similar_projects": similar_projects
            }
        
        except Exception as e:
            logger.error(f"❌ Code generation error: {e}")
            return {"success": False, "error": str(e)}
    
    async def debug_code(self, code: str, error: str, 
                        language: str) -> Dict[str, Any]:
        """
        🐛 تصحيح وإصلاح الأخطاء البرمجية
        
        Args:
            code: الكود الذي به خطأ
            error: رسالة الخطأ
            language: لغة البرمجة
        
        Returns:
            الكود المصحح والشرح
        """
        try:
            # البحث عن حلول سابقة لنفس الخطأ
            solution = await self.rag.find_error_solution(error, language)
            
            if solution.get("solution"):
                logger.info(f"✅ Found existing solution for error")
                return {
                    "success": True,
                    "fixed_code": code,  # الكود الأصلي إذا كان الحل موجود
                    "solution": solution.get("solution"),
                    "from_cache": True
                }
            
            # إذا لم يوجد حل، استخدم AI
            prompt = f"""أنت محقق أخطاء برمجية متخصص.

لغة البرمجة: {language}

الكود الأصلي:
```{language}
{code}
```

الخطأ:
{error}

الكود المصحح مع الشرح:"""
            
            fixed_code = await self._call_ai(prompt, AIProvider.OLLAMA)
            
            # حفظ الحل في قاعدة الأخطاء
            await self.rag.store_error_solution(
                error_type=error.split(":")[0],
                error_msg=error,
                solution=fixed_code,
                language=language
            )
            
            return {
                "success": True,
                "fixed_code": fixed_code,
                "explanation": await self._generate_explanation(fixed_code, language),
                "from_cache": False
            }
        
        except Exception as e:
            logger.error(f"❌ Debug error: {e}")
            return {"success": False, "error": str(e)}
    
    async def generate_video_script(self, topic: str, duration: int = 10,
                                   style: str = "educational") -> Dict[str, Any]:
        """
        🎬 توليد سيناريو فيديو احترافي
        
        Args:
            topic: موضوع الفيديو
            duration: مدة الفيديو بالدقائق
            style: أسلوب السيناريو
        
        Returns:
            السيناريو مع تقسيم المشاهد
        """
        try:
            words_per_minute = 130  # معدل الكلام
            target_words = duration * words_per_minute
            
            prompt = f"""أنت كاتب سيناريو فيديو محترف.

الموضوع: {topic}
المدة: {duration} دقائق (حوالي {target_words} كلمة)
الأسلوب: {style}

اكتب سيناريو فيديو احترافي يتضمن:
1. مقدمة جذابة
2. نقاط رئيسية
3. أمثلة عملية
4. خلاصة قوية

format:
[المشهد 1]
الوقت: 0:00-1:00
الكلام:
...

[المشهد 2]
...

السيناريو:"""
            
            script = await self._call_ai(prompt, AIProvider.ANTHROPIC)
            
            return {
                "success": True,
                "script": script,
                "topic": topic,
                "duration": duration,
                "estimated_words": target_words,
                "storyboard": await self._generate_storyboard(script, topic)
            }
        
        except Exception as e:
            logger.error(f"❌ Video script generation error: {e}")
            return {"success": False, "error": str(e)}
    
    async def execute_project(self, project_spec: Dict[str, Any]) -> Dict[str, Any]:
        """
        ⚡ تنفيذ مشروع برمجي كامل
        
        Args:
            project_spec: مواصفات المشروع
        
        Returns:
            نتيجة التنفيذ
        """
        try:
            project_type = project_spec.get("type", "python")
            code = project_spec.get("code", "")
            requirements = project_spec.get("requirements", [])
            
            logger.info(f"🚀 Executing project: {project_type}")
            
            # تثبيت المتطلبات
            for req in requirements:
                logger.info(f"📦 Installing {req}")
                result = await self.function_caller.install_package(req)
                if not result.success:
                    logger.warning(f"⚠️ Failed to install {req}")
            
            # تنفيذ الكود
            result = await self.function_caller.run_code(
                code,
                language=project_type
            )
            
            return {
                "success": result.success,
                "output": result.stdout,
                "error": result.stderr,
                "duration": result.duration,
                "return_code": result.return_code
            }
        
        except Exception as e:
            logger.error(f"❌ Project execution error: {e}")
            return {"success": False, "error": str(e)}
    
    async def write_article(self, topic: str, style: str, 
                           length: int = 500) -> str:
        """
        ✍️ كتابة مقالة احترافية
        
        Args:
            topic: موضوع المقالة
            style: أسلوب الكتابة
            length: عدد الكلمات
        
        Returns:
            المقالة المكتوبة
        """
        try:
            prompt = f"""اكتب مقالة احترافية بأسلوب {style} حول موضوع: {topic}
عدد الكلمات: حوالي {length} كلمة
الصيغة: Markdown

المقالة:"""
            
            article = await self._call_ai(prompt, AIProvider.GOOGLE)
            return article
        
        except Exception as e:
            logger.error(f"❌ Article writing error: {e}")
            return f"خطأ: {str(e)}"
    
    async def analyze_document(self, content: str, 
                              doc_type: str = "text") -> Dict[str, Any]:
        """
        📊 تحليل المستندات والملفات
        
        Args:
            content: محتوى المستند
            doc_type: نوع المستند
        
        Returns:
            تحليل شامل
        """
        try:
            # حفظ المستند في قاعدة المعرفة
            await self.rag.store_document(
                doc_id=f"doc_{hash(content)}",
                content=content,
                doc_type=doc_type,
                source="analysis"
            )
            
            prompt = f"""حلل المستند التالي وأعد تقرير شامل يتضمن:
- الأفكار الرئيسية
- الملخص
- الكلمات المفتاحية
- الاستنتاجات

المستند:
{content[:2000]}

التحليل:"""
            
            analysis = await self._call_ai(prompt, AIProvider.OLLAMA)
            
            return {
                "success": True,
                "analysis": analysis,
                "doc_type": doc_type,
                "doc_id": f"doc_{hash(content)}"
            }
        
        except Exception as e:
            logger.error(f"❌ Document analysis error: {e}")
            return {"success": False, "error": str(e)}
    
    # ============ Helper Methods ============
    
    async def _select_best_ai(self, task: str) -> AIProvider:
        """اختيار أفضل AI حسب نوع المهمة"""
        if "كود" in task or "program" in task.lower():
            return AIProvider.OLLAMA  # Specialized for code
        elif "فيديو" in task or "video" in task.lower():
            return AIProvider.ANTHROPIC  # Claude for creative
        elif "مقالة" in task or "article" in task.lower():
            return AIProvider.GOOGLE  # Gemini for content
        else:
            return AIProvider.OLLAMA  # Default to local
    
    async def _call_ai(self, prompt: str, provider: AIProvider) -> str:
        """استدعاء AI المختار"""
        try:
            if provider == AIProvider.OLLAMA:
                return await self.ollama.generate(prompt)
            elif provider == AIProvider.OPENAI:
                return await self._call_openai(prompt)
            elif provider == AIProvider.ANTHROPIC:
                return await self._call_anthropic(prompt)
            elif provider == AIProvider.GOOGLE:
                return await self._call_google(prompt)
            else:
                return await self.ollama.generate(prompt)
        except Exception as e:
            logger.error(f"❌ AI call error: {e}")
            return f"خطأ في استدعاء AI: {str(e)}"
    
    async def _call_openai(self, prompt: str) -> str:
        """استدعاء OpenAI"""
        try:
            import openai
            response = await openai.ChatCompletion.acreate(
                model="gpt-4",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.7,
                max_tokens=2000
            )
            return response.choices[0].message.content
        except Exception as e:
            logger.warning(f"OpenAI failed, falling back: {e}")
            return await self.ollama.generate(prompt)
    
    async def _call_anthropic(self, prompt: str) -> str:
        """استدعاء Claude"""
        try:
            response = self.anthropic_client.messages.create(
                model="claude-3-sonnet-20240229",
                max_tokens=2000,
                messages=[{"role": "user", "content": prompt}]
            )
            return response.content[0].text
        except Exception as e:
            logger.warning(f"Anthropic failed, falling back: {e}")
            return await self.ollama.generate(prompt)
    
    async def _call_google(self, prompt: str) -> str:
        """استدعاء Google Gemini"""
        try:
            model = self.gemini_client.GenerativeModel('gemini-pro')
            response = model.generate_content(prompt)
            return response.text
        except Exception as e:
            logger.warning(f"Google failed, falling back: {e}")
            return await self.ollama.generate(prompt)
    
    def _build_prompt(self, message: str, similar: List, 
                     context: List = None) -> str:
        """بناء prompt محسّن مع السياق"""
        prompt = message
        
        if context:
            prompt += "\n\nالسياق السابق:"
            for msg in context[-3:]:  # آخر 3 رسائل
                prompt += f"\n- {msg.get('message', '')}"
        
        if similar:
            prompt += "\n\nاستعلامات مشابهة محفوظة:"
            for sim in similar[:2]:
                prompt += f"\n- {sim.get('code_preview', '')[:200]}"
        
        return prompt
    
    def _format_similar_projects(self, projects: List) -> str:
        """تنسيق المشاريع المشابهة"""
        if not projects:
            return "لا توجد مشاريع مشابهة"
        
        formatted = ""
        for proj in projects:
            formatted += f"\n- {proj.get('language', 'unknown')}: {proj.get('code_preview', '')[:100]}"
        
        return formatted
    
    async def _generate_explanation(self, code: str, language: str) -> str:
        """توليد شرح للكود"""
        prompt = f"""اشرح هذا الكود {language} بشكل مختصر:
```
{code[:500]}
```
الشرح:"""
        return await self._call_ai(prompt, AIProvider.OLLAMA)
    
    async def _generate_storyboard(self, script: str, topic: str) -> List[str]:
        """توليد storyboard من السيناريو"""
        prompt = f"""من السيناريو التالي، أنشئ وصف لـ 3 مشاهد رئيسية:
{script[:500]}

المشاهد:"""
        descriptions = await self._call_ai(prompt, AIProvider.OLLAMA)
        return descriptions.split("\n")


# إنشاء instance عام
mymy_ia = MyMYIAMagique()
