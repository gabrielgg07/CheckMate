from database.db import db
from datetime import datetime
import uuid

class Friendship(db.Model):
    __tablename__ = "friendships"

    id = db.Column(db.String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String, db.ForeignKey("users.id"), nullable=False)
    friend_id = db.Column(db.String, db.ForeignKey("users.id"), nullable=False)
    status = db.Column(db.String(20), default="pending")  # pending, accepted, blocked
    can_control = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    __table_args__ = (
        db.UniqueConstraint("user_id", "friend_id", name="_user_friend_uc"),
    )
