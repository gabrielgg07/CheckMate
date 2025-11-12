import jwt
from datetime import datetime, timedelta
from flask import current_app

def create_jwt(user_id):
    payload = {
        "user_id": user_id,
        "exp": datetime.utcnow() + timedelta(hours=24)
    }
    return jwt.encode(payload, current_app.config["JWT_SECRET"], algorithm="HS256")

def validate_jwt(token):
    try:
        decoded = jwt.decode(token, current_app.config["JWT_SECRET"], algorithms=["HS256"])
        return decoded  # e.g. { "user_id": "...", "exp": ... }
    except jwt.ExpiredSignatureError:
        return None  # token expired
    except jwt.InvalidTokenError:
        return None  # invalid token