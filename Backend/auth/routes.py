from flask import Blueprint, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from database.db import db
from auth.models import User
from core.security import create_jwt, validate_jwt
from datetime import datetime
from google.oauth2 import id_token
from google.auth.transport import requests as grequests
import jwt



auth_bp = Blueprint("auth", __name__)

# ---------------------------
# 🔹 Register (email or Google)
# ---------------------------
@auth_bp.route("/register", methods=["POST"])
def register():
    data = request.get_json()
    email = data.get("email")
    if not email:
        return jsonify({"error": "Email is required"}), 400

    # prevent duplicate user
    existing_user = User.query.filter_by(email=email).first()
    if existing_user:
        return jsonify({"error": "Email already registered"}), 400

    # detect Google registration
    google_id = data.get("google_id")
    if google_id:
        user = User(

            email=email,
            google_id=google_id,
            name=data.get("name"),
            given_name=data.get("givenName"),
            family_name=data.get("familyName"),
            profile_image_url=data.get("profileImageURL"),
            access_token=data.get("accessToken"),
            id_token=data.get("idToken"),
            is_verified=True,
            account_type="professional",
        )
    else:
        password = data.get("password")
        if not password:
            return jsonify({"error": "Password required for normal registration"}), 400
        user = User(
            email=email,
            name=data.get("name"),
            password=generate_password_hash(password),
            account_type="basic",
        )

    db.session.add(user)
    db.session.commit()
    return jsonify({"message": "User registered successfully"}), 201


# ---------------------------
# 🔹 Login (email or Google)
# ---------------------------
@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    email = data.get("email")
    user = User.query.filter_by(email=email).first()

    # Google login
    if data.get("google_id"):
        if not user:
            return jsonify({"error": "No account found for this Google user"}), 404
        # Optionally update tokens/profile
        user.access_token = data.get("accessToken")
        user.id_token = data.get("idToken")
        user.last_login = datetime.utcnow()
        db.session.commit()
        token = create_jwt(user.id)
        return jsonify({"token": token, "message": "Google login successful"}), 200

    # Email/password login
    if not user or not check_password_hash(user.password, data.get("password", "")):
        return jsonify({"error": "Invalid credentials"}), 401

    user.last_login = datetime.utcnow()
    db.session.commit()

    token = create_jwt(user.id)
    return jsonify({"token": token, "message": "Login successful"}), 200


@auth_bp.route("/google", methods=["POST"])
def google_auth():


    data = request.get_json()
    id_token_str = data.get("idToken")

    if not id_token_str:
        return jsonify({"error": "Missing ID token"}), 400

    try:
        # Verify token with Google
        CLIENT_ID = "172460374843-dllgb5kk8c2cb559b9tqjon03qo4u2c1.apps.googleusercontent.com"
        info = id_token.verify_oauth2_token(id_token_str, grequests.Request(), CLIENT_ID)

        email = info["email"]
        google_id = info["sub"]
        name = info.get("name")
        given_name = info.get("given_name")
        family_name = info.get("family_name")
        picture = info.get("picture")

    except Exception as e:
        return jsonify({"error": f"Invalid Google token: {e}"}), 401

    # Lookup or create user
    user = User.query.filter_by(email=email).first()
    if not user:
        user = User(
            email=email,
            google_id=google_id,
            name=name,
            given_name=given_name,
            family_name=family_name,
            profile_image_url=picture,
            access_token=data.get("accessToken"),
            id_token=id_token_str,
            is_verified=True,
            account_type="professional",
        )
        db.session.add(user)
        db.session.commit()
    else:
        user.access_token = data.get("accessToken")
        user.id_token = id_token_str
        user.last_login = datetime.utcnow()
        db.session.commit()

    token = create_jwt(user.id)
    return jsonify({
        "message": "Google login successful",
        "token": token,
        "user": {
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "profile_image_url": user.profile_image_url,
        }
    }), 200


@auth_bp.route("/protected")
def protected():
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        return jsonify({"error": "Missing or invalid token"}), 401

    token = auth_header.split("Bearer ")[1]
    decoded = validate_jwt(token)
    if not decoded:
        return jsonify({"error": "Invalid or expired token"}), 401

    return jsonify({"message": f"Welcome user {decoded['user_id']}!"})
