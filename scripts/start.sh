#!/usr/bin/env bash
# Boot the full VoxRecap stack: redis + api + worker + ui via docker compose.
# Submodules are initialised on first run; rebuilds happen automatically.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required but not on PATH" >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "docker compose v2 is required" >&2
  exit 1
fi

echo "==> ensuring submodules are initialised"
git submodule update --init --recursive

# Force the legacy Docker builder. Buildx + Docker Desktop's containerd
# image store can hang indefinitely on the "resolving provenance for
# metadata file" export step. The legacy builder doesn't generate
# attestations and is plenty fast for a local stack.
export DOCKER_BUILDKIT=0
export COMPOSE_DOCKER_CLI_BUILD=0
export BUILDX_NO_DEFAULT_ATTESTATIONS=1

echo "==> building containers (legacy builder)"
docker compose build --pull

echo "==> starting stack"
docker compose up -d

echo
echo "VoxRecap is up:"
echo "  UI:  http://localhost:5173"
echo "  API: http://localhost:8000  (health: /health)"
echo
echo "Tail logs with: docker compose logs -f"
echo "Stop with:      docker compose down"
