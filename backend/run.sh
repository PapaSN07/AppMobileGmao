#!/usr/bin/env bash
# Start backend uvicorn on port 8003 (will try to source ../.venv if present)
set -e
if [ -f ../.venv/bin/activate ]; then
  # shellcheck source=/dev/null
  source ../.venv/bin/activate
fi

python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8003
