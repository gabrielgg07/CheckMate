from flask import Flask
from flask_cors import CORS
from database.db import db
from auth.routes import auth_bp
from relationship.routes import relationships_bp
from health.routes import health_bp
from config import Config




def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    CORS(app)
    
    db.init_app(app)
    app.register_blueprint(auth_bp, url_prefix="/auth")
    app.register_blueprint(relationships_bp, url_prefix="/relationships")
    app.register_blueprint(health_bp, url_prefix="/health")
    
    @app.route("/")
    def index():
        return {"message": "Backend running ✅"}
    
    return app

if __name__ == "__main__":
    app = create_app()
    app.run(host="0.0.0.0", port=5001, debug=True)
