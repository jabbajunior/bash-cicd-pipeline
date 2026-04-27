"""
Live deployment API tests.

These tests use requests to call the running FastAPI container over HTTP.
They require the app container to be running and reachable at BASE_URL.
"""

import os
import time

import pytest
import requests

BASE_URL = os.getenv("BASE_URL", "http://localhost:8000").rstrip("/")
TIMEOUT_SECONDS = 3

def reset_app_state():
    # Helper method to reset app state between tests
    response = requests.post(f"{BASE_URL}/reset", timeout=TIMEOUT_SECONDS)
    assert response.status_code == 200
    assert response.json() == {"status": "reset"}


def test_health():
    # Call the real health check endpoint over HTTP.
    response = requests.get(f"{BASE_URL}/health", timeout=TIMEOUT_SECONDS)

    # The endpoint should return a successful status.
    assert response.status_code == 200

    # The response body should confirm the app is healthy.
    assert response.json() == {"status": "ok"}


def test_create_item():
    """Verify that the create item endpoint stores and returns a new item."""

    # Reset in-memory app state before the test.
    reset_app_state()

    # Send a POST request with a valid JSON body.
    response = requests.post(
        f"{BASE_URL}/items/",
        json={"name": "test_item"},
        timeout=TIMEOUT_SECONDS,
    )

    # Confirm the endpoint returns HTTP 201 Created.
    assert response.status_code == 201

    # Confirm the response body contains the created item data.
    assert response.json() == {"id": 1, "name": "test_item"}


def test_create_item_invalid_body():
    """Verify that the create item endpoint rejects an invalid request body."""

    # Reset in-memory app state before the test.
    reset_app_state()

    # Send a POST request with a missing required field.
    response = requests.post(
        f"{BASE_URL}/items/",
        json={},
        timeout=TIMEOUT_SECONDS,
    )

    # Confirm FastAPI returns a validation error.
    assert response.status_code == 422


def test_read_item():
    """Verify that the get item endpoint returns a stored item by ID."""

    reset_app_state()

    # Create a test item first so there is something to retrieve.
    create_response = requests.post(
        f"{BASE_URL}/items/",
        json={"name": "test_item"},
        timeout=TIMEOUT_SECONDS,
    )

    assert create_response.status_code == 201

    # Request the item by its ID.
    response = requests.get(
        f"{BASE_URL}/items/1",
        timeout=TIMEOUT_SECONDS,
    )

    # Confirm the endpoint returns HTTP 200 OK.
    assert response.status_code == 200

    # Confirm the response body matches the stored item.
    assert response.json() == {"id": 1, "name": "test_item"}


def test_read_item_not_found():
    """Verify that the get item endpoint returns 404 for a missing item."""

    reset_app_state()

    # Request an item ID that does not exist.
    response = requests.get(
        f"{BASE_URL}/items/999",
        timeout=TIMEOUT_SECONDS,
    )

    # Confirm the endpoint returns HTTP 404 Not Found.
    assert response.status_code == 404

    # Confirm the response body matches the expected error payload.
    assert response.json() == {"status": "not found"}    


def test_read_items():
    """Verify that the get all items endpoint returns all stored items."""

    reset_app_state()

    # Create a couple of test items.
    first_response = requests.post(
        f"{BASE_URL}/items/",
        json={"name": "test_item_1"},
        timeout=TIMEOUT_SECONDS,
    )

    second_response = requests.post(
        f"{BASE_URL}/items/",
        json={"name": "test_item_2"},
        timeout=TIMEOUT_SECONDS,
    )

    assert first_response.status_code == 201
    assert second_response.status_code == 201

    # Request all stored items.
    response = requests.get(
        f"{BASE_URL}/items",
        timeout=TIMEOUT_SECONDS,
    )

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

    reset_app_state()

    # Request all stored items when none have been created.
    response = requests.get(
        f"{BASE_URL}/items",
        timeout=TIMEOUT_SECONDS,
    )

    # Confirm the endpoint returns HTTP 200 OK.
    assert response.status_code == 200

    # Confirm the response body contains no items.
    assert response.json() == {"items": {}}