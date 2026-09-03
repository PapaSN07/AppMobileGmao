# Script PowerShell pour découvrir les colonnes exactes de la table REQUESTER
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  DECOUVERTE COLONNES REQUESTER (GMAO_ODS)" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

$scriptPath = "$PSScriptRoot\backend\scripts\discover_requester_columns.py"

# Détecter le bon python venv
$pythonPath = "python"
if (Test-Path "$PSScriptRoot\backend\.venv\Scripts\python.exe") {
    $pythonPath = "$PSScriptRoot\backend\.venv\Scripts\python.exe"
} elseif (Test-Path "$PSScriptRoot\.venv\Scripts\python.exe") {
    $pythonPath = "$PSScriptRoot\.venv\Scripts\python.exe"
}

if (Test-Path $scriptPath) {
    Write-Host "Découverte des colonnes via $pythonPath..." -ForegroundColor Yellow
    & $pythonPath $scriptPath
    Write-Host ""
    Write-Host "Le rapport a ete sauvegarde dans :" -ForegroundColor Green
    Write-Host "   $PSScriptRoot\rapport_colonnes_requester.txt" -ForegroundColor White
} else {
    Write-Host "Script introuvable a l'emplacement : $scriptPath" -ForegroundColor Red
}
