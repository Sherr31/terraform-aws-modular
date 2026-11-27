
import os
from datetime import datetime, timezone

from flask import Flask, jsonify

app = Flask(__name__)

APP_NAME = "App One"
APP_VERSION = "1.1.0"
API_VERSION = "v1"
APP_ENV = os.getenv("APP_ENV", "development")
STARTED_AT = datetime.now(timezone.utc).isoformat()


@app.route("/")
def home():
    return jsonify({
        "application": APP_NAME,
        "message": "Terraform AWS Modular Demo",
        "status": "running",
        "version": APP_VERSION,
        "environment": APP_ENV
    }), 200


@app.route("/health")
def health():
    return jsonify({
        "status": "healthy",
        "application": APP_NAME
    }), 200


@app.route("/info")
def info():
    return jsonify({
        "application": APP_NAME,
        "version": APP_VERSION,
        "api_version": API_VERSION,
        "environment": APP_ENV,
        "started_at": STARTED_AT
    }), 200


@app.route("/version")
def version():
    return jsonify({
        "application": APP_NAME,
        "version": APP_VERSION,
        "api_version": API_VERSION
    }), 200


@app.route("/ready")
def ready():
    return jsonify({
        "status": "ready",
        "application": APP_NAME
    }), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
