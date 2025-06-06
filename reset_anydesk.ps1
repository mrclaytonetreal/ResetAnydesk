# Script para resetar configurações do AnyDesk
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$Host.UI.RawUI.WindowTitle = "Resetar AnyDesk"

# Função para verificar privilégios administrativos
function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Por favor, execute este script como administrador."
        Read-Host "Pressione Enter para sair"
        exit
    }
}

# Função para parar o AnyDesk
function Stop-AnyDesk {
    $maxAttempts = 5
    $attempt = 0
    while ($attempt -lt $maxAttempts) {
        try {
            $service = Get-Service -Name "AnyDesk" -ErrorAction SilentlyContinue
            if ($service -and $service.Status -eq "Running") {
                Stop-Service -Name "AnyDesk" -Force
                Start-Sleep -Seconds 1
            }
            $process = Get-Process -Name "AnyDesk" -ErrorAction SilentlyContinue
            if ($process) {
                Stop-Process -Name "AnyDesk" -Force
            }
            return
        }
        catch {
            $attempt++
            Start-Sleep -Seconds 1
        }
    }
    Write-Host "Aviso: Não foi possível parar o serviço AnyDesk após $maxAttempts tentativas."
}

# Função para iniciar o AnyDesk
function Start-AnyDesk {
    $maxAttempts = 5
    $attempt = 0
    while ($attempt -lt $maxAttempts) {
        try {
            $service = Get-Service -Name "AnyDesk" -ErrorAction SilentlyContinue
            if ($service -and $service.Status -ne "Running") {
                Start-Service -Name "AnyDesk"
                Start-Sleep -Seconds 1
            }
            $exePaths = @(
                "${env:SystemDrive}\Program Files (x86)\AnyDesk\AnyDesk.exe",
                "${env:SystemDrive}\Program Files\AnyDesk\AnyDesk.exe"
            )
            foreach ($path in $exePaths) {
                if (Test-Path $path) {
                    Start-Process -FilePath $path
                    return
                }
            }
            Write-Host "Aviso: Executável do AnyDesk não encontrado."
            return
        }
        catch {
            $attempt++
            Start-Sleep -Seconds 1
        }
    }
    Write-Host "Aviso: Não foi possível iniciar o AnyDesk após $maxAttempts tentativas."
}

# Verifica privilégios administrativos
Test-Admin

# Define caminhos
$allUsersPath = "$env:ProgramData\AnyDesk"
$appDataPath = "$env:APPDATA\AnyDesk"
$tempPath = "$env:TEMP"

# Para o AnyDesk
Stop-AnyDesk

# Salva user.conf e thumbnails
if (Test-Path "$appDataPath\user.conf") {
    Copy-Item -Path "$appDataPath\user.conf" -Destination "$tempPath\user.conf" -Force
}
if (Test-Path "$appDataPath\thumbnails") {
    Remove-Item -Path "$tempPath\thumbnails" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$appDataPath\thumbnails" -Destination "$tempPath\thumbnails" -Recurse -Force
}

# Remove arquivos de configuração
Remove-Item -Path "$allUsersPath\*" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$appDataPath\*" -Force -ErrorAction SilentlyContinue

# Limpa chaves do Registro
$regPaths = @(
    "HKCU:\Software\AnyDesk",
    "HKLM:\Software\AnyDesk"
)
foreach ($path in $regPaths) {
    if (Test-Path $path) {
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Inicia o AnyDesk
Start-AnyDesk

# Aguarda a recriação do system.conf
$maxWaitSeconds = 30
$elapsed = 0
while ($elapsed -lt $maxWaitSeconds) {
    if (Test-Path "$allUsersPath\system.conf") {
        $content = Get-Content -Path "$allUsersPath\system.conf" -ErrorAction SilentlyContinue
        if ($content -match "ad.anynet.id=") {
            break
        }
    }
    Start-Sleep -Seconds 1
    $elapsed++
}
if ($elapsed -ge $maxWaitSeconds) {
    Write-Host "Timeout: system.conf não foi criado ou não contém 'ad.anynet.id='."
    Read-Host "Pressione Enter para sair"
    exit
}

# Restaura configurações
Stop-AnyDesk
if (Test-Path "$tempPath\user.conf") {
    Move-Item -Path "$tempPath\user.conf" -Destination "$appDataPath\user.conf" -Force
}
if (Test-Path "$tempPath\thumbnails") {
    Copy-Item -Path "$tempPath\thumbnails" -Destination "$appDataPath\thumbnails" -Recurse -Force
    Remove-Item -Path "$tempPath\thumbnails" -Recurse -Force -ErrorAction SilentlyContinue
}

# Inicia o AnyDesk novamente
Start-AnyDesk

Write-Host "*********"
Write-Host "Concluído."
Read-Host "Pressione Enter para sair"