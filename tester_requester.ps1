# Script PowerShell de test de la table dbo.REQUESTER via CoswinUserService
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  TEST LECTURE UTILISATEURS (dbo.REQUESTER - Gmao_ODS)" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

$scriptPath = "$PSScriptRoot\backend\scripts\tester_requester_ods.py"

# Détecter le bon python venv
$pythonPath = "python"
if (Test-Path "$PSScriptRoot\backend\.venv\Scripts\python.exe") {
    $pythonPath = "$PSScriptRoot\backend\.venv\Scripts\python.exe"
} elseif (Test-Path "$PSScriptRoot\.venv\Scripts\python.exe") {
    $pythonPath = "$PSScriptRoot\.venv\Scripts\python.exe"
}

if (Test-Path $scriptPath) {
    Write-Host "Interrogation du service CoswinUserService via $pythonPath..." -ForegroundColor Yellow
    & $pythonPath $scriptPath
    Write-Host ""
    Write-Host "Le rapport d'execution a ete sauvegarde dans :" -ForegroundColor Green
    Write-Host "   $PSScriptRoot\rapport_utilisateurs_requester.txt" -ForegroundColor White
} else {
    Write-Host "Script introuvable a l'emplacement : $scriptPath" -ForegroundColor Red
}
