
import os
import logging
from datetime import datetime, timezone

import psycopg2
from flask import Flask, jsonify

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

APP_NAME = "App Two"
APP_VERSION = "1.1.0"
APP_ENV = os.getenv("APP_ENV", "development")

DB_HOST = os.getenv("DB_HOST", "")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "appdb")
DB_USER = os.getenv("DB_USER", "dbadmin")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")

STARTED_AT = datetime.now(timezone.utc).isoformat()


@app.route("/")
def home():
    return jsonify({
        "application": APP_NAME,
        "message": "Terraform AWS Modular Demo - PostgreSQL Integration",
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


@app.route("/ready")
def ready():
    return jsonify({
        "status": "ready",
        "application": APP_NAME
    }), 200


@app.route("/info")
def info():
    return jsonify({
        "application": APP_NAME,
        "version": APP_VERSION,
        "environment": APP_ENV,
        "database_configured": bool(DB_HOST and DB_PASSWORD),
        "started_at": STARTED_AT
    }), 200


@app.route("/db-health")
def db_health():
    if not all([DB_HOST, DB_PASSWORD]):
        return jsonify({
            "status": "degraded",
            "message": "Database credentials not configured"
        }), 503

    try:
        with psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            connect_timeout=5
        ) as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT version();")
                database_version = cursor.fetchone()[0]

        return jsonify({
            "status": "healthy",
            "database": "PostgreSQL",
            "version": database_version
        }), 200

    except Exception:
        logger.exception("Database health check failed")
        return jsonify({
            "status": "unhealthy",
            "message": "Unable to connect to PostgreSQL"
        }), 503


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
