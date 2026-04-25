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

# Disable buildx provenance/SBOM attestations: on Docker Desktop with the
# containerd image store these can hang the export step indefinitely
# ("resolving provenance for metadata file"). They aren't needed locally.
# BuildKit (default) is kept on so we get live progress and proper layer
# caching across rebuilds.
export BUILDX_NO_DEFAULT_ATTESTATIONS=1
# Stable project name regardless of where the script is invoked from
# (worktree vs. main checkout) — keeps image cache reusable.
export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-voxrecap}"

echo "==> building containers (BuildKit, no attestations)"
docker compose build --pull --progress=plain

echo "==> starting stack"
docker compose up -d

echo
echo "VoxRecap is up:"
echo "  UI:  http://localhost:5173"
echo "  API: http://localhost:8000  (health: /health)"
echo
echo "Tail logs with: docker compose logs -f"
echo "Stop with:      docker compose down"
