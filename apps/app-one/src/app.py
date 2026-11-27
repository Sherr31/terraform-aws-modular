
from flask import Flask, jsonify
import os

app = Flask(__name__)

APP_NAME = "App One"
APP_VERSION = "1.0.0"
API_VERSION = "v1"


@app.route("/")
def home():
    return jsonify({
        "application": APP_NAME,
        "message": "Terraform AWS Modular Demo",
        "status": "running"
    })


@app.route("/health")
def health():
    return jsonify({
        "status": "healthy"
    }), 200


@app.route("/info")
def info():
    return jsonify({
        "application": APP_NAME,
        "environment": os.getenv("APP_ENV", "development"),
        "version": APP_VERSION
    })


@app.route("/version")
def version():
    return jsonify({
        "application": APP_NAME,
        "version": APP_VERSION,
        "api_version": API_VERSION
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
