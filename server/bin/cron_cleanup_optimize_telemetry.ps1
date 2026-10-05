# Limpeza por prazo (D-70). Os prazos vêm do inventário de retenção; não há
# parâmetro de prazo. Sem -Mode, roda o agendado (só apaga depois da ativação
# supervisionada).
param(
  [ValidateSet('scheduled', 'activate', 'deactivate', 'dry-run')]
  [string]$Mode = 'scheduled',
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $scriptDir '..')

$argsList = @('run', 'bin/cleanup_optimize_telemetry.dart')

if ($DryRun) {
  $argsList += '--dry-run'
} else {
  $argsList += @('--mode', $Mode)
}

& dart @argsList
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
