from fastapi import FastAPI, Response
from pydantic import BaseModel

app = FastAPI()

items = {}
index = 1


class Item(BaseModel):
    """Request body for creating a new item."""
    name: str


# Returns an http 200 and a short message indicating the program is healthy
@app.get(
    "/health",
    status_code=200,
    summary="Health check",
    description="Simple endpoint used to confirm that the API is running.")
def read_health():
    """Return a basic health status for CI checks."""
    return {"status": "ok"}


@app.post(
    "/items/",
    status_code=201,
    summary="Create item",
    description="Craete a new item and store it in the in-memory items dictionary")
def create_item(item: Item):
    """Create a new item and return the created record with its generated ID."""
    global index

    item_id = index
    items[item_id] = {"id": item_id, "name": item.name}
    index += 1;
    
    return items[item_id]


@app.get(
    "/items/{item_id}",
    status_code=200,
    summary="Get item by ID",
    description="Fetch a single item from the in-memory store using its integer ID.")
def read_item(item_id: int, response: Response):
    """Return an item by ID, or raise a 404 error if the item does not exist."""
    if item_id not in items:
        response.status_code = 404
        return {"status": "not found"}
    return items[item_id]


@app.get(
    "/items",
    status_code=200,
    summary="Get all items"
    description="Fetch all items from the in-memory store.")
def read_items():
    """Return all items from the in-memory store."""
    return {"items": items}