$ErrorActionPreference = 'Stop'

Set-Location $PSScriptRoot

$artifactsDir = Join-Path $PSScriptRoot 'test\artifacts'
New-Item -ItemType Directory -Force -Path $artifactsDir | Out-Null

$tag = $env:LOCAL_TEST_SERVER_TAG
$fileStem = if ([string]::IsNullOrWhiteSpace($tag)) { 'local_test_server' } else { "local_test_server.$tag" }

$stdoutLog = Join-Path $artifactsDir "$fileStem.stdout.log"
$stderrLog = Join-Path $artifactsDir "$fileStem.stderr.log"
$pidFile = Join-Path $artifactsDir "$fileStem.pid"
$portFile = Join-Path $artifactsDir "$fileStem.port"

function Test-PortInUse([int]$port) {
    try {
        $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction Stop
        return $null -ne $conn
    } catch {
        return $false
    }
}

function Select-FreePort([int]$startPort, [int]$maxTries = 30) {
    for ($offset = 0; $offset -le $maxTries; $offset++) {
        $p = $startPort + $offset
        if (-not (Test-PortInUse $p)) {
            return $p
        }
    }

    throw "Nenhuma porta livre encontrada a partir de $startPort"
}

if (Test-Path $pidFile) {
    $existingPid = Get-Content $pidFile -ErrorAction SilentlyContinue
    if ($existingPid) {
        $existingProcess = Get-Process -Id $existingPid -ErrorAction SilentlyContinue
        if ($existingProcess) {
            if (Test-Path $portFile) {
                $existingPort = Get-Content $portFile -ErrorAction SilentlyContinue
                if ($existingPort) {
                    Write-Host "Servidor ja esta rodando com PID $existingPid (porta $existingPort)."
                    exit 0
                }
            }

            Write-Host "Servidor ja esta rodando com PID $existingPid."
            exit 0
        }
    }
}

# PowerShell 5.1 compat: evitar o operador ??
$requestedPort = 8080
if ($env:PORT) {
    $parsedPort = 0
    if ([int]::TryParse($env:PORT, [ref]$parsedPort)) {
        $requestedPort = $parsedPort
    }
}

$port = $requestedPort
if (Test-PortInUse $port) {
    $port = Select-FreePort $requestedPort 50
    Write-Host "Porta $requestedPort ocupada. Usando porta livre $port."
}

$env:PORT = "$port"

$process = Start-Process `
    -FilePath (Get-Command dart).Source `
    -ArgumentList 'run', 'bin/local_test_server.dart' `
    -WorkingDirectory $PSScriptRoot `
    -RedirectStandardOutput $stdoutLog `
    -RedirectStandardError $stderrLog `
    -PassThru `
    -WindowStyle Hidden

Start-Sleep -Milliseconds 400
$process.Refresh()
if ($process.HasExited) {
    Write-Host 'Servidor de teste encerrou ao iniciar.'
    if (Test-Path $stderrLog) { Get-Content $stderrLog | Write-Host }
    exit 1
}

# Em alguns ambientes do Windows, o dart.exe pode repassar para dartvm e encerrar.
# Para garantir que o stop script mate o listener real, persistimos o PID que está
# ouvindo na porta (quando possível).
$listenerPid = $null
for ($attempt = 1; $attempt -le 50; $attempt++) {
    try {
        $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($conn) {
            $listenerPid = $conn.OwningProcess
            break
        }
    } catch {
        # ignore
    }

    Start-Sleep -Milliseconds 200
    $process.Refresh()
    if ($process.HasExited) {
        Write-Host 'Servidor de teste encerrou ao iniciar.'
        if (Test-Path $stderrLog) { Get-Content $stderrLog | Write-Host }
        exit 1
    }
}

if (-not $listenerPid) {
    $listenerPid = $process.Id
}

Set-Content -Path $pidFile -Value $listenerPid
Set-Content -Path $portFile -Value $port
Write-Host "Servidor de teste iniciado com PID $listenerPid (porta $port)."
