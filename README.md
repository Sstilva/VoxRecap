# VoxRecap

Orchestrator repo. Pulls in three sibling repos as submodules and brings up
the full stack with one command.

```
ui/      → voxrecap-app-web    (React + Vite)
api/     → voxrecap-app-api    (FastAPI + Celery dispatcher + WS bridge)
worker/  → voxrecap-app-worker (Celery worker + Redis pub/sub notifier)
redis    → message broker, result backend, and event bus
```

## Quick start

```bash
git clone --recurse-submodules <this repo>
./scripts/start.sh
```

That builds and starts four containers:

| Service | Port | Notes |
| --- | --- | --- |
| ui     | 5173 | Vite dev server, proxies `/api` and `/api/ws` to the API |
| api    | 8000 | `POST /api/tasks`, `WS /api/ws/tasks/{id}`, `GET /health` |
| worker | —    | Celery worker, runs `tasks.process_demo` |
| redis  | 6379 | broker (db 1) + backend (db 2) + pub/sub (db 0) |

Open http://localhost:5173 and click **Run task**. The UI POSTs to the API,
which enqueues a Celery job and opens a WebSocket back. The worker emits
`TaskEvent`s to a Redis pub/sub channel; the API forwards them across the
WebSocket and the UI renders them live.

Stop with `docker compose down`.

## Branching

`main` is protected — work happens on `dev`. Each submodule follows the
same convention: feature branches PR into `dev`, `dev` merges into `main`
on release.

## Architecture notes

Each service depends on small `Protocol` / interface boundaries
(`TaskDispatcher`, `TaskEventBus`, `ProgressNotifier`, `TaskApi`,
`TaskEventStream`) so transports and backends can be swapped without
touching business code. See each submodule's README for layout.
