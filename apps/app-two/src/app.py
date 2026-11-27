import os
import logging
from flask import Flask, jsonify
import psycopg2

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

DB_HOST = os.getenv("DB_HOST", "")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "appdb")
DB_USER = os.getenv("DB_USER", "dbadmin")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")


@app.route("/")
def home():
    return jsonify({
        "application": "App Two",
        "message": "Terraform AWS Modular Demo - PostgreSQL Connected",
        "status": "running"
    })


@app.route("/health")
def health():
    return jsonify({"status": "healthy"}), 200


@app.route("/db-health")
def db_health():
    if not all([DB_HOST, DB_PASSWORD]):
        return jsonify({
            "status": "degraded",
            "message": "Database credentials not configured"
        }), 503

    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            connect_timeout=5
        )
        cursor = conn.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        cursor.close()
        conn.close()
        return jsonify({
            "status": "healthy",
            "database": "PostgreSQL",
            "version": version
        }), 200
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        return jsonify({
            "status": "unhealthy",
            "message": str(e)
        }), 503


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
