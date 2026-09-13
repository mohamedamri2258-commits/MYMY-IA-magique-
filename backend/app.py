from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
from werkzeug.security import generate_password_hash, check_password_hash
from models import db, User, Conversation, Message
from config import config
from ai_engine import AIEngine
import os
from dotenv import load_dotenv

load_dotenv()

# Initialisation
app = Flask(__name__)
config_name = os.getenv('FLASK_ENV', 'development')
app.config.from_object(config[config_name])
app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'jwt-secret-key-change-in-production')

# Extensions
db.init_app(app)
jwt = JWTManager(app)
CORS(app)
ai_engine = AIEngine()

# ==================== ROUTES D'AUTHENTIFICATION ====================

@app.route('/api/auth/register', methods=['POST'])
def register():
    """Enregistrement utilisateur"""
    data = request.get_json()
    
    if not data or not all(k in data for k in ('email', 'username', 'password')):
        return jsonify({'error': 'Données manquantes'}), 400
    
    if User.query.filter_by(email=data['email']).first():
        return jsonify({'error': 'Email déjà utilisé'}), 409
    
    if User.query.filter_by(username=data['username']).first():
        return jsonify({'error': 'Nom d\'utilisateur déjà utilisé'}), 409
    
    user = User(
        email=data['email'],
        username=data['username'],
        password_hash=generate_password_hash(data['password'])
    )
    
    db.session.add(user)
    db.session.commit()
    
    access_token = create_access_token(identity=user.id)
    
    return jsonify({
        'message': 'Utilisateur créé avec succès',
        'user': user.to_dict(),
        'access_token': access_token
    }), 201

@app.route('/api/auth/login', methods=['POST'])
def login():
    """Connexion utilisateur"""
    data = request.get_json()
    
    if not data or not all(k in data for k in ('email', 'password')):
        return jsonify({'error': 'Email et mot de passe requis'}), 400
    
    user = User.query.filter_by(email=data['email']).first()
    
    if not user or not check_password_hash(user.password_hash, data['password']):
        return jsonify({'error': 'Email ou mot de passe incorrect'}), 401
    
    access_token = create_access_token(identity=user.id)
    
    return jsonify({
        'message': 'Connexion réussie',
        'user': user.to_dict(),
        'access_token': access_token
    }), 200

# ==================== ROUTES DE CONVERSATION ====================

@app.route('/api/conversations', methods=['GET'])
@jwt_required()
def get_conversations():
    """Récupère toutes les conversations de l'utilisateur"""
    user_id = get_jwt_identity()
    conversations = Conversation.query.filter_by(user_id=user_id).order_by(Conversation.updated_at.desc()).all()
    
    return jsonify({
        'conversations': [c.to_dict() for c in conversations]
    }), 200

@app.route('/api/conversations', methods=['POST'])
@jwt_required()
def create_conversation():
    """Crée une nouvelle conversation"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    conversation = Conversation(
        user_id=user_id,
        title=data.get('title', 'Nouvelle conversation')
    )
    
    db.session.add(conversation)
    db.session.commit()
    
    return jsonify({
        'message': 'Conversation créée',
        'conversation': conversation.to_dict()
    }), 201

@app.route('/api/conversations/<conversation_id>', methods=['GET'])
@jwt_required()
def get_conversation(conversation_id):
    """Récupère une conversation avec ses messages"""
    user_id = get_jwt_identity()
    conversation = Conversation.query.filter_by(id=conversation_id, user_id=user_id).first()
    
    if not conversation:
        return jsonify({'error': 'Conversation non trouvée'}), 404
    
    return jsonify({
        'conversation': conversation.to_dict(),
        'messages': [m.to_dict() for m in conversation.messages]
    }), 200

@app.route('/api/conversations/<conversation_id>', methods=['DELETE'])
@jwt_required()
def delete_conversation(conversation_id):
    """Supprime une conversation"""
    user_id = get_jwt_identity()
    conversation = Conversation.query.filter_by(id=conversation_id, user_id=user_id).first()
    
    if not conversation:
        return jsonify({'error': 'Conversation non trouvée'}), 404
    
    db.session.delete(conversation)
    db.session.commit()
    
    return jsonify({'message': 'Conversation supprimée'}), 200

# ==================== ROUTES DE CHAT/IA ====================

@app.route('/api/chat', methods=['POST'])
@jwt_required()
def chat():
    """Endpoint principal de chat"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    if not data or 'message' not in data or 'conversation_id' not in data:
        return jsonify({'error': 'Message et conversation_id requis'}), 400
    
    conversation = Conversation.query.filter_by(
        id=data['conversation_id'],
        user_id=user_id
    ).first()
    
    if not conversation:
        return jsonify({'error': 'Conversation non trouvée'}), 404
    
    # Récupérer l'historique
    history = [{'role': m.role, 'content': m.content} for m in conversation.messages]
    
    # Générer la réponse IA
    system_prompt = data.get('system_prompt', None)
    result = ai_engine.chat(data['message'], history, system_prompt)
    
    if not result['success']:
        return jsonify({'error': result['response']}), 500
    
    # Sauvegarder les messages
    user_msg = Message(
        conversation_id=data['conversation_id'],
        role='user',
        content=data['message'],
        tokens_used=0
    )
    
    assistant_msg = Message(
        conversation_id=data['conversation_id'],
        role='assistant',
        content=result['response'],
        tokens_used=result.get('tokens_used', 0)
    )
    
    db.session.add(user_msg)
    db.session.add(assistant_msg)
    db.session.commit()
    
    return jsonify({
        'response': result['response'],
        'tokens_used': result.get('tokens_used', 0),
        'model': result.get('model', 'unknown')
    }), 200

@app.route('/api/query', methods=['POST'])
def query():
    """Endpoint de requête simple (sans authentification)"""
    data = request.get_json()
    
    if not data or 'query' not in data:
        return jsonify({'error': 'Requête manquante'}), 400
    
    result = ai_engine.chat(data['query'])
    
    return jsonify({
        'response': result['response'],
        'tokens_used': result.get('tokens_used', 0),
        'success': result['success']
    }), 200 if result['success'] else 500

# ==================== ROUTES DE SANTÉ ====================

@app.route('/api/health', methods=['GET'])
def health():
    """Endpoint de santé"""
    return jsonify({
        'status': 'healthy',
        'service': 'MYMY-IA Magique',
        'version': '1.0.0'
    }), 200

# ==================== GESTION DES ERREURS ====================

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Ressource non trouvée'}), 404

@app.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    return jsonify({'error': 'Erreur interne du serveur'}), 500

# ==================== INITIALISATION ====================

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    
    app.run(
        host=os.getenv('HOST', '0.0.0.0'),
        port=int(os.getenv('PORT', 5000)),
        debug=os.getenv('DEBUG', False)
    )
