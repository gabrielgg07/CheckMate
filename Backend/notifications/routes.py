from flask import Blueprint, jsonify, request
import subprocess
from auth.models import User
from database.db import db

notifications_bp = Blueprint("notifications", __name__)

@notifications_bp.route("/notify/<user_id>/<notif_type>", methods=["POST"])
def send_push(user_id, notif_type):
    user = db.session.get(User, user_id)
    if not user or not user.device_token:
        return jsonify({"error": "User not found or missing token"}), 404

    device_token = user.device_token

    # You can override title/body via JSON body
    data = request.get_json(silent=True) or {}
    title = data.get("title", "ScreenControl Alert")
    body = data.get("body", "You have a new ScreenControl notification")

    try:
        result = subprocess.run(
            [
                "./apns_wrapper/apns_sender",   # path to your Go binary
                device_token,
                notif_type,
                title,
                body
            ],
            capture_output=True,
            text=True,
            timeout=5
        )

        print("GO OUTPUT:", result.stdout)
        print("GO ERR:", result.stderr)

        if result.returncode != 0:
            return jsonify({"error": "Go APNS error", "detail": result.stderr}), 500

        return jsonify({"success": True}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
