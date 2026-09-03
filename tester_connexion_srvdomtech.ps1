# Script PowerShell autonome de test de connexion srv-bddomtech
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  TEST DE CONNEXION RESEAU SERVEUR DISTANT SENELEC" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

$scriptPath = "$PSScriptRoot\backend\scripts\test_connexion_srvdomtech.py"

# Détecter le bon python dans les virtualenv du projet
$pythonPath = "python"
if (Test-Path "$PSScriptRoot\backend\.venv\Scripts\python.exe") {
    $pythonPath = "$PSScriptRoot\backend\.venv\Scripts\python.exe"
} elseif (Test-Path "$PSScriptRoot\.venv\Scripts\python.exe") {
    $pythonPath = "$PSScriptRoot\.venv\Scripts\python.exe"
}

if (Test-Path $scriptPath) {
    Write-Host "Lancement du test de connexion via $pythonPath..." -ForegroundColor Yellow
    & $pythonPath $scriptPath
    Write-Host ""
    Write-Host "Le rapport de test a ete sauvegarde dans :" -ForegroundColor Green
    Write-Host "   $PSScriptRoot\rapport_test_connexion.txt" -ForegroundColor White
} else {
    Write-Host "Script introuvable a l'emplacement : $scriptPath" -ForegroundColor Red
}
