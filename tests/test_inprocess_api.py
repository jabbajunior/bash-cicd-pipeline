"""
In-process API tests.

These tests use FastAPI's TestClient to test the app directly in Python.
They do not require the Docker container or FastAPI server to be running.
"""

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


def test_read_item():
    """Verify that the get item endpoint returns a stored item by ID."""

    # Reset in-memory app state before the test.
    main.items.clear()
    main.index = 1

    # Create a test item first so there is something to retrieve.
    client.post("/items/", json={"name": "test_item"})

    # Request the item by its ID.
    response = client.get("/items/1")

    # Confirm the endpoint returns HTTP 200 OK.
    assert response.status_code == 200

    # Confirm the response body matches the stored item.
    assert response.json() == {"id": 1, "name": "test_item"}


def test_read_item_not_found():
    """Verify that the get item endpoint returns 404 for a missing item."""

    # Reset in-memory app state before the test.
    main.items.clear()
    main.index = 1

    # Request an item ID that does not exist.
    response = client.get("/items/999")

    # Confirm the endpoint returns HTTP 404 Not Found.
    assert response.status_code == 404

    # Confirm the response body matches the expected error payload.
    assert response.json() == {"status": "not found"}

def test_read_items():
    """Verify that the get all items endpoint returns all stored items."""

    # Reset in-memory app state before the test.
    main.items.clear()
    main.index = 1

    # Create a couple of test items.
    client.post("/items/", json={"name": "test_item_1"})
    client.post("/items/", json={"name": "test_item_2"})

    # Request all stored items.
    response = client.get("/items")

    # Confirm the endpoint returns HTTP 200 OK.
    assert response.status_code == 200

    # Confirm the response body contains all stored items.
    assert response.json() == {
        "items": {
            "1": {"id": 1, "name": "test_item_1"},
            "2": {"id": 2, "name": "test_item_2"},
        }
    }

def test_read_items_empty():
    """Verify that the get all items endpoint returns an empty collection when no items exist."""

    # Reset in-memory app state before the test.
    main.items.clear()
    main.index = 1

    # Request all stored items when none have been created.
    response = client.get("/items")

    # Confirm the endpoint returns HTTP 200 OK.
    assert response.status_code == 200

    # Confirm the response body contains no items.
    assert response.json() == {"items": {}}