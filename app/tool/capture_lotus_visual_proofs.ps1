param(
  [string]$Device = "emulator-5554",
  [string]$Stage = "",
  [string]$OutputDirectory = ""
)

$ErrorActionPreference = "Stop"

$appRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $appRoot

function Get-AndroidDebugBridge {
  $sdkAdb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
  if (Test-Path $sdkAdb) {
    return $sdkAdb
  }

  $adbCommand = Get-Command adb -ErrorAction SilentlyContinue
  if ($adbCommand) {
    return $adbCommand.Path
  }

  throw "adb.exe was not found."
}

function Get-FlutterCommandPath {
  $flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
  if (-not $flutterCommand) {
    throw "flutter was not found on PATH."
  }

  return $flutterCommand.Path
}

function Wait-ForTopActivity {
  param(
    [string]$AdbPath,
    [string]$DeviceId,
    [string]$PackageName,
    [int]$TimeoutSeconds = 180
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $output = & $AdbPath -s $DeviceId shell dumpsys activity activities 2>$null
    if ($output -match [regex]::Escape($PackageName)) {
      return
    }
    Start-Sleep -Seconds 2
  }

  throw "Timed out waiting for $PackageName to reach the foreground."
}

function Save-DeviceScreenshot {
  param(
    [string]$AdbPath,
    [string]$DeviceId,
    [string]$DestinationPath
  )

  $destinationDirectory = Split-Path -Parent $DestinationPath
  if (-not (Test-Path $destinationDirectory)) {
    New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
  }

  $cmd = '"' + $AdbPath + '" -s ' + $DeviceId + ' exec-out screencap -p > "' + $DestinationPath + '"'
  cmd.exe /c $cmd | Out-Null

  if (-not (Test-Path $DestinationPath)) {
    throw "Screenshot was not created: $DestinationPath"
  }

  $length = (Get-Item $DestinationPath).Length
  if ($length -le 0) {
    throw "Screenshot is empty: $DestinationPath"
  }
}

function Stop-RunProcessTree {
  param([int]$ProcessId)

  cmd.exe /c "taskkill /PID $ProcessId /T /F" | Out-Null
}

$adb = Get-AndroidDebugBridge
$flutter = Get-FlutterCommandPath
$packageName = "com.mtgia.mtg_app"

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
  $OutputDirectory = Join-Path $appRoot "doc\lotus_visual_proofs_2026-04-05"
}

if (-not (Test-Path $OutputDirectory)) {
  New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

$stages = @(
  [pscustomobject]@{ Key = "base_table"; Proof = $null; Description = "Base table without injected overlay" },
  [pscustomobject]@{ Key = "menu_overlay"; Proof = "menu_overlay"; Description = "Menu chips overlay" },
  [pscustomobject]@{ Key = "first_time_commander_damage"; Proof = "first_time_commander_damage"; Description = "First-time tutorial - commander damage step" },
  [pscustomobject]@{ Key = "first_time_player_options"; Proof = "first_time_player_options"; Description = "First-time tutorial - player options step" },
  [pscustomobject]@{ Key = "first_time_fullscreen_mode"; Proof = "first_time_fullscreen_mode"; Description = "First-time tutorial - fullscreen step" },
  [pscustomobject]@{ Key = "own_commander_damage_hint"; Proof = "own_commander_damage_hint"; Description = "Own commander damage hint overlay" },
  [pscustomobject]@{ Key = "turn_tracker_hint_step1"; Proof = "turn_tracker_hint_step1"; Description = "Turn tracker hint step 1" },
  [pscustomobject]@{ Key = "turn_tracker_hint_step2"; Proof = "turn_tracker_hint_step2"; Description = "Turn tracker hint step 2" },
  [pscustomobject]@{ Key = "show_counters_hint"; Proof = "show_counters_hint"; Description = "Counters hint overlay" }
)

$filteredStages = if ([string]::IsNullOrWhiteSpace($Stage)) {
  $stages
} else {
  $stages | Where-Object { $_.Key -eq $Stage }
}

if (-not $filteredStages -or $filteredStages.Count -eq 0) {
  throw "No stages matched '$Stage'."
}

$manifestLines = @(
  "# Lotus Visual Proofs",
  "",
  "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
  "Device: $Device",
  ""
)

foreach ($stageItem in $filteredStages) {
  & $adb -s $Device shell am force-stop $packageName | Out-Null
  Start-Sleep -Seconds 2

  $stdoutPath = Join-Path $OutputDirectory "$($stageItem.Key).stdout.log"
  $stderrPath = Join-Path $OutputDirectory "$($stageItem.Key).stderr.log"
  $pngPath = Join-Path $OutputDirectory "$($stageItem.Key).png"

  $arguments = @(
    "run",
    "-d", $Device,
    "--dart-define=DEBUG_BOOT_INTO_LIFE_COUNTER=true"
  )

  if ($stageItem.Proof) {
    $arguments += "--dart-define=DEBUG_LOTUS_VISUAL_PROOF=$($stageItem.Proof)"
  }

  $process = Start-Process -FilePath $flutter `
    -ArgumentList $arguments `
    -WorkingDirectory $appRoot `
    -RedirectStandardOutput $stdoutPath `
    -RedirectStandardError $stderrPath `
    -PassThru

  try {
    Wait-ForTopActivity -AdbPath $adb -DeviceId $Device -PackageName $packageName
    Start-Sleep -Seconds 65
    Save-DeviceScreenshot -AdbPath $adb -DeviceId $Device -DestinationPath $pngPath

    $manifestLines += "- [$($stageItem.Key)]($pngPath)"
    $manifestLines += "  $($stageItem.Description)"
  }
  finally {
    if (-not $process.HasExited) {
      Stop-RunProcessTree -ProcessId $process.Id
    }

    & $adb -s $Device shell am force-stop $packageName | Out-Null
    Start-Sleep -Seconds 2
  }
}

$manifestPath = Join-Path $OutputDirectory "README.md"
Set-Content -Path $manifestPath -Value $manifestLines -Encoding UTF8

Write-Output $OutputDirectory
