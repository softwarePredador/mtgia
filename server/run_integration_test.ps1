# Start server in background, wait, run test, then kill server
$serverJob = Start-Job -ScriptBlock {
    Set-Location C:\Users\rafae\Documents\project\mtgia\server
    & dart_frog dev 2>&1
}

Write-Host "⏳ Aguardando server iniciar..."
Start-Sleep -Seconds 8

# Verify server is up
try {
    $null = Invoke-WebRequest -Uri "http://localhost:8080/cards?limit=1" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ Server respondendo!"
} catch {
    Write-Host "❌ Server não respondeu. Tentando mais 5s..."
    Start-Sleep -Seconds 5
    try {
        $null = Invoke-WebRequest -Uri "http://localhost:8080/cards?limit=1" -TimeoutSec 5 -ErrorAction Stop
        Write-Host "✅ Server respondendo!"
    } catch {
        Write-Host "❌ Server não iniciou. Abortando."
        Stop-Job $serverJob -ErrorAction SilentlyContinue
        Remove-Job $serverJob -ErrorAction SilentlyContinue
        exit 1
    }
}

# Run integration test
Write-Host "`n🧪 Rodando teste de integração...`n"
Set-Location C:\Users\rafae\Documents\project\mtgia\server
& dart run test/integration_binder_test.dart
$testExitCode = $LASTEXITCODE

# Cleanup
Write-Host "`n🧹 Parando server..."
Stop-Job $serverJob -ErrorAction SilentlyContinue
Remove-Job $serverJob -ErrorAction SilentlyContinue
Get-Process dart -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

exit $testExitCode
