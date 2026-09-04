param(
  [string]$Mode = "quick"
)

$ErrorActionPreference = "Stop"

try {
  [Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)
  [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
  $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
} catch {
  # Não bloquear o gate por limitação de host/terminal
}

$RootDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$BackendTestJwtSecret = if ($env:JWT_SECRET) { $env:JWT_SECRET } else { "local_quality_gate_jwt_secret_not_for_production_20260706" }

function Write-Header([string]$Title) {
  Write-Host ""
  Write-Host "============================================================"
  Write-Host $Title
  Write-Host "============================================================"
}

function Ensure-Command([string]$Name) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Comando não encontrado: $Name"
  }
}

function Ensure-PackageResolved([string]$PackageDir, [string]$Resolver) {
  $packageConfig = Join-Path (Join-Path $PackageDir ".dart_tool") "package_config.json"
  if (-not (Test-Path $packageConfig)) {
    Write-Header "Resolving dependencies: $PackageDir"
    Push-Location $PackageDir
    try {
      & $Resolver pub get
    }
    finally {
      Pop-Location
    }
  }
}

function Run-BackendQuick {
  Write-Header "Backend quick checks"
  Push-Location (Join-Path $RootDir "server")
  try {
    $env:JWT_SECRET = $BackendTestJwtSecret
    $env:RUN_INTEGRATION_TESTS = "0"
    dart test
  }
  finally {
    Pop-Location
  }
}

function Run-BackendFull {
  Write-Header "Backend full checks"
  Push-Location (Join-Path $RootDir "server")
  try {
    Write-Host "ℹ️ Perfil determinístico: tags live/live_backend/live_db_write/live_external ficam excluídas."
    $env:RUN_INTEGRATION_TESTS = "0"
    $env:JWT_SECRET = $BackendTestJwtSecret
    dart test -P all-local
  }
  finally {
    Pop-Location
  }
}

function Run-FrontendQuick {
  Write-Header "Frontend quick checks"
  Push-Location (Join-Path $RootDir "app")
  try {
    flutter analyze --no-fatal-infos
  }
  finally {
    Pop-Location
  }
}

function Run-FrontendFull {
  Write-Header "Frontend full checks"
  Push-Location (Join-Path $RootDir "app")
  try {
    flutter analyze --no-fatal-infos
    flutter test --no-version-check --reporter compact
  }
  finally {
    Pop-Location
  }
}

function Run-UiAudit {
  Write-Header "ManaLoom Flutter UI audit"
  Push-Location (Join-Path $RootDir "app")
  try {
    flutter analyze lib test --no-version-check --no-fatal-infos
    flutter test test/ui test/core/widgets/debug_accessibility_tools_test.dart --no-version-check
  }
  finally {
    Pop-Location
  }
}

function Run-DependencyValidator([string]$PackageDir, [string]$Label) {
  Write-Header "Dependency validator: $Label"
  $fullPackageDir = Join-Path $RootDir $PackageDir
  $resolver = if ($PackageDir -eq "app") { "flutter" } else { "dart" }
  Ensure-PackageResolved $fullPackageDir $resolver
  Push-Location $fullPackageDir
  try {
    dart run dependency_validator
  }
  finally {
    Pop-Location
  }
}

