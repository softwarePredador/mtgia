param(
    [string]$BaseUrl = "http://127.0.0.1:8080",
    [Parameter(Mandatory = $true)][string]$DeckId,
    [Parameter(Mandatory = $true)][string]$Archetype,
    [string]$AuthToken,
    [int]$Bracket = 2,
    [bool]$KeepTheme = $true,
    [int]$Runs = 10,
    [int]$PollIntervalMs = 2000,
    [int]$MaxPolls = 150
)

$ErrorActionPreference = 'Stop'

Set-Location $PSScriptRoot

$artifactsDir = Join-Path $PSScriptRoot 'test\artifacts'
New-Item -ItemType Directory -Force -Path $artifactsDir | Out-Null

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$outputPath = Join-Path $artifactsDir "optimize-baseline.$timestamp.json"

function Invoke-OptimizeRun {
    param(
        [int]$RunNumber
    )

    $payload = @{
        deck_id = $DeckId
        archetype = $Archetype
        bracket = $Bracket
        keep_theme = $KeepTheme
    }
    $headers = @{}
    if (-not [string]::IsNullOrWhiteSpace($AuthToken)) {
        $headers['Authorization'] = "Bearer $AuthToken"
    }

    $bodyJson = $payload | ConvertTo-Json -Depth 8
    $requestSw = [System.Diagnostics.Stopwatch]::StartNew()
    $response = Invoke-WebRequest `
        -UseBasicParsing `
        -Uri "$BaseUrl/ai/optimize" `
        -Method POST `
        -ContentType 'application/json' `
        -Headers $headers `
        -Body $bodyJson
    $requestSw.Stop()

    $parsed = $response.Content | ConvertFrom-Json
    $run = [ordered]@{
        run = $RunNumber
        requested_at = (Get-Date).ToString('o')
        request_latency_ms = $requestSw.ElapsedMilliseconds
        status_code = [int]$response.StatusCode
        initial_mode = $parsed.mode
        initial_timings = $parsed.timings
    }

    if ($parsed.job_id) {
        $jobSw = [System.Diagnostics.Stopwatch]::StartNew()
        $polls = @()
        $finalJob = $null

        for ($poll = 1; $poll -le $MaxPolls; $poll++) {
            Start-Sleep -Milliseconds $PollIntervalMs
            $pollResponse = Invoke-WebRequest `
                -UseBasicParsing `
                -Uri "$BaseUrl$($parsed.poll_url)" `
                -Method GET `
                -Headers $headers
            $pollParsed = $pollResponse.Content | ConvertFrom-Json

            $polls += [ordered]@{
                poll = $poll
                status = $pollParsed.status
                stage = $pollParsed.stage
                stage_number = $pollParsed.stage_number
                total_stages = $pollParsed.total_stages
            }

            if ($pollParsed.status -eq 'completed' -or $pollParsed.status -eq 'failed') {
                $finalJob = $pollParsed
                break
            }
        }

        $jobSw.Stop()

        $run.poll_interval_ms = $PollIntervalMs
        $run.total_job_time_ms = $jobSw.ElapsedMilliseconds
        $run.poll_count = $polls.Count
        $run.polls = $polls
        $run.job_status = $finalJob.status
        $run.final_stage = $finalJob.stage
        $run.result_mode = $finalJob.result.mode
        $run.result_timings = $finalJob.result.timings
        if ($finalJob.error) {
            $run.error = $finalJob.error
        }
        if ($finalJob.quality_error) {
            $run.quality_error = $finalJob.quality_error
        }
        return $run
    }

    $run.result_mode = $parsed.mode
    $run.result_timings = $parsed.timings
    $run.removals = @($parsed.removals).Count
    $run.additions = @($parsed.additions).Count
    return $run
}

$results = @()
for ($i = 1; $i -le $Runs; $i++) {
    Write-Host "Run $i/$Runs -> POST $BaseUrl/ai/optimize"
    $results += Invoke-OptimizeRun -RunNumber $i
}

$requestLatencies = @($results | ForEach-Object { [int]($_.request_latency_ms) })
$jobDurations = @($results | Where-Object { $_.total_job_time_ms } | ForEach-Object { [int]($_.total_job_time_ms) })

$summary = [ordered]@{
    base_url = $BaseUrl
    deck_id = $DeckId
    archetype = $Archetype
    runs = $Runs
    generated_at = (Get-Date).ToString('o')
    avg_request_latency_ms = if ($requestLatencies.Count -gt 0) { [math]::Round(($requestLatencies | Measure-Object -Average).Average, 2) } else { 0 }
    max_request_latency_ms = if ($requestLatencies.Count -gt 0) { ($requestLatencies | Measure-Object -Maximum).Maximum } else { 0 }
    avg_total_job_time_ms = if ($jobDurations.Count -gt 0) { [math]::Round(($jobDurations | Measure-Object -Average).Average, 2) } else { $null }
    max_total_job_time_ms = if ($jobDurations.Count -gt 0) { ($jobDurations | Measure-Object -Maximum).Maximum } else { $null }
    results = $results
}

$summary | ConvertTo-Json -Depth 20 | Set-Content -Path $outputPath -Encoding UTF8
Write-Host "Baseline salvo em $outputPath"
