$ErrorActionPreference = 'Stop'

Set-Location $PSScriptRoot

try {
    $runTag = [Guid]::NewGuid().ToString('N').Substring(0, 8)
    $env:LOCAL_TEST_SERVER_TAG = $runTag

    if (-not $env:OPTIMIZE_COMPLETE_DISABLE_OPENAI) {
        $env:OPTIMIZE_COMPLETE_DISABLE_OPENAI = '1'
    }

    if (-not $env:VALIDATION_CORPUS_PATH) {
        $env:VALIDATION_CORPUS_PATH = 'test/fixtures/optimization_resolution_corpus.json'
    }

    if (-not $env:VALIDATION_LIMIT) {
        $env:VALIDATION_LIMIT = '19'
    }

    & .\start_local_test_server.ps1

    $fileStem = "local_test_server.$runTag"
    $portFile = Join-Path $PSScriptRoot "test\artifacts\$fileStem.port"
    $port = 8080
    if (Test-Path $portFile) {
        $portValue = (Get-Content $portFile -ErrorAction SilentlyContinue | Select-Object -First 1)
        if ($portValue) {
            $parsedPort = [int]$portValue
            if ($parsedPort -gt 0) { $port = $parsedPort }
        }
    }

    $baseUrl = "http://127.0.0.1:$port"
    Write-Host "Aguardando backend local iniciar em $baseUrl ..."
    $isUp = $false

    for ($attempt = 1; $attempt -le 12; $attempt++) {
        Start-Sleep -Seconds 5
        $statusCode = & curl.exe -s -o NUL -w "%{http_code}" "$baseUrl/health/live"
        if ($statusCode -eq '200') {
            $isUp = $true
            break
        }
    }

    if (-not $isUp) {
        Write-Host 'Backend nao respondeu dentro da janela esperada.'
        exit 1
    }

    $env:TEST_API_BASE_URL = $baseUrl

    & dart run bin/run_commander_only_optimization_validation.dart
    exit $LASTEXITCODE
} finally {
    & .\stop_local_test_server.ps1
}
