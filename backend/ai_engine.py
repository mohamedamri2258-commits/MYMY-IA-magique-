import os
import json
from typing import List, Dict
import requests
from dotenv import load_dotenv

load_dotenv()

class AIEngine:
    """Moteur IA MYMY-IA Magique"""
    
    def __init__(self):
        self.api_key = os.getenv('OPENAI_API_KEY', '')
        self.model = os.getenv('AI_MODEL', 'gpt-3.5-turbo')
        self.base_url = os.getenv('OPENAI_API_BASE', 'https://api.openai.com/v1')
        self.max_tokens = int(os.getenv('MAX_TOKENS', 2000))
        self.temperature = float(os.getenv('TEMPERATURE', 0.7))
        self.top_k = int(os.getenv('TOP_K', 5))
        
    def generate_response(self, messages: List[Dict], system_prompt: str = None) -> Dict:
        """
        Génère une réponse IA basée sur les messages
        
        Args:
            messages: Liste des messages [{'role': 'user', 'content': '...'}]
            system_prompt: Instructions système optionnelles
            
        Returns:
            Dict avec 'response', 'tokens_used', 'model'
        """
        try:
            # Préparer les messages
            full_messages = []
            
            if system_prompt:
                full_messages.append({
                    'role': 'system',
                    'content': system_prompt
                })
            
            full_messages.extend(messages)
            
            # Appel à OpenAI API (ou autre provider)
            headers = {
                'Authorization': f'Bearer {self.api_key}',
                'Content-Type': 'application/json'
            }
            
            payload = {
                'model': self.model,
                'messages': full_messages,
                'max_tokens': self.max_tokens,
                'temperature': self.temperature,
                'top_p': 0.95,
                'frequency_penalty': 0.0,
                'presence_penalty': 0.0
            }
            
            response = requests.post(
                f'{self.base_url}/chat/completions',
                headers=headers,
                json=payload,
                timeout=30
            )
            
            if response.status_code == 200:
                data = response.json()
                return {
                    'response': data['choices'][0]['message']['content'],
                    'tokens_used': data['usage']['total_tokens'],
                    'model': self.model,
                    'success': True
                }
            else:
                return {
                    'response': f'Erreur API: {response.status_code}',
                    'tokens_used': 0,
                    'success': False
                }
                
        except Exception as e:
            return {
                'response': f'Erreur: {str(e)}',
                'tokens_used': 0,
                'success': False
            }
    
    def chat(self, user_message: str, conversation_history: List[Dict] = None, system_prompt: str = None) -> Dict:
        """
        Interface de chat simple
        
        Args:
            user_message: Message de l'utilisateur
            conversation_history: Historique de conversation
            system_prompt: Instructions système
            
        Returns:
            Réponse de l'IA
        """
        if conversation_history is None:
            conversation_history = []
            
        # Ajouter le message utilisateur
        conversation_history.append({
            'role': 'user',
            'content': user_message
        })
        
        # Générer la réponse
        result = self.generate_response(conversation_history, system_prompt)
        
        if result['success']:
            conversation_history.append({
                'role': 'assistant',
                'content': result['response']
            })
        
        return result
    
    def get_context_from_documents(self, query: str, documents: List[str], top_k: int = None) -> List[str]:
        """
        Récupère les documents les plus pertinents
        
        Args:
            query: Requête utilisateur
            documents: Liste de documents
            top_k: Nombre de résultats à retourner
            
        Returns:
            Liste des documents pertinents
        """
        if top_k is None:
            top_k = self.top_k
            
        # Implémentation simple - à remplacer par une recherche sémantique réelle
        return documents[:top_k]
