
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route("/")
def home():
    return jsonify({
        "application": "App One",
        "message": "Terraform AWS Modular Demo",
        "status": "running"
    })


@app.route("/health")
def health():
    return jsonify({"status": "healthy"}), 200


@app.route("/info")
def info():
    return jsonify({
        "application": "app-one",
        "environment": os.getenv("APP_ENV", "development"),
        "version": "1.0.0"
    })


@app.route("/version")
def version():
    return jsonify({
        "application": "app-one",
        "version": "1.0.0",
        "api_version": "v1"
    })
