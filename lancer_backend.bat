@echo off
title GMAO Backend
cd /d C:\Users\X1\AppMobileGmao\backend
echo Demarrage du backend sur port 8003...
.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8003
pause
