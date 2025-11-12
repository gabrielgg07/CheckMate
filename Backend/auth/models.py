from database.db import db
import uuid
from datetime import datetime


class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.String, primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # Common fields
    name = db.Column(db.String(120))
    email = db.Column(db.String(120), unique=True, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Local auth
    password = db.Column(db.String(200), nullable=True)

    # Google auth fields
    google_id = db.Column(db.String(200), unique=True, nullable=True)
    given_name = db.Column(db.String(100), nullable=True)
    family_name = db.Column(db.String(100), nullable=True)
    profile_image_url = db.Column(db.String(300), nullable=True)
    # ✅ add these two
    access_token = db.Column(db.Text, nullable=True)
    id_token = db.Column(db.Text, nullable=True)


    # Optional: professional or business-related fields
    account_type = db.Column(db.String(50), default="basic")  # e.g., "basic", "pro", "enterprise"
    is_verified = db.Column(db.Boolean, default=False)
    last_login = db.Column(db.DateTime, nullable=True)


