"""
⚡ Function Calling System - التحكم التلقائي والتنفيذ
Execute Commands and Functions Automatically with AI Control
"""

import os
import subprocess
import asyncio
import logging
import shlex
import json
from typing import Dict, Any, Optional, List, Callable
from dataclasses import dataclass
from enum import Enum

logger = logging.getLogger(__name__)

class CommandType(Enum):
    """أنواع الأوامر المسموحة"""
    PYTHON = "python"
    NODE = "node"
    BASH = "bash"
    FLUTTER = "flutter"
    NPM = "npm"
    PIP = "pip"


@dataclass
class CommandResult:
    """نتيجة تنفيذ أمر"""
    success: bool
    stdout: str
    stderr: str
    return_code: int
    duration: float


class FunctionCaller:
    """نظام استدعاء الدوال والأوامر الآلي"""
    
    def __init__(self):
        self.max_timeout = int(os.getenv("MAX_COMMAND_TIMEOUT", "300"))
        self.allowed_commands = os.getenv(
            "ALLOWED_COMMANDS", 
            "python,node,bash,flutter,npm,pip"
        ).split(",")
        
        # قائمة الدوال المسموحة
        self.function_registry: Dict[str, Callable] = {}
        self._register_default_functions()
        
        logger.info("⚡ Function Calling System initialized")
    
    def _register_default_functions(self):
        """تسجيل الدوال الافتراضية"""
        self.register_function("run_code", self.run_code)
        self.register_function("execute_command", self.execute_command)
        self.register_function("create_file", self.create_file)
        self.register_function("read_file", self.read_file)
        self.register_function("list_directory", self.list_directory)
        self.register_function("install_package", self.install_package)
        self.register_function("build_project", self.build_project)
    
    def register_function(self, name: str, func: Callable):
        """تسجيل دالة جديدة"""
        self.function_registry[name] = func
        logger.info(f"📋 Function registered: {name}")
    
    def is_command_allowed(self, command: str) -> bool:
        """التحقق من أن الأمر مسموح"""
        for allowed in self.allowed_commands:
            if command.strip().startswith(allowed.strip()):
                return True
        return False
    
    async def run_code(self, code: str, language: str = "python",
                      timeout: int = None) -> CommandResult:
        """تنفيذ كود برمجي"""
        try:
            timeout = timeout or self.max_timeout
            
            if language == "python":
                return await self._run_python(code, timeout)
            elif language == "javascript":
                return await self._run_javascript(code, timeout)
            elif language == "bash":
                return await self._run_bash(code, timeout)
            else:
                return CommandResult(
                    success=False,
                    stdout="",
                    stderr=f"❌ Unsupported language: {language}",
                    return_code=1,
                    duration=0
                )
        except Exception as e:
            logger.error(f"❌ Error running code: {e}")
            return CommandResult(
                success=False,
                stdout="",
                stderr=str(e),
                return_code=1,
                duration=0
            )
    
    async def _run_python(self, code: str, timeout: int) -> CommandResult:
        """تنفيذ كود Python"""
        try:
            import time
            start_time = time.time()
            
            process = await asyncio.create_subprocess_exec(
                "python3", "-c", code,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            
            stdout, stderr = await asyncio.wait_for(
                process.communicate(),
                timeout=timeout
            )
            
            duration = time.time() - start_time
            
            return CommandResult(
                success=process.returncode == 0,
                stdout=stdout.decode() if stdout else "",
                stderr=stderr.decode() if stderr else "",
                return_code=process.returncode,
                duration=duration
            )
        except asyncio.TimeoutError:
            return CommandResult(
                success=False,
                stdout="",
                stderr=f"⏱️ Timeout after {timeout}s",
                return_code=-1,
                duration=timeout
            )
        except Exception as e:
            return CommandResult(
                success=False,
                stdout="",
                stderr=str(e),
                return_code=-1,
                duration=0
            )
    
    async def _run_javascript(self, code: str, timeout: int) -> CommandResult:
        """تنفيذ كود JavaScript/Node.js"""
        try:
            import time
            start_time = time.time()
            
            process = await asyncio.create_subprocess_exec(
                "node", "-e", code,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            
            stdout, stderr = await asyncio.wait_for(
                process.communicate(),
                timeout=timeout
            )
            
            duration = time.time() - start_time
            
            return CommandResult(
                success=process.returncode == 0,
                stdout=stdout.decode() if stdout else "",
                stderr=stderr.decode() if stderr else "",
                return_code=process.returncode,
                duration=duration
            )
        except asyncio.TimeoutError:
            return CommandResult(
                success=False,
                stdout="",
                stderr=f"⏱️ Timeout after {timeout}s",
                return_code=-1,
                duration=timeout
            )
        except Exception as e:
            return CommandResult(
                success=False,
                stdout="",
                stderr=str(e),
                return_code=-1,
                duration=0
            )
    
    async def _run_bash(self, command: str, timeout: int) -> CommandResult:
        """تنفيذ أمر Bash"""
        # التحقق من أن الأمر مسموح
        if not self.is_command_allowed(command):
            return CommandResult(
                success=False,
                stdout="",
                stderr=f"❌ Command not allowed: {command}",
                return_code=1,
                duration=0
            )
        
        try:
            import time
            start_time = time.time()
            
            process = await asyncio.create_subprocess_shell(
                command,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            
            stdout, stderr = await asyncio.wait_for(
                process.communicate(),
                timeout=timeout
            )
            
            duration = time.time() - start_time
            
            return CommandResult(
                success=process.returncode == 0,
                stdout=stdout.decode() if stdout else "",
                stderr=stderr.decode() if stderr else "",
                return_code=process.returncode,
                duration=duration
            )
        except asyncio.TimeoutError:
            return CommandResult(
                success=False,
                stdout="",
                stderr=f"⏱️ Timeout after {timeout}s",
                return_code=-1,
                duration=timeout
            )
        except Exception as e:
            return CommandResult(
                success=False,
                stdout="",
                stderr=str(e),
                return_code=-1,
                duration=0
            )
    
    async def execute_command(self, command: str, 
                             timeout: int = None) -> CommandResult:
        """تنفيذ أمر عام في نظام التشغيل"""
        return await self._run_bash(command, timeout or self.max_timeout)
    
    async def create_file(self, file_path: str, content: str) -> Dict[str, Any]:
        """إنشاء ملف"""
        try:
            # التحقق الأمني
            if "../" in file_path or file_path.startswith("/"):
                return {"success": False, "error": "❌ Invalid file path"}
            
            os.makedirs(os.path.dirname(file_path) or ".", exist_ok=True)
            
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(content)
            
            logger.info(f"📝 File created: {file_path}")
            return {"success": True, "file_path": file_path}
        except Exception as e:
            logger.error(f"❌ Error creating file: {e}")
            return {"success": False, "error": str(e)}
    
    async def read_file(self, file_path: str) -> Dict[str, Any]:
        """قراءة ملف"""
        try:
            if not os.path.exists(file_path):
                return {"success": False, "error": "❌ File not found"}
            
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
            
            return {"success": True, "content": content}
        except Exception as e:
            logger.error(f"❌ Error reading file: {e}")
            return {"success": False, "error": str(e)}
    
    async def list_directory(self, path: str = ".") -> Dict[str, Any]:
        """عرض محتويات المجلد"""
        try:
            items = os.listdir(path)
            files = []
            directories = []
            
            for item in items:
                full_path = os.path.join(path, item)
                if os.path.isdir(full_path):
                    directories.append(item)
                else:
                    files.append(item)
            
            return {
                "success": True,
                "path": path,
                "files": files,
                "directories": directories,
                "total": len(files) + len(directories)
            }
        except Exception as e:
            logger.error(f"❌ Error listing directory: {e}")
            return {"success": False, "error": str(e)}
    
    async def install_package(self, package_name: str, 
                             package_manager: str = "pip") -> CommandResult:
        """تثبيت حزمة برمجية"""
        if package_manager == "pip":
            command = f"pip install {package_name}"
        elif package_manager == "npm":
            command = f"npm install {package_name}"
        else:
            return CommandResult(
                success=False,
                stdout="",
                stderr=f"❌ Unknown package manager: {package_manager}",
                return_code=1,
                duration=0
            )
        
        return await self._run_bash(command, self.max_timeout * 2)
    
    async def build_project(self, project_type: str, 
                           project_path: str = ".") -> CommandResult:
        """بناء مشروع برمجي"""
        if project_type == "flutter":
            command = f"cd {project_path} && flutter build apk --release"
        elif project_type == "npm":
            command = f"cd {project_path} && npm run build"
        elif project_type == "python":
            command = f"cd {project_path} && python setup.py build"
        else:
            return CommandResult(
                success=False,
                stdout="",
                stderr=f"❌ Unknown project type: {project_type}",
                return_code=1,
                duration=0
            )
        
        return await self._run_bash(command, self.max_timeout)
    
    def parse_ai_response_for_functions(self, response: str) -> List[Dict[str, Any]]:
        """استخراج استدعاءات الدوال من استجابة AI"""
        functions_to_call = []
        
        try:
            # البحث عن نمط الدوال في الاستجابة
            import re
            
            # نمط: FUNCTION(name) { params }
            pattern = r'FUNCTION\s*\(\s*(\w+)\s*\)\s*\{([^}]*)\}'
            matches = re.finditer(pattern, response, re.DOTALL)
            
            for match in matches:
                func_name = match.group(1)
                params_str = match.group(2)
                
                # محاولة تحليل المعاملات
                try:
                    params = json.loads("{" + params_str + "}")
                except:
                    # إذا فشل التحليل، حاول كـ dict مفروض
                    params = {}
                
                functions_to_call.append({
                    "name": func_name,
                    "params": params
                })
        
        except Exception as e:
            logger.error(f"❌ Error parsing functions: {e}")
        
        return functions_to_call
    
    async def execute_function_calls(self, functions: List[Dict[str, Any]]) -> List[Dict]:
        """تنفيذ قائمة من استدعاءات الدوال"""
        results = []
        
        for func_call in functions:
            func_name = func_call.get("name")
            params = func_call.get("params", {})
            
            if func_name not in self.function_registry:
                results.append({
                    "function": func_name,
                    "success": False,
                    "error": f"❌ Function not found: {func_name}"
                })
                continue
            
            try:
                func = self.function_registry[func_name]
                result = await func(**params) if asyncio.iscoroutinefunction(func) else func(**params)
                
                results.append({
                    "function": func_name,
                    "success": True,
                    "result": result
                })
                
                logger.info(f"✅ Function executed: {func_name}")
            except Exception as e:
                logger.error(f"❌ Error executing {func_name}: {e}")
                results.append({
                    "function": func_name,
                    "success": False,
                    "error": str(e)
                })
        
        return results


# إنشاء instance عام
function_caller = FunctionCaller()
