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

This project is intended for Linux or a Linux-like environment with Bash 4+, Docker, and `curl`. Other Unix-like systems may work, but they are not the primary target.

Then set up the project:

1. Clone the repository to your machine.
2. Change into the project directory.
3. Install the project dependencies with `uv sync`.

If you want to run the GitHub Actions workflows on a self-hosted runner, that runner also needs Docker, Bash, `curl`, and access to the repository checkout.


### Usage

`CD` depends on the candidate image artifacts created by `CI`, so always run `CI` first when you are working locally or triggering workflows manually.

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

#### Self-Hosted Runner

##### Prerequisites
These workflows use `runs-on: self-hosted`, so the runner machine needs Docker, Bash, `curl`, and a checkout of this repository.

To add the runner, either:

- Use the GitHub UI: open the repository, go to `Settings` > `Actions` > `Runners`, and click `New self-hosted runner`.
- Use GitHub CLI: run `gh repo view --web` to open the repository in your browser, then follow the same `Settings` > `Actions` > `Runners` flow.

##### Running with GitHub CLI

You can trigger either workflow from the terminal with `gh` once the repository is connected to GitHub CLI:

```bash
gh workflow run CI --ref <branch>
gh workflow run CD --ref <branch>
```

##### Running via Pull Requests

- `CI` runs automatically when you open a pull request, update it with new commits, reopen it, or mark it ready for review.
- `CD` runs automatically when a pull request is closed. If you want it to deploy, merge the pull request rather than closing it without merging.
- If you want to trigger `CI` again, push another commit to the pull request branch.
- If you want to trigger `CD`, close the pull request after the CI artifacts exist, or merge the pull request if that is your release flow.

## Known Issues
- Run the scripts from the repository root. They source `./scripts/...` and use relative `./logs` and `./state` paths, so absolute-path invocation is not supported.
- The project is Linux-first. It uses `#!/usr/bin/bash` and Bash-specific features such as `mapfile`, so other Unix-like systems are not the primary target.
- The CD flow assumes the app responds on `localhost:8000` and exposes a `/health` endpoint during validation.
- `CD` depends on the candidate artifacts created by `CI` in the same state directory. Mixing runs across different `PIPELINE_STATE_PATH` values is not supported.
- The `CD` workflow assumes the self-hosted runner already has a checkout of this repository.
- The `CD` workflow currently triggers on any closed pull request. If you only want deploys on merged pull requests, that behavior needs an additional guard.

## Further Reading

Deeper we go, more technical
