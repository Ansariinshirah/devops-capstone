import os

import redis
from flask import Flask, jsonify
from prometheus_client import CONTENT_TYPE_LATEST, Counter, generate_latest

app = Flask(__name__)

REQUESTS = Counter("app_requests_total", "Total HTTP requests", ["endpoint"])

cache = redis.Redis(
    host=os.getenv("REDIS_HOST", "localhost"),
    port=int(os.getenv("REDIS_PORT", "6379")),
    socket_connect_timeout=2,
    decode_responses=True,
)


def get_visits():
    try:
        return cache.incr("visits")
    except redis.exceptions.RedisError:
        return None


@app.route("/")
def index():
    REQUESTS.labels(endpoint="/").inc()
    return jsonify(
        service="InfoSetu DevOps Capstone",
        environment=os.getenv("APP_ENV", "development"),
        visits=get_visits(),
    )


@app.route("/health")
def health():
    REQUESTS.labels(endpoint="/health").inc()
    try:
        cache.ping()
        redis_ok = True
    except redis.exceptions.RedisError:
        redis_ok = False
    return jsonify(status="ok", redis=redis_ok)


@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}
