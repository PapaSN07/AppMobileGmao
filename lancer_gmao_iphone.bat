@echo off
title GMAO Mobile - Lancement
echo.
echo ====================================
echo   GMAO MOBILE - Demarrage
echo ====================================
echo.

echo [1/2] Demarrage du Backend API...
start "GMAO Backend" cmd /k "cd /d C:\Users\X1\AppMobileGmao\backend ^&^& .venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8003 --reload"

timeout /t 3 /nobreak ^> nul

echo [2/2] Demarrage du serveur Web iPhone...
start "GMAO Web iPhone" cmd /k "cd /d C:\Users\X1\AppMobileGmao\frontend_mobile\build\web ^&^& python -m http.server 8080"

timeout /t 2 /nobreak ^> nul

echo.
echo ====================================
echo   APP PRETE !
echo   Ouvrez Safari sur iPhone :
echo   http://192.168.137.1:8080
echo ====================================
echo.
pause