function Run-DependencyAudit {
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue `
    (Join-Path $RootDir "app/playwright-report"), `
    (Join-Path $RootDir "app/test-results"), `
    (Join-Path $RootDir "app/test_bundle.dart")

  Run-DependencyValidator "app" "Flutter app"
  Run-DependencyValidator "server" "Dart Frog server"
  Run-DependencyValidator "tools/manaloom_lints" "ManaLoom custom lint package"
  Run-DependencyValidator "tools/project_logic" "ManaLoom project logic generator"
}

function Run-CustomLint {
  Ensure-PackageResolved (Join-Path $RootDir "tools/manaloom_lints") "dart"
  Ensure-PackageResolved (Join-Path $RootDir "app") "flutter"
  Ensure-PackageResolved (Join-Path $RootDir "server") "dart"

  Write-Header "ManaLoom custom lint package"
  Push-Location (Join-Path $RootDir "tools/manaloom_lints")
  try {
    dart analyze
    dart test
  }
  finally {
    Pop-Location
  }

  Write-Header "ManaLoom Flutter custom_lint"
  Push-Location (Join-Path $RootDir "app")
  try {
    dart run custom_lint
  }
  finally {
    Pop-Location
  }

  Write-Header "ManaLoom backend custom_lint"
  Push-Location (Join-Path $RootDir "server")
  try {
    dart run custom_lint
  }
  finally {
    Pop-Location
  }
}

function Run-PatrolSmoke {
  Write-Header "ManaLoom Patrol critical E2E"
  $appDir = Join-Path $RootDir "app"
  Ensure-PackageResolved $appDir "flutter"
  Push-Location $appDir
  try {
    flutter test patrol_test/manaloom_patrol_smoke_test.dart --no-version-check --dart-define=PATROL_HOT_RESTART=true

    if ($env:MANALOOM_RUN_PATROL_DEVICE_TESTS -eq "1") {
      Write-Header "ManaLoom Patrol device/web CLI run"
      $patrolArgs = @(
        "test",
        "--target",
        "patrol_test/manaloom_patrol_smoke_test.dart",
        "--dart-define=DISABLE_FIREBASE_STARTUP=true",
        "--dart-define=DISABLE_PUSH_INIT=true",
        "--dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true"
      )

      if ($env:MANALOOM_PATROL_DEVICE) {
        $patrolArgs += @("--device", $env:MANALOOM_PATROL_DEVICE)
      }

      if ($env:MANALOOM_PATROL_WEB_HEADLESS) {
        $patrolArgs += "--web-headless=$($env:MANALOOM_PATROL_WEB_HEADLESS)"
      }

      $env:PATROL_ANALYTICS_ENABLED = "false"
      dart run patrol_cli:main @patrolArgs
    }
    else {
      Write-Host ""
      Write-Host "Patrol CLI real nao foi executado porque MANALOOM_RUN_PATROL_DEVICE_TESTS=1 nao foi definido."
      Write-Host "Para rodar em device/emulador: `$env:MANALOOM_RUN_PATROL_DEVICE_TESTS='1'; .\scripts\quality_gate.ps1 patrol-smoke"
      Write-Host "Para rodar no Chrome headless: `$env:MANALOOM_RUN_PATROL_DEVICE_TESTS='1'; `$env:MANALOOM_PATROL_DEVICE='chrome'; `$env:MANALOOM_PATROL_WEB_HEADLESS='true'; .\scripts\quality_gate.ps1 patrol-smoke"
    }
  }
  finally {
    Pop-Location
  }
}

function Run-E2ESuite {
  Write-Header "ManaLoom E2E suite (strict gate)"
  Ensure-Command "bash"
  bash (Join-Path $RootDir "scripts/manaloom_e2e_suite.sh") --strict
  $e2eExitCode = $LASTEXITCODE
  if ($e2eExitCode -ne 0) {
    Write-Host "❌ Gate E2E estrito terminou com exit $e2eExitCode; PARTIAL/SKIP nao recebe credito de PASS."
    exit $e2eExitCode
  }
}

