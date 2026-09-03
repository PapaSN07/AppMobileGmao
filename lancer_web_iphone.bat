@echo off
title GMAO Web iPhone
cd /d C:\Users\X1\AppMobileGmao\frontend_mobile\build\web
echo Serveur Web actif sur http://192.168.137.1:8080
echo Ouvrez Safari sur votre iPhone et tapez cette adresse !
echo.
python -m http.server 8080
pause
