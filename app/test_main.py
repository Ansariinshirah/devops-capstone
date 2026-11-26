from main import app


def test_health_returns_ok():
    client = app.test_client()
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json()["status"] == "ok"


def test_index_returns_service_name():
    client = app.test_client()
    resp = client.get("/")
    assert resp.status_code == 200
    assert resp.get_json()["service"] == "InfoSetu DevOps Capstone"


def test_metrics_endpoint():
    client = app.test_client()
    client.get("/health")
    resp = client.get("/metrics")
    assert resp.status_code == 200
    assert b"app_requests_total" in resp.data
