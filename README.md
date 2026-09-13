# MYMY-IA Magique 🌟

Un système d'intelligence artificielle web complet et moderne, conçu pour être aussi puissant que ChatGPT, Copilot, ou Claude.

## 🎯 Caractéristiques

- **Backend Robuste**: API REST Flask avec authentification JWT
- **Base de Données**: SQLAlchemy avec support PostgreSQL
- **Interface Web Moderne**: UI responsive et intuitive
- **Gestion des Conversations**: Historique complet et persistant
- **Intégration IA**: Support OpenAI et autres modèles
- **Sécurité**: Authentification, autorisation, validation des données
- **Scalabilité**: Architecture prête pour la production

## 🚀 Démarrage Rapide

### Avec Docker

```bash
# Cloner le repo
git clone <url>
cd MYMY-IA-magique-

# Configurer les variables d'environnement
cp backend/.env.example backend/.env
# Éditer backend/.env avec votre clé OpenAI

# Démarrer les services
docker-compose up -d

# Accéder à l'application
http://localhost
```

### Sans Docker

```bash
# Backend
cd backend
pip install -r requirements.txt
cp .env.example .env
# Éditer .env
python app.py

# Frontend (dans un autre terminal)
cd web
python -m http.server 8000
# Accéder à http://localhost:8000
```

## 📁 Structure du Projet

```
MYMY-IA-magique-/
├── backend/                 # API Flask
│   ├── app.py              # Application principale
│   ├── models.py           # Modèles de base de données
│   ├── ai_engine.py        # Moteur IA
│   ├── config.py           # Configuration
│   ├── requirements.txt     # Dépendances Python
│   └── .env.example        # Variables d'environnement
├── web/                    # Frontend
│   ├── index.html          # Interface HTML
│   ├── styles.css          # Styles CSS
│   └── app.js              # Logique JavaScript
├── docker-compose.yml      # Configuration Docker
├── nginx.conf              # Configuration Nginx
└── README.md               # Ce fichier
```

## 🔑 API Endpoints

### Authentification
- `POST /api/auth/register` - Créer un compte
- `POST /api/auth/login` - Se connecter

### Conversations
- `GET /api/conversations` - Lister toutes les conversations
- `POST /api/conversations` - Créer une nouvelle conversation
- `GET /api/conversations/<id>` - Récupérer une conversation
- `DELETE /api/conversations/<id>` - Supprimer une conversation

### Chat
- `POST /api/chat` - Envoyer un message (authentifié)
- `POST /api/query` - Requête simple (public)

### Santé
- `GET /api/health` - État du serveur

## 🔐 Variables d'Environnement

```env
# Flask
FLASK_ENV=development
DEBUG=True
SECRET_KEY=your-secret-key
JWT_SECRET_KEY=your-jwt-secret

# Base de données
DATABASE_URL=postgresql://user:pass@localhost:5432/mymy_ia

# OpenAI
OPENAI_API_KEY=your-api-key
AI_MODEL=gpt-3.5-turbo
MAX_TOKENS=2000
TEMPERATURE=0.7
```

## 📱 Fonctionnalités à Venir

- [ ] Support des fichiers et images
- [ ] Plugins et extensions
- [ ] Modèles d'IA personnalisés
- [ ] Export des conversations
- [ ] Collaboration en temps réel
- [ ] Mode hors ligne
- [ ] Application mobile native

## 🛠️ Développement

```bash
# Installation des dépendances
cd backend
pip install -r requirements.txt

# Lancer les tests
pytest

# Format du code
black .

# Linting
flake8 .
```

## 📝 Licence

MIT License - voir LICENSE.md

## 👨‍💼 Auteur

MYMY-IA Team - 2024

## 📞 Support

Pour toute question ou problème, créez une issue sur GitHub.
