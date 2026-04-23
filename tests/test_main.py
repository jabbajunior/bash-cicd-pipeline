from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health():
    # Call the health check endpoint.
    response = client.get("/health")

    # The endpoint should return a successful status.
    assert response.status_code == 200

    # The response body should confirm the app is healthy.
    assert response.json() == {"status": "ok"}


