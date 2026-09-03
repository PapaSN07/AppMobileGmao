# Script PowerShell pour chercher la table coswin_user dans TOUTES les bases de données
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  RECHERCHE DE LA TABLE COSWIN_USER SUR TOUTES LES BASES" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

$scriptPath = "$PSScriptRoot\backend\scripts\find_coswin_user_table.py"

# Détecter le bon python venv
$pythonPath = "python"
if (Test-Path "$PSScriptRoot\backend\.venv\Scripts\python.exe") {
    $pythonPath = "$PSScriptRoot\backend\.venv\Scripts\python.exe"
} elseif (Test-Path "$PSScriptRoot\.venv\Scripts\python.exe") {
    $pythonPath = "$PSScriptRoot\.venv\Scripts\python.exe"
}

if (Test-Path $scriptPath) {
    Write-Host "Recherche dans toutes les bases de données via $pythonPath..." -ForegroundColor Yellow
    & $pythonPath $scriptPath
    Write-Host ""
    Write-Host "Le rapport de recherche a ete sauvegarde dans :" -ForegroundColor Green
    Write-Host "   $PSScriptRoot\rapport_recherche_coswin_user.txt" -ForegroundColor White
} else {
    Write-Host "Script introuvable a l'emplacement : $scriptPath" -ForegroundColor Red
}
