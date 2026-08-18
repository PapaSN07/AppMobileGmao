# Script PowerShell pour tester la connexion au serveur Coswin Senelec
# et configurer automatiquement l'IP qui fonctionne.

$ip1 = "10.101.1.100"
$ip2 = "10.101.1.102"
$port = 8083
$envFile = "backend/.env.prod"

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  TEST DE CONNEXION COSWIN SENELEC" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "Branchez le cable Senelec avant de continuer..." -ForegroundColor Yellow
Write-Host ""

# Fonction pour tester un port TCP
function Test-Port {
    param($ip, $port)
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $connect = $client.BeginConnect($ip, $port, $null, $null)
        # Timeout de 3 secondes
        $wait = $connect.AsyncWaitHandle.WaitOne(3000, $false)
        if (-not $wait) {
            $client.Close()
            return $false
        }
        $client.EndConnect($connect)
        $client.Close()
        return $true
    }
    catch {
        return $false
    }
}

Write-Host "Test de connexion vers $ip1 : $port..." -NoNewline
$res1 = Test-Port $ip1 $port
if ($res1) {
    Write-Host " ✅ REUSSI" -ForegroundColor Green
} else {
    Write-Host " ❌ ECHEC" -ForegroundColor Red
}

Write-Host "Test de connexion vers $ip2 : $port..." -NoNewline
$res2 = Test-Port $ip2 $port
if ($res2) {
    Write-Host " ✅ REUSSI" -ForegroundColor Green
} else {
    Write-Host " ❌ ECHEC" -ForegroundColor Red
}

$workingIp = $null
if ($res1) { $workingIp = $ip1 }
elseif ($res2) { $workingIp = $ip2 }

if ($workingIp -ne $null) {
    Write-Host ""
    Write-Host "IP active detectee : $workingIp" -ForegroundColor Green
    
    if (Test-Path $envFile) {
        Write-Host "Mise a jour du fichier $envFile..." -NoNewline
        $content = Get-Content $envFile
        $newContent = @()
        $updated = $false
        foreach ($line in $content) {
            if ($line -like "OT_API_BASE_URL=*") {
                $newContent += "OT_API_BASE_URL=http://${workingIp}:8083/ws/rest"
                $updated = $true
            } else {
                $newContent += $line
            }
        }
        $newContent | Set-Content $envFile
        Write-Host " ✅ FAIT" -ForegroundColor Green
        Write-Host "L'adresse de l'API a ete configuree sur http://${workingIp}:8083/ws/rest" -ForegroundColor Cyan
        Write-Host "Veuillez redemarrer votre serveur FastAPI (uvicorn) pour appliquer le changement." -ForegroundColor Yellow
    } else {
        Write-Host " ⚠️ Fichier $envFile introuvable !" -ForegroundColor Red
    }
} else {
    Write-Host ""
    Write-Host "❌ Aucune des deux adresses IP ($ip1 ou $ip2) n'est joignable sur le port $port." -ForegroundColor Red
    Write-Host "Verifiez que le cable Senelec est bien branche et que votre carte reseau est active." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Appuyez sur une touche pour quitter..."
[void]$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
