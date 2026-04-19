$ErrorActionPreference = 'Stop'

Set-Location $PSScriptRoot

$artifactsDir = Join-Path $PSScriptRoot 'test\artifacts'

$tag = $env:LOCAL_TEST_SERVER_TAG
$fileStem = if ([string]::IsNullOrWhiteSpace($tag)) { 'local_test_server' } else { "local_test_server.$tag" }

$pidFile = Join-Path $artifactsDir "$fileStem.pid"
$portFile = Join-Path $artifactsDir "$fileStem.port"

function Get-ChildPids([int]$parentPid) {
    $children = Get-CimInstance Win32_Process -Filter "ParentProcessId=$parentPid" -ErrorAction SilentlyContinue
    if (-not $children) { return @() }

    $pids = @()
    foreach ($child in $children) {
        $pids += [int]$child.ProcessId
        $pids += Get-ChildPids ([int]$child.ProcessId)
    }

    return $pids
}

function Stop-ProcessTree([int]$rootPid) {
    $pids = @(Get-ChildPids $rootPid) + @($rootPid)
    $pids = $pids | Where-Object { $_ -gt 0 } | Select-Object -Unique | Sort-Object -Descending

    foreach ($procId in $pids) {
        Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
    }
}

# Se não tiver PID file, ainda tentamos limpar o listener pela porta (se existir).
if (-not (Test-Path $pidFile)) {
    Write-Host 'Nenhum PID file encontrado para o servidor de teste.'

    if (Test-Path $portFile) {
        $portValue = (Get-Content $portFile -ErrorAction SilentlyContinue | Select-Object -First 1)
        if ($portValue) {
            $port = [int]$portValue
            Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty OwningProcess -Unique |
                ForEach-Object { Stop-ProcessTree ([int]$_) }
        }
    }

    Remove-Item $portFile -Force -ErrorAction SilentlyContinue
    exit 0
}

$pidValue = (Get-Content $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1)
if ($pidValue) {
    Stop-ProcessTree ([int]$pidValue)
    Write-Host "Servidor de teste encerrado (PID $pidValue)."
}

Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
Remove-Item $portFile -Force -ErrorAction SilentlyContinue
