# Bash CI/CD Pipeline Learning Project


## Overview

This project demonstrates a simple CI/CD pipeline written in Bash for a small FastAPI application, and it can be run locally or through **self-hosted** Github Action runners.<br/>
It checks code quality, runs tests, builds a Docker image, starts a candidate container, verifies the app inside that container, and promotes the deployment if everything passes.<br/>
It also keeps logs and pipeline state so you can follow what happened across runs.

## What It Does

- Runs linting and automated tests
- Builds a Docker image for each candidate release
- Starts a candidate container for validation
- Tests the app inside the container before deployment
- Promotes the candidate to the stable deployment if checks pass
- Records logs and state files for later review

## Visual Diagram Here

(Demo also here)

## Getting Started

### Installation

To run this project locally, make sure you have the following installed:

- Python 3.13
- [`uv`](https://docs.astral.sh/uv/getting-started/installation/) as the package manager
- Docker
- Bash
- `curl`

Then set up the project:

1. Clone the repository to your machine.
2. Change into the project directory.
3. Install the project dependencies with `uv sync`.

If you want to run the GitHub Actions workflows on a self-hosted runner, that runner also needs Docker, Bash, `curl`, and access to the repository checkout.


### Usage

#### Local Quick Start

Use the commands below from the project root.

##### Prerequisites

If the scripts are not already executable, set that once:
```bash
chmod +x scripts/*.sh
```

##### Run CI

Run the CI pipeline first. It lints the code, runs the tests, and builds the candidate Docker image.
```bash
./scripts/ci.sh
```

##### Run CD

Run the CD pipeline after CI succeeds. It starts the candidate container, checks that the app is healthy, and promotes the deployment if everything passes.
```bash
./scripts/cd.sh
```

The CD script depends on the candidate image artifacts created by `ci.sh`, so it will fail if you run it before CI.

#### Self-Hosted Runner

## Known Issues

## Further Reading

Deeper we go, more technical
