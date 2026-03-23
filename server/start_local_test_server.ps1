$ErrorActionPreference = 'Stop'

Set-Location $PSScriptRoot

$stdoutLog = Join-Path $PSScriptRoot 'test\artifacts\local_test_server.stdout.log'
$stderrLog = Join-Path $PSScriptRoot 'test\artifacts\local_test_server.stderr.log'
$pidFile = Join-Path $PSScriptRoot 'test\artifacts\local_test_server.pid'

if (Test-Path $pidFile) {
    $existingPid = Get-Content $pidFile -ErrorAction SilentlyContinue
    if ($existingPid) {
        $existingProcess = Get-Process -Id $existingPid -ErrorAction SilentlyContinue
        if ($existingProcess) {
            Write-Host "Servidor ja esta rodando com PID $existingPid."
            exit 0
        }
    }
}

$process = Start-Process `
    -FilePath (Get-Command dart).Source `
    -ArgumentList 'run', 'bin/local_test_server.dart' `
    -WorkingDirectory $PSScriptRoot `
    -RedirectStandardOutput $stdoutLog `
    -RedirectStandardError $stderrLog `
    -PassThru `
    -WindowStyle Hidden

Set-Content -Path $pidFile -Value $process.Id
Write-Host "Servidor de teste iniciado com PID $($process.Id)."
