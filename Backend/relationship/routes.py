from flask import Blueprint, request, jsonify
from database.db import db
from relationship.models import Friendship
from auth.models import User

relationships_bp = Blueprint("relationships", __name__)

@relationships_bp.route("/add", methods=["POST"])
def add_friend():
    data = request.get_json()
    user_id = data.get("user_id")
    friend_email = data.get("friend_email")

    friend = User.query.filter_by(email=friend_email).first()
    if not friend:
        return jsonify({"error": "User not found"}), 404

    if user_id == friend.id:
        return jsonify({"error": "Cannot add yourself"}), 400

    existing = Friendship.query.filter_by(user_id=user_id, friend_id=friend.id).first()
    if existing:
        return jsonify({"error": "Friendship already exists"}), 400

    friendship = Friendship(user_id=user_id, friend_id=friend.id)
    db.session.add(friendship)
    db.session.commit()

    return jsonify({"message": "Friend request sent"}), 201


@relationships_bp.route("/accept", methods=["POST"])
def accept_friend():
    data = request.get_json()
    friendship_id = data.get("friendship_id")

    friendship = Friendship.query.get(friendship_id)
    if not friendship:
        return jsonify({"error": "Request not found"}), 404

    friendship.status = "accepted"
    db.session.commit()

    return jsonify({"message": "Friend request accepted"}), 200


@relationships_bp.route("/grant_control", methods=["POST"])
def grant_control():
    data = request.get_json()
    friendship_id = data.get("friendship_id")
    allow = data.get("allow", True)

    friendship = Friendship.query.get(friendship_id)
    if not friendship or friendship.status != "accepted":
        return jsonify({"error": "Invalid or unaccepted friendship"}), 400

    friendship.can_control = allow
    db.session.commit()

    return jsonify({"message": f"Control {'granted' if allow else 'revoked'}"}), 200
