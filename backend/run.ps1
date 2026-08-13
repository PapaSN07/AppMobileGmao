# Activate virtualenv (relative to project root) then start uvicorn on port 8003
if (Test-Path ".\.venv\Scripts\Activate.ps1") {
    & .\.venv\Scripts\Activate.ps1
}

python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8003
