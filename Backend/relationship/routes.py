from flask import Blueprint, request, jsonify
from database.db import db
from relationship.models import Friendship
from auth.models import User
from auth.models import User

relationships_bp = Blueprint("relationships", __name__)
@relationships_bp.route("/add", methods=["POST"])
def add_friend():
    data = request.get_json()
    from_user_id = data.get("from_user_id")
    to_user_id = data.get("to_user_id")

    if not from_user_id or not to_user_id:
        return jsonify({"error": "Missing IDs"}), 400

    # Cannot friend yourself
    if from_user_id == to_user_id:
        return jsonify({"error": "Cannot add yourself"}), 400

    # Validate both users exist
    from_user = User.query.get(from_user_id)
    to_user = User.query.get(to_user_id)

    if not from_user or not to_user:
        return jsonify({"error": "User not found"}), 404

    # Already requested?
    existing = Friendship.query.filter_by(
        user_id=from_user_id,
        friend_id=to_user_id
    ).first()

    if existing:
        return jsonify({"error": "Friendship already exists"}), 400

    # Create friend request
    friendship = Friendship(
        user_id=from_user_id,
        friend_id=to_user_id,
        status="pending"
    )
    db.session.add(friendship)
    db.session.commit()

    return jsonify({
        "message": "Friend request sent",
        "friendship_id": friendship.id
    }), 201

@relationships_bp.route("/accept", methods=["POST"])
def accept_friend():
    data = request.get_json()
    friendship_id = data.get("friendship_id")

    friendship = Friendship.query.get(friendship_id)
    if not friendship:
        return jsonify({"error": "Request not found"}), 404

    if friendship.status != "pending":
        return jsonify({"error": "Not pending"}), 400

    friendship.status = "accepted"

    # Create reverse (mutual) friendship
    reverse = Friendship.query.filter_by(
        user_id=friendship.friend_id,
        friend_id=friendship.user_id
    ).first()

    if not reverse:
        reverse = Friendship(
            user_id=friendship.friend_id,
            friend_id=friendship.user_id,
            status="accepted"
        )
        db.session.add(reverse)

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


# 🔍 Search for users (privacy-safe)
@relationships_bp.route("/search", methods=["GET"])
def search_users():
    query = request.args.get("q", "").strip().lower()
    if not query:
        return jsonify([])

    results = (
        User.query
        .filter(
            (User.name.ilike(f"%{query}%"))
        )
        .limit(20)
        .all()
    )

    # ✅ Return only public-safe fields
    return jsonify([
        {
            "id": u.id,
            "name": u.name,
            "profile_image_url": u.profile_image_url
        } for u in results
    ])


@relationships_bp.route("/pending/<user_id>", methods=["GET"])
def get_pending_requests(user_id):
    # Find all requests *sent TO* this user that are still pending
    pending = Friendship.query.filter_by(
        friend_id=user_id,
        status="pending"
    ).all()

    # Return user info for each sender
    result = []
    for f in pending:
        from_user = User.query.get(f.user_id)
        if from_user:
            result.append({
                "friendship_id": f.id,
                "from_user_id": from_user.id,
                "name": from_user.name,
                "profile_image_url": from_user.profile_image_url
            })

    return jsonify(result), 200


@relationships_bp.route("/friends/<user_id>", methods=["GET"])
def get_friends(user_id):
    # friendships where the user is the requester
    outgoing = Friendship.query.filter_by(
        user_id=user_id,
        status="accepted"
    ).all()

    # friendships where the user is the receiver
    incoming = Friendship.query.filter_by(
        friend_id=user_id,
        status="accepted"
    ).all()

    friend_ids = set()

    # Collect IDs from outgoing
    for f in outgoing:
        friend_ids.add(f.friend_id)

    # Collect IDs from incoming
    for f in incoming:
        friend_ids.add(f.user_id)

    # Load actual users
    friends = User.query.filter(User.id.in_(friend_ids)).all()

    result = [
        {
            "id": u.id,
            "name": u.name,
            "email": u.email,
            "profile_image_url": u.profile_image_url
        }
        for u in friends
    ]

    return jsonify(result), 200
