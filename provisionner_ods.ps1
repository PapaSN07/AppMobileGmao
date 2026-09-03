# Script PowerShell autonome de provisionnement coswin_user (GMAO ODS)
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  PROVISIONNEMENT DE LA TABLE COSWIN_USER (GMAO ODS)" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

$scriptPath = "$PSScriptRoot\backend\scripts\provision_ods_users.py"

# Détecter le bon python dans les virtualenv du projet
$pythonPath = "python"
if (Test-Path "$PSScriptRoot\backend\.venv\Scripts\python.exe") {
    $pythonPath = "$PSScriptRoot\backend\.venv\Scripts\python.exe"
} elseif (Test-Path "$PSScriptRoot\.venv\Scripts\python.exe") {
    $pythonPath = "$PSScriptRoot\.venv\Scripts\python.exe"
}

if (Test-Path $scriptPath) {
    Write-Host "Lancement du script de provisionnement via $pythonPath..." -ForegroundColor Yellow
    & $pythonPath $scriptPath
    Write-Host ""
    Write-Host "Le rapport d'execution a ete sauvegarde dans :" -ForegroundColor Green
    Write-Host "   $PSScriptRoot\rapport_provisionnement.txt" -ForegroundColor White
} else {
    Write-Host "Script introuvable a l'emplacement : $scriptPath" -ForegroundColor Red
}
