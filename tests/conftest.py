# tests/conftest.py

import os

import httpx
import pytest
from fastapi.testclient import TestClient


TIMEOUT_SECONDS = 3.0


def pytest_addoption(parser):
    parser.addoption(
        "--api-target",
        choices=["inprocess", "live"],
        default="inprocess",
        help="Choose whether tests run against TestClient or a live server.",
    )

    parser.addoption(
        "--base-url",
        default=os.getenv("BASE_URL", "http://localhost:8000"),
        help="Base URL for live API tests.",
    )


@pytest.fixture
def api_client(request):
    target = request.config.getoption("--api-target")

    if target == "inprocess":
        from app.main import app

        with TestClient(app) as client:
            yield client

        return

    base_url = request.config.getoption("--base-url").rstrip("/")

    with httpx.Client(
        base_url=base_url,
        timeout=TIMEOUT_SECONDS,
        follow_redirects=True,
    ) as client:
        yield client