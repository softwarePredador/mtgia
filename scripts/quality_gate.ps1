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
  Write-Header "ManaLoom E2E suite"
  Ensure-Command "bash"
  bash (Join-Path $RootDir "scripts/manaloom_e2e_suite.sh")
}

function Run-ProjectLogic {
  Write-Header "ManaLoom generated project logic and documentation drift"
  $packageDir = Join-Path $RootDir "tools/project_logic"
  Ensure-PackageResolved $packageDir "dart"
  Push-Location $packageDir
  try {
    dart run bin/manaloom_project_logic.dart --check --root $RootDir
    dart test
  }
  finally {
    Pop-Location
  }

  foreach ($relativePackage in @("app", "server", "tools/manaloom_lints", "tools/project_logic")) {
    $packageDir = Join-Path $RootDir $relativePackage
    Ensure-PackageResolved $packageDir "dart"
    Push-Location $packageDir
    try {
      $docOutput = @(dart doc --dry-run 2>&1)
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
  .\scripts\quality_gate.ps1 e2e # suite E2E local: app, deckbuilder, battle, IA, contratos e logs

Dica:
  Use 'quick' durante implementação e 'full' antes de concluir item/sprint.
  O modo 'full' é determinístico e exclui tags live/live_backend/live_db_write/live_external.
  Use o perfil E2E live guardado para chamadas contra uma API real.
  Use 'e2e' para varredura completa local; exporte MANALOOM_RUN_FLUTTER_RUNTIME_E2E=1 ou MANALOOM_RUN_LIVE_PRODUCT_E2E=1 para camadas vivas opcionais.

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
  Ensure-Command "dart"
  Ensure-Command "flutter"

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
