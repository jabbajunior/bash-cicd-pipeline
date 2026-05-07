# tests/test_combined.py

"""
API contract tests.

These tests can run in two modes:

1. In-process mode:
   Uses FastAPI TestClient directly against the application code.

2. Live mode:
   Uses HTTPX to call a running FastAPI server over HTTP.

Run in-process tests:
    uv run pytest tests/test_combined.py --api-target=inprocess --verbose

Run live deployment tests:
    uv run pytest tests/test_combined.py --api-target=live --base-url=http://localhost:8000 --verbose
"""


def reset_app_state(api_client):
    """Reset app state between tests."""
    response = api_client.post("/reset")

    assert response.status_code == 200
    assert response.json() == {"status": "reset"}


def test_health(api_client):
    """Verify that the health endpoint reports the app is running."""

    response = api_client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_create_item(api_client):
    """Verify that the create item endpoint stores and returns a new item."""

    reset_app_state(api_client)

    response = api_client.post(
        "/items/",
        json={"name": "test_item"},
    )

    assert response.status_code == 201
    assert response.json() == {"id": 1, "name": "test_item"}


def test_create_item_invalid_body(api_client):
    """Verify that the create item endpoint rejects an invalid request body."""

    reset_app_state(api_client)

    response = api_client.post(
        "/items/",
        json={},
    )

    assert response.status_code == 422


def test_read_item(api_client):
    """Verify that the get item endpoint returns a stored item by ID."""

    reset_app_state(api_client)

    create_response = api_client.post(
        "/items/",
        json={"name": "test_item"},
    )

    assert create_response.status_code == 201

    response = api_client.get("/items/1")

    assert response.status_code == 200
    assert response.json() == {"id": 1, "name": "test_item"}


def test_read_item_not_found(api_client):
    """Verify that the get item endpoint returns 404 for a missing item."""

    reset_app_state(api_client)

    response = api_client.get("/items/999")

    assert response.status_code == 404
    assert response.json() == {"status": "not found"}


def test_read_items(api_client):
    """Verify that the get all items endpoint returns all stored items."""

    reset_app_state(api_client)

    first_response = api_client.post(
        "/items/",
        json={"name": "test_item_1"},
    )

    second_response = api_client.post(
        "/items/",
        json={"name": "test_item_2"},
    )

    assert first_response.status_code == 201
    assert second_response.status_code == 201

    response = api_client.get("/items")

    assert response.status_code == 200
    assert response.json() == {
        "items": {
            "1": {"id": 1, "name": "test_item_1"},
            "2": {"id": 2, "name": "test_item_2"},
        }
    }


def test_read_items_empty(api_client):
    """Verify that the get all items endpoint returns an empty collection when no items exist."""

    reset_app_state(api_client)

    response = api_client.get("/items")

    assert response.status_code == 200
    assert response.json() == {"items": {}}