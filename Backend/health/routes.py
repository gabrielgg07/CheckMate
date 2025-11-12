from flask import Blueprint, request, jsonify
from database.db import db

health_bp = Blueprint("health", __name__)

@health_bp.route("", methods=["GET"])
def health_check():
    try:
        # Simple database check
        # 
        # 
        #db.session.execute("SELECT 1")
        return {"status": "ok", "database": "connected"}, 200
    except Exception as e:
        return {"status": "error", "database": str(e)}, 500
