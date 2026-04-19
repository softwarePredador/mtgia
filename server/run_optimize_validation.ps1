$ErrorActionPreference = 'Stop'

Set-Location $PSScriptRoot

try {
    & .\start_local_test_server.ps1

    Write-Host 'Aguardando backend local iniciar em http://127.0.0.1:8080 ...'
    $isUp = $false

    for ($attempt = 1; $attempt -le 12; $attempt++) {
        Start-Sleep -Seconds 5
        $statusCode = & curl.exe -s -o NUL -w "%{http_code}" http://127.0.0.1:8080/health/live
        if ($statusCode -eq '200') {
            $isUp = $true
            break
        }
    }

    if (-not $isUp) {
        Write-Host 'Backend nao respondeu dentro da janela esperada.'
        $stdoutLog = Join-Path $PSScriptRoot 'test\artifacts\local_test_server.stdout.log'
        $stderrLog = Join-Path $PSScriptRoot 'test\artifacts\local_test_server.stderr.log'
        if (Test-Path $stdoutLog) {
            Get-Content $stdoutLog | Write-Host
        }
        if (Test-Path $stderrLog) {
            Get-Content $stderrLog | Write-Host
        }
        exit 1
    }

    $env:RUN_INTEGRATION_TESTS = '1'

    Write-Host "`n=== CORE TESTS ===`n"
    & dart test `
        test/optimization_rules_test.dart `
        test/optimization_quality_gate_test.dart `
        test/optimization_final_validation_test.dart `
        test/optimization_goal_validation_test.dart `
        test/optimization_validator_test.dart `
        test/goldfish_simulator_test.dart `
        test/generated_deck_validation_service_test.dart `
        test/optimize_learning_pipeline_test.dart `
        test/optimize_payload_parser_test.dart `
        test/optimization_pipeline_integration_test.dart
    $coreExit = $LASTEXITCODE

    Write-Host "`n=== HTTP OPTIMIZE FLOW ===`n"
    & dart test test/ai_optimize_flow_test.dart
    $optimizeExit = $LASTEXITCODE

    Write-Host "`n=== HTTP GENERATE -> CREATE -> OPTIMIZE ===`n"
    & dart test test/ai_generate_create_optimize_flow_test.dart
    $generateFlowExit = $LASTEXITCODE

    if ($coreExit -ne 0 -or $optimizeExit -ne 0 -or $generateFlowExit -ne 0) {
        exit 1
    }

    exit 0
} finally {
    & .\stop_local_test_server.ps1
}