function Get-ProjectLogicPinnedToolchain {
  $expectedFlutterVersion = "3.44.6"
  $expectedFlutterRevision = "ee80f08bbf97172ec030b8751ceab557177a34a6"
  $expectedEngineRevision = "83675ed27633283e7fc296c8bca22e841224c096"
  $expectedDartVersion = "3.12.2"
  $flutterRoot = if ($env:MANALOOM_FLUTTER_ROOT) {
    $env:MANALOOM_FLUTTER_ROOT
  }
  elseif ($env:MANALOOM_FLUTTER_BIN) {
    Split-Path -Parent (Split-Path -Parent $env:MANALOOM_FLUTTER_BIN)
  }
  else {
    Join-Path $HOME ".manaloom/toolchains/flutter-3.44.6"
  }
  $flutterRoot = (Resolve-Path $flutterRoot).Path
  $versionFile = Join-Path $flutterRoot "bin/cache/flutter.version.json"
  if (-not (Test-Path -PathType Leaf $versionFile)) {
    throw "Identidade do Flutter pinado ausente: $versionFile"
  }
  $identity = Get-Content -Raw $versionFile | ConvertFrom-Json
  if (
    $identity.frameworkVersion -ne $expectedFlutterVersion -or
    $identity.frameworkRevision -ne $expectedFlutterRevision -or
    $identity.engineRevision -ne $expectedEngineRevision -or
    $identity.dartSdkVersion -ne $expectedDartVersion
  ) {
    throw "Identidade Flutter/Dart divergente do pin de project logic."
  }
  $isWindowsHost = [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT
  $dartExecutable = if ($isWindowsHost) { "dart.exe" } else { "dart" }
  $dartBin = Join-Path $flutterRoot "bin/cache/dart-sdk/bin/$dartExecutable"
  if (-not (Test-Path -PathType Leaf $dartBin)) {
    throw "Dart pinado ausente: $dartBin"
  }
  $dartVersionOutput = (& $dartBin --version 2>&1 | Out-String)
  if ($LASTEXITCODE -ne 0 -or $dartVersionOutput -notmatch "Dart SDK version:\s+3\.12\.2\b") {
    throw "Dart pinado não é a versão 3.12.2."
  }
  [pscustomobject]@{
    FlutterRoot = $flutterRoot
    DartBin = (Resolve-Path $dartBin).Path
    FlutterVersion = $expectedFlutterVersion
    FlutterRevision = $expectedFlutterRevision
    EngineRevision = $expectedEngineRevision
    DartVersion = $expectedDartVersion
  }
}

function Get-ProjectLogicHostedPins([string[]]$LockPaths) {
  $pins = @{}
  foreach ($lockPath in $LockPaths) {
    if (-not (Test-Path -PathType Leaf $lockPath)) {
      throw "Lock obrigatório ausente: $lockPath"
    }
    $packageName = $null
    $packageSource = $null
    foreach ($line in Get-Content $lockPath) {
      if ($line -match '^  ([A-Za-z_][A-Za-z0-9_]*):$') {
        $packageName = $Matches[1]
        $packageSource = $null
        continue
      }
      if ($line -match '^    source: ([A-Za-z_]+)$') {
        $packageSource = $Matches[1]
        if ($packageSource -notin @("hosted", "path", "sdk")) {
          throw "Fonte de lock não suportada no bootstrap offline: $packageSource"
        }
        continue
      }
      if ($line -match '^    version: "([^"]+)"$' -and $packageSource -eq "hosted") {
        $key = "$packageName$([char]9)$($Matches[1])"
        $pins[$key] = $true
      }
    }
  }
  @($pins.Keys | Sort-Object)
}

function Get-ProjectLogicCacheFingerprint([string]$CacheRoot, [string[]]$Pins) {
  $records = [System.Collections.Generic.List[string]]::new()
  foreach ($pin in $Pins) {
    $parts = $pin -split ([char]9), 2
    $packageName = $parts[0]
    $version = $parts[1]
    $packageRoot = Join-Path $CacheRoot "hosted/pub.dev/$packageName-$version"
    $hashFile = Join-Path $CacheRoot "hosted-hashes/pub.dev/$packageName-$version.sha256"
    if (-not (Test-Path -PathType Container $packageRoot) -or -not (Test-Path -PathType Leaf $hashFile)) {
      throw "Cache offline incompleto para $packageName $version."
    }
    foreach ($file in Get-ChildItem -File -Recurse $packageRoot | Sort-Object FullName) {
      $relative = $file.FullName.Substring($CacheRoot.Length).TrimStart([char[]]@('\', '/'))
      $digest = (Get-FileHash -Algorithm SHA256 $file.FullName).Hash.ToLowerInvariant()
      $records.Add(("file{0}{1}{0}{2}" -f [char]9, $relative, $digest))
    }
    $hashRelative = $hashFile.Substring($CacheRoot.Length).TrimStart([char[]]@('\', '/'))
    $hashDigest = (Get-FileHash -Algorithm SHA256 $hashFile).Hash.ToLowerInvariant()
    $records.Add(("file{0}{1}{0}{2}" -f [char]9, $hashRelative, $hashDigest))
  }
  $payload = ($records | Sort-Object) -join [Environment]::NewLine
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
  $sha256 = [System.Security.Cryptography.SHA256]::Create()
  try {
    -join ($sha256.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") })
  }
  finally {
    $sha256.Dispose()
  }
}

function Get-ProjectLogicActiveRootsFingerprint([string]$CacheRoot) {
  $activeRoots = Join-Path $CacheRoot "active_roots"
  $records = @()
  if (Test-Path -PathType Container $activeRoots) {
    $records = foreach ($file in Get-ChildItem -File -Recurse $activeRoots | Sort-Object FullName) {
      $relative = $file.FullName.Substring($activeRoots.Length).TrimStart([char[]]@('\', '/'))
      $digest = (Get-FileHash -Algorithm SHA256 $file.FullName).Hash.ToLowerInvariant()
      "$relative|$digest"
    }
  }
  $payload = ($records | Sort-Object) -join [Environment]::NewLine
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
  $sha256 = [System.Security.Cryptography.SHA256]::Create()
  try {
    -join ($sha256.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") })
  }
  finally {
    $sha256.Dispose()
  }
}

function Test-ProjectLogicPathsOverlap([string]$Left, [string]$Right) {
  $trimChars = [char[]]@(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
  )
  $leftFull = [System.IO.Path]::GetFullPath($Left).TrimEnd($trimChars)
  $rightFull = [System.IO.Path]::GetFullPath($Right).TrimEnd($trimChars)
  $comparison = [System.StringComparison]::OrdinalIgnoreCase
  $separator = [System.IO.Path]::DirectorySeparatorChar
  return $leftFull.Equals($rightFull, $comparison) -or
    $leftFull.StartsWith("$rightFull$separator", $comparison) -or
    $rightFull.StartsWith("$leftFull$separator", $comparison)
}

function Initialize-ProjectLogicTaskCache(
  [string]$GlobalCache,
  [string]$TaskCache,
  [string[]]$Pins
) {
  New-Item -ItemType Directory -Force $TaskCache | Out-Null
  if (@(Get-ChildItem -Force $TaskCache).Count -ne 0) {
    throw "Cache task-scoped deve iniciar vazio."
  }
  foreach ($pin in $Pins) {
    $parts = $pin -split ([char]9), 2
    $packageName = $parts[0]
    $version = $parts[1]
    $sourcePackage = Join-Path $GlobalCache "hosted/pub.dev/$packageName-$version"
    $targetPackage = Join-Path $TaskCache "hosted/pub.dev/$packageName-$version"
    $sourceHash = Join-Path $GlobalCache "hosted-hashes/pub.dev/$packageName-$version.sha256"
    $targetHash = Join-Path $TaskCache "hosted-hashes/pub.dev/$packageName-$version.sha256"
    New-Item -ItemType Directory -Force (Split-Path -Parent $targetPackage) | Out-Null
    New-Item -ItemType Directory -Force (Split-Path -Parent $targetHash) | Out-Null
    Copy-Item -Recurse -Force $sourcePackage $targetPackage
    Copy-Item -Force $sourceHash $targetHash
  }
}

function Invoke-ProjectLogicPubGet([string]$DartBin, [string]$PackageDir) {
  foreach ($name in @("pubspec.yaml", "pubspec.lock")) {
    if (-not (Test-Path -PathType Leaf (Join-Path $PackageDir $name))) {
      throw "Input de pacote obrigatório ausente: $PackageDir/$name"
    }
  }
  Push-Location $PackageDir
  try {
    & $DartBin pub get --offline --enforce-lockfile --no-precompile
    if ($LASTEXITCODE -ne 0) {
      throw "Bootstrap offline falhou em $PackageDir."
    }
  }
  finally {
    Pop-Location
  }
}

function Get-ProjectLogicDotToolInventory([string]$PackageDir) {
  $dotTool = Join-Path $PackageDir ".dart_tool"
  $records = @()
  if (Test-Path -PathType Container $dotTool) {
    $records = foreach ($entry in Get-ChildItem -Force -Recurse $dotTool | Sort-Object FullName) {
      $relative = $entry.FullName.Substring($dotTool.Length).TrimStart([char[]]@('\', '/'))
      if ($relative -in @("package_config.json", "package_graph.json")) {
        continue
      }
      if ($entry.LinkType) {
        "$relative|link|$($entry.LinkTarget)|$($entry.Attributes)"
      }
      elseif ($entry.PSIsContainer) {
        "$relative|directory|$($entry.Attributes)"
      }
      else {
        $digest = (Get-FileHash -Algorithm SHA256 $entry.FullName).Hash.ToLowerInvariant()
        "$relative|file|$digest|$($entry.Attributes)"
      }
    }
  }
  $payload = $records -join [Environment]::NewLine
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
  $sha256 = [System.Security.Cryptography.SHA256]::Create()
  try {
    -join ($sha256.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") })
  }
  finally {
    $sha256.Dispose()
  }
}

function Run-ProjectLogic {
  Write-Header "ManaLoom generated project logic and documentation drift"
  $toolchain = Get-ProjectLogicPinnedToolchain
  $dartBin = $toolchain.DartBin
  $lockPaths = @(
    (Join-Path $RootDir "pubspec.lock"),
    (Join-Path $RootDir "app/pubspec.lock"),
    (Join-Path $RootDir "server/pubspec.lock"),
    (Join-Path $RootDir "tools/project_logic/pubspec.lock"),
    (Join-Path $RootDir "tools/manaloom_lints/pubspec.lock")
  )
  $packageDirs = @(
    (Join-Path $RootDir "tools/project_logic"),
    $RootDir,
    (Join-Path $RootDir "app"),
    (Join-Path $RootDir "server"),
    (Join-Path $RootDir "tools/manaloom_lints")
  )
  $globalCacheCandidate = if ($env:MANALOOM_PROJECT_LOGIC_GLOBAL_PUB_CACHE) {
    $env:MANALOOM_PROJECT_LOGIC_GLOBAL_PUB_CACHE
  }
  elseif ($env:PUB_CACHE) {
    $env:PUB_CACHE
  }
  else {
    Join-Path $env:LOCALAPPDATA "Pub/Cache"
  }
  $globalCache = (Resolve-Path $globalCacheCandidate).Path
  $taskCache = Join-Path ([System.IO.Path]::GetTempPath()) "manaloom_project_logic_pub_cache.$([Guid]::NewGuid().ToString('N'))"
  if (Test-ProjectLogicPathsOverlap $taskCache $globalCache) {
    throw "Caches Pub task-scoped e global não podem se sobrepor."
  }
  $pins = Get-ProjectLogicHostedPins $lockPaths
  $globalFingerprintBefore = Get-ProjectLogicCacheFingerprint $globalCache $pins
  $globalActiveRootsBefore = Get-ProjectLogicActiveRootsFingerprint $globalCache
  $lockFingerprintBefore = @{}
  foreach ($lockPath in $lockPaths) {
    $lockFingerprintBefore[$lockPath] = (Get-FileHash -Algorithm SHA256 $lockPath).Hash
  }
  $metadataState = @()
  foreach ($packageDir in $packageDirs) {
    $dotTool = Join-Path $packageDir ".dart_tool"
    $config = Join-Path $dotTool "package_config.json"
    $graph = Join-Path $dotTool "package_graph.json"
    $dotToolItem = Get-Item -LiteralPath $dotTool -Force -ErrorAction SilentlyContinue
    if ($null -ne $dotToolItem -and ($dotToolItem.LinkType -or -not $dotToolItem.PSIsContainer)) {
      throw "Metadata .dart_tool deve ser diretório real: $dotTool"
    }
    foreach ($metadataPath in @($config, $graph)) {
      $metadataItem = Get-Item -LiteralPath $metadataPath -Force -ErrorAction SilentlyContinue
      if ($null -ne $metadataItem -and ($metadataItem.LinkType -or $metadataItem.PSIsContainer)) {
        throw "Metadata de pacote linked/não regular é proibida: $metadataPath"
      }
    }
    $metadataState += [pscustomobject]@{
      PackageDir = $packageDir
      DotToolExisted = (Test-Path -PathType Container $dotTool)
      OtherFingerprint = (Get-ProjectLogicDotToolInventory $packageDir)
      ConfigExisted = (Test-Path -PathType Leaf $config)
      ConfigBytes = if (Test-Path -PathType Leaf $config) { [System.IO.File]::ReadAllBytes($config) } else { $null }
      ConfigTimestamp = if (Test-Path -PathType Leaf $config) { (Get-Item $config).LastWriteTimeUtc } else { $null }
      GraphExisted = (Test-Path -PathType Leaf $graph)
      GraphBytes = if (Test-Path -PathType Leaf $graph) { [System.IO.File]::ReadAllBytes($graph) } else { $null }
      GraphTimestamp = if (Test-Path -PathType Leaf $graph) { (Get-Item $graph).LastWriteTimeUtc } else { $null }
    }
  }
  $previousPubCache = $env:PUB_CACHE
  $previousTaskCache = $env:MANALOOM_PROJECT_LOGIC_TASK_PUB_CACHE
  $previousGlobalCache = $env:MANALOOM_PROJECT_LOGIC_GLOBAL_PUB_CACHE
  $previousFlutterRoot = $env:FLUTTER_ROOT
  $cleanupErrors = [System.Collections.Generic.List[string]]::new()
  try {
    Initialize-ProjectLogicTaskCache $globalCache $taskCache $pins
    $taskFingerprint = Get-ProjectLogicCacheFingerprint $taskCache $pins
    if ($taskFingerprint -ne $globalFingerprintBefore) {
      throw "Seed do cache task-scoped diverge do cache global atestado."
    }
    $env:PUB_CACHE = $taskCache
    $env:MANALOOM_PROJECT_LOGIC_TASK_PUB_CACHE = $taskCache
    $env:MANALOOM_PROJECT_LOGIC_GLOBAL_PUB_CACHE = $globalCache
    $env:FLUTTER_ROOT = $toolchain.FlutterRoot

    $projectLogicDir = Join-Path $RootDir "tools/project_logic"
    Invoke-ProjectLogicPubGet $dartBin $projectLogicDir
    & $dartBin (Join-Path $projectLogicDir "bin/manaloom_project_logic.dart") --check --root $RootDir
    if ($LASTEXITCODE -ne 0) {
      throw "CLI project logic falhou."
    }
    Push-Location $projectLogicDir
    try {
      & $dartBin test
      if ($LASTEXITCODE -ne 0) {
        throw "Testes do gerador project logic falharam."
      }
    }
    finally {
      Pop-Location
    }

    foreach ($relativePackage in @("app", "server", "tools/manaloom_lints", "tools/project_logic")) {
      $packageDir = Join-Path $RootDir $relativePackage
      Invoke-ProjectLogicPubGet $dartBin $packageDir
      Push-Location $packageDir
      try {
        $docOutput = @(& $dartBin doc --dry-run 2>&1)
        if ($LASTEXITCODE -ne 0) {
          $docOutput | Write-Host
          throw "dart doc falhou em $relativePackage."
        }
        $warnings = @($docOutput | Select-String -Pattern '^  warning:').Count
        $errors = @($docOutput | Select-String -Pattern '^  error:').Count
        if ($warnings -ne 0 -or $errors -ne 0) {
          $docOutput | Write-Host
          throw "dart doc encontrou $warnings warning(s) e $errors erro(s) em $relativePackage."
        }
        Write-Host "dart doc: $relativePackage sem warnings/erros."
      }
      finally {
        Pop-Location
      }
    }
  }
  finally {
    foreach ($state in $metadataState) {
      $dotTool = Join-Path $state.PackageDir ".dart_tool"
      $config = Join-Path $dotTool "package_config.json"
      $graph = Join-Path $dotTool "package_graph.json"
      if ($state.ConfigExisted) {
        New-Item -ItemType Directory -Force $dotTool | Out-Null
        [System.IO.File]::WriteAllBytes($config, $state.ConfigBytes)
        (Get-Item $config).LastWriteTimeUtc = $state.ConfigTimestamp
      }
      elseif (Test-Path $config) {
        Remove-Item -Force $config
      }
      if ($state.GraphExisted) {
        New-Item -ItemType Directory -Force $dotTool | Out-Null
        [System.IO.File]::WriteAllBytes($graph, $state.GraphBytes)
        (Get-Item $graph).LastWriteTimeUtc = $state.GraphTimestamp
      }
      elseif (Test-Path $graph) {
        Remove-Item -Force $graph
      }
      if ((Get-ProjectLogicDotToolInventory $state.PackageDir) -ne $state.OtherFingerprint) {
        $cleanupErrors.Add("Conteúdo inesperado em $($state.PackageDir)/.dart_tool")
      }
      if (-not $state.DotToolExisted -and (Test-Path -PathType Container $dotTool)) {
        if (@(Get-ChildItem -Force $dotTool).Count -eq 0) {
          Remove-Item -Force $dotTool
        }
        else {
          $cleanupErrors.Add("Diretório .dart_tool residual em $($state.PackageDir)")
        }
      }
    }
    foreach ($lockPath in $lockPaths) {
      if ((Get-FileHash -Algorithm SHA256 $lockPath).Hash -ne $lockFingerprintBefore[$lockPath]) {
        $cleanupErrors.Add("Lock mudou durante project logic: $lockPath")
      }
    }
    if ((Get-ProjectLogicCacheFingerprint $globalCache $pins) -ne $globalFingerprintBefore) {
      $cleanupErrors.Add("Cache Pub global mudou durante project logic.")
    }
    if ((Get-ProjectLogicActiveRootsFingerprint $globalCache) -ne $globalActiveRootsBefore) {
      $cleanupErrors.Add("active_roots do cache Pub global mudou durante project logic.")
    }
    if (Test-Path -PathType Container $taskCache) {
      Remove-Item -Recurse -Force $taskCache
    }
    if (Test-Path $taskCache) {
      $cleanupErrors.Add("Cache task-scoped residual: $taskCache")
    }
    $env:PUB_CACHE = $previousPubCache
    $env:MANALOOM_PROJECT_LOGIC_TASK_PUB_CACHE = $previousTaskCache
    $env:MANALOOM_PROJECT_LOGIC_GLOBAL_PUB_CACHE = $previousGlobalCache
    $env:FLUTTER_ROOT = $previousFlutterRoot
    if ($cleanupErrors.Count -ne 0) {
      throw ($cleanupErrors -join [Environment]::NewLine)
    }
  }
}

function Show-Usage {
  @"
Uso:
  .\scripts\quality_gate.ps1 quick   # validação rápida (dart test + flutter analyze)
  .\scripts\quality_gate.ps1 full    # validação completa (dart test + flutter analyze + flutter test)
  .\scripts\quality_gate.ps1 ui-audit # golden/accessibility audit das telas críticas Flutter
  .\scripts\quality_gate.ps1 deps # valida dependências declaradas no app/server/lints
  .\scripts\quality_gate.ps1 custom-lint # roda regras customizadas ManaLoom no app/server
  .\scripts\quality_gate.ps1 patrol-smoke # valida fluxos E2E criticos do Patrol
  .\scripts\quality_gate.ps1 project-logic # manifesto, OpenAPI, ERD e drift documental
  .\scripts\quality_gate.ps1 e2e # gate E2E estrito: PARTIAL/SKIP retorna nao-zero

Dica:
  Use 'quick' durante implementação e 'full' antes de concluir item/sprint.
  O modo 'full' é determinístico e exclui tags live/live_backend/live_db_write/live_external.
  Use o perfil E2E live guardado para chamadas contra uma API real.
  Use 'e2e' como gate estrito: somente PASS retorna zero. Para diagnostico
  PARTIAL sem credito de gate/release, execute no bash:
  ./scripts/manaloom_e2e_suite.sh --allow-partial

Exemplos:
  .\scripts\quality_gate.ps1 full
  .\scripts\quality_gate.ps1 ui-audit
  .\scripts\quality_gate.ps1 deps
  .\scripts\quality_gate.ps1 custom-lint
  .\scripts\quality_gate.ps1 patrol-smoke
  .\scripts\quality_gate.ps1 project-logic
  .\scripts\quality_gate.ps1 e2e
"@
}

try {
  if ($Mode.ToLowerInvariant() -ne "project-logic") {
    Ensure-Command "dart"
    Ensure-Command "flutter"
  }

  switch ($Mode.ToLowerInvariant()) {
    "quick" {
      Run-BackendQuick
      Run-FrontendQuick
      break
    }
    "full" {
      Run-BackendFull
      Run-FrontendFull
      break
    }
    "ui-audit" {
      Run-UiAudit
      break
    }
    "deps" {
      Run-DependencyAudit
      break
    }
    "custom-lint" {
      Run-CustomLint
      break
    }
    "patrol-smoke" {
      Run-PatrolSmoke
      break
    }
    "project-logic" {
      Run-ProjectLogic
      break
    }
    "e2e" {
      Run-E2ESuite
      break
    }
    "help" {
      Show-Usage
      exit 0
    }
    "-h" {
      Show-Usage
      exit 0
    }
    "--help" {
      Show-Usage
      exit 0
    }
    default {
      throw "Modo inválido: $Mode`n`n$(Show-Usage)"
    }
  }

  Write-Header "Quality gate concluído"
  Write-Host "✅ Todos os checks do modo '$Mode' passaram."
}
catch {
  Write-Host "❌ $($_.Exception.Message)"
  exit 1
}
