# ---- compatibility shim for legacy 'hyper' on Py3.10+ ----
import collections as _collections
import collections.abc as _abc
for _name in ("Iterable", "Mapping", "MutableMapping", "MutableSet"):
    if not hasattr(_collections, _name):
        setattr(_collections, _name, getattr(_abc, _name))
# ----------------------------------------------------------

from flask import Blueprint, jsonify
from apns2.client import APNsClient
from apns2.credentials import TokenCredentials
from apns2.payload import Payload

from auth.models import User
from database.db import db

notifications_bp = Blueprint("notifications", __name__)

APNS_KEY_PATH = "apns/AuthKey_475XB44R37.p8"
APNS_KEY_ID = "475XB44R37"
APNS_TEAM_ID = "Z4LS6UY7MC"
APNS_BUNDLE_ID = "com.screencontrol"

credentials = TokenCredentials(
    auth_key_path=APNS_KEY_PATH,
    auth_key_id=APNS_KEY_ID,
    team_id=APNS_TEAM_ID,
)

client = APNsClient(credentials=credentials, use_sandbox=True)

@notifications_bp.route("/notify/<user_id>", methods=["POST"])
def send_push(user_id):
    user = db.session.get(User, user_id)
    if not user or not user.device_token:
        return jsonify({"error": "User not found or missing token"}), 404

    payload = Payload(alert="Hello 👋 from ScreenControl!", sound="default", badge=1)
    try:
        client.send_notification(user.device_token, payload, topic=APNS_BUNDLE_ID)
        return jsonify({"success": True, "sent_to": user.email}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
