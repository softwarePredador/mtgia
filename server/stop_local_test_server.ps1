$ErrorActionPreference = 'Stop'

Set-Location $PSScriptRoot

$pidFile = Join-Path $PSScriptRoot 'test\artifacts\local_test_server.pid'

if (-not (Test-Path $pidFile)) {
    Write-Host 'Nenhum PID file encontrado para o servidor de teste.'
    exit 0
}

$pidValue = Get-Content $pidFile -ErrorAction SilentlyContinue
if ($pidValue) {
    $process = Get-Process -Id $pidValue -ErrorAction SilentlyContinue
    if ($process) {
        Stop-Process -Id $pidValue -Force -ErrorAction SilentlyContinue
        Write-Host "Servidor de teste encerrado (PID $pidValue)."
    }
}

Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
