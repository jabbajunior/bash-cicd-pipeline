from fastapi.testclient import TestClient
from app.main import app
from app import main

client = TestClient(app)

def test_health():
    # Call the health check endpoint.
    response = client.get("/health")

    # The endpoint should return a successful status.
    assert response.status_code == 200

    # The response body should confirm the app is healthy.
    assert response.json() == {"status": "ok"}


def test_create_item():
    """Verify that the create item endpoint stores and returns a new item."""

    # Reset in-memory app state before the test.
    main.items.clear()
    main.index = 1

    # Send a POST request with a valid JSON body.
    response = client.post("/items/", json={"name": "test_item"})

    # Confirm the endpoint returns HTTP 201 Created.
    assert response.status_code == 201

    # Confirm the response body contains the created item data.
    assert response.json() == {"id": 1, "name": "test_item"}

def test_create_item_invalid_body():
    """Verify that the create item endpoint rejects an invalid request body."""

    # Reset in-memory app state before the test.
    main.items.clear()
    main.index = 1

    # Send a POST request with a missing required field.
    response = client.post("/items/", json={})

    # Confirm FastAPI returns a validation error.
    assert response.status_code == 422