# Base image (can later specify alpine or debian)
FROM python:3.13

# Working Directory 
WORKDIR /app 

# Install UV
COPY --from=ghcr.io/astral-sh/uv:0.11.7 /uv /uvx /bin/
# Copy files to tell UV what dependencies to install
COPY pyproject.toml uv.lock ./

# Install dependencies
RUN uv sync --frozen

# Copy app files over
COPY app ./app
COPY tests ./tests

# Copy over test files

EXPOSE 8000


CMD ["uv", "run", "fastapi", "dev", "--host", "0.0.0.0", "--port", "8000"]
# JSON ARGS CMD ["cmd1", "cmd2", "cmd3", "etc.."]
