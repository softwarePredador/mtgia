param(
    [string]$BaseUrl = "http://127.0.0.1:8080",
    [string]$Email = "",
    [string]$Password = "",
    [switch]$SkipLogin
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Invoke-JsonRequest {
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Url,
        [hashtable]$Headers,
        [object]$Body,
        [int]$TimeoutSec = 10
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $params = @{
            Method           = $Method
            Uri              = $Url
            TimeoutSec       = $TimeoutSec
            ErrorAction      = "Stop"
            UseBasicParsing  = $true
        }

        if ($Headers) {
            $params["Headers"] = $Headers
        }

        if ($null -ne $Body) {
            $params["ContentType"] = "application/json"
            $params["Body"] = ($Body | ConvertTo-Json -Depth 10)
        }

        $response = Invoke-WebRequest @params
        $stopwatch.Stop()

        $content = $response.Content
        $json = $null
        if ($content) {
            try {
                $json = $content | ConvertFrom-Json
            } catch {
                $json = $content
            }
        }

        return [PSCustomObject]@{
            Ok         = $true
            StatusCode = [int]$response.StatusCode
            ElapsedMs  = $stopwatch.ElapsedMilliseconds
            Content    = $json
            Error      = $null
        }
    } catch {
        $stopwatch.Stop()

        $statusCode = $null
        $content = $null
        $response = $null

        if ($_.Exception.PSObject.Properties["Response"]) {
            $response = $_.Exception.Response
        }

        if ($response) {
            if ($response.PSObject.Properties["StatusCode"]) {
                $statusCode = [int]$response.StatusCode
            } elseif ($response.PSObject.Properties["BaseResponse"]) {
                $statusCode = [int]$response.BaseResponse.StatusCode
            }
            try {
                if ($response.PSObject.Properties["Content"]) {
                    $content = $response.Content
                } elseif ($response.PSObject.Properties["GetResponseStream"]) {
                    $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
                    $content = $reader.ReadToEnd()
                }
                if ($content) {
                    try {
                        $content = $content | ConvertFrom-Json
                    } catch {
                        # Keep raw text when response is not JSON.
                    }
                }
            } catch {
                $content = $null
            }
        }

        return [PSCustomObject]@{
            Ok         = $false
            StatusCode = $statusCode
            ElapsedMs  = $stopwatch.ElapsedMilliseconds
            Content    = $content
            Error      = $_.Exception.Message
        }
    }
}

$normalizedBaseUrl = $BaseUrl.TrimEnd("/")
$exitCode = 0

Write-Host "ManaLoom backend auth readiness check" -ForegroundColor Green
Write-Host "Base URL: $normalizedBaseUrl"

Write-Step "GET /health"
$health = Invoke-JsonRequest -Method "GET" -Url "$normalizedBaseUrl/health" -TimeoutSec 5
if ($health.Ok -and $health.StatusCode -eq 200) {
    Write-Host "OK    /health ($($health.ElapsedMs) ms)" -ForegroundColor Green
} else {
    Write-Host "FAIL  /health ($($health.ElapsedMs) ms) - $($health.Error)" -ForegroundColor Red
    if ($health.StatusCode) {
        Write-Host "Status: $($health.StatusCode)"
    }
    if ($health.Content) {
        Write-Host "Body: $($health.Content | ConvertTo-Json -Depth 10 -Compress)"
    }
    exit 1
}

Write-Step "GET /health/ready"
$ready = Invoke-JsonRequest -Method "GET" -Url "$normalizedBaseUrl/health/ready" -TimeoutSec 8
if ($ready.Ok -and $ready.StatusCode -eq 200) {
    Write-Host "OK    /health/ready ($($ready.ElapsedMs) ms)" -ForegroundColor Green
} else {
    Write-Host "WARN  /health/ready ($($ready.ElapsedMs) ms)" -ForegroundColor Yellow
    if ($ready.StatusCode) {
        Write-Host "Status: $($ready.StatusCode)"
    }
    if ($ready.Error) {
        Write-Host "Error: $($ready.Error)"
    }
    if ($ready.Content) {
        Write-Host "Body: $($ready.Content | ConvertTo-Json -Depth 10 -Compress)"
    }
    $exitCode = 1
}

if (-not $SkipLogin) {
    if ([string]::IsNullOrWhiteSpace($Email) -or [string]::IsNullOrWhiteSpace($Password)) {
        Write-Step "POST /auth/login"
        Write-Host "SKIP  login check - informe -Email e -Password ou use -SkipLogin." -ForegroundColor Yellow
    } else {
        Write-Step "POST /auth/login"
        $login = Invoke-JsonRequest `
            -Method "POST" `
            -Url "$normalizedBaseUrl/auth/login" `
            -Body @{
                email = $Email
                password = $Password
            } `
            -TimeoutSec 20

        if ($login.Ok -and $login.StatusCode -eq 200) {
            $userEmail = $null
            if ($login.Content -and $login.Content.user) {
                $userEmail = $login.Content.user.email
            }
            Write-Host "OK    /auth/login ($($login.ElapsedMs) ms)" -ForegroundColor Green
            if ($userEmail) {
                Write-Host "User: $userEmail"
            }
        } else {
            Write-Host "FAIL  /auth/login ($($login.ElapsedMs) ms)" -ForegroundColor Red
            if ($login.StatusCode) {
                Write-Host "Status: $($login.StatusCode)"
            }
            if ($login.Error) {
                Write-Host "Error: $($login.Error)"
            }
            if ($login.Content) {
                Write-Host "Body: $($login.Content | ConvertTo-Json -Depth 10 -Compress)"
            }
            $exitCode = 1
        }
    }
}

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "Backend pronto para teste de login no app." -ForegroundColor Green
} else {
    Write-Host "Backend ainda nao esta confiavel para teste de login no app." -ForegroundColor Yellow
}

exit $exitCode
