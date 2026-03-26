$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$appRoot = Split-Path -Parent $PSScriptRoot
$benchmarksDir = Join-Path $appRoot 'test\features\home\benchmarks'
$goldensDir = Join-Path $appRoot 'test\features\home\goldens'
$proofsDir = Join-Path $appRoot 'test\features\home\proofs'

New-Item -ItemType Directory -Force $proofsDir | Out-Null

$proofs = @(
  @{
    Title = 'NORMAL FOUR-PLAYER TABLE'
    Benchmark = 'life_counter_benchmark_normal_4p.png'
    Current = 'life_counter_clone_current_normal_4p.png'
    Output = 'life_counter_clone_proof_normal_4p.png'
  },
  @{
    Title = 'HUB OPEN WITH BOTTOM RAIL'
    Benchmark = 'life_counter_benchmark_hub_open.png'
    Current = 'life_counter_clone_current_hub_open.png'
    Output = 'life_counter_clone_proof_hub_open.png'
  },
  @{
    Title = 'SETTINGS OVERLAY'
    Benchmark = 'life_counter_benchmark_settings.png'
    Current = 'life_counter_clone_current_settings.png'
    Output = 'life_counter_clone_proof_settings.png'
  },
  @{
    Title = 'SET LIFE OVERLAY'
    Benchmark = 'life_counter_benchmark_set_life.png'
    Current = 'life_counter_clone_current_set_life.png'
    Output = 'life_counter_clone_proof_set_life.png'
  },
  @{
    Title = 'HIGH ROLL TAKEOVER'
    Benchmark = 'life_counter_benchmark_high_roll.png'
    Current = 'life_counter_clone_current_high_roll.png'
    Output = 'life_counter_clone_proof_high_roll.png'
  }
)

$background = [System.Drawing.Color]::FromArgb(5, 5, 5)
$textPrimary = [System.Drawing.Color]::FromArgb(245, 245, 245)
$textSecondary = [System.Drawing.Color]::FromArgb(176, 176, 176)
$stroke = [System.Drawing.Color]::FromArgb(28, 28, 28)

$titleFont = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold)
$labelFont = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)

try {
  foreach ($proof in $proofs) {
    $benchmarkPath = Join-Path $benchmarksDir $proof.Benchmark
    $currentPath = Join-Path $goldensDir $proof.Current
    $outputPath = Join-Path $proofsDir $proof.Output

    if (-not (Test-Path $benchmarkPath)) {
      throw "Benchmark image not found: $benchmarkPath"
    }
    if (-not (Test-Path $currentPath)) {
      throw "Current golden not found: $currentPath"
    }

    $benchmark = [System.Drawing.Bitmap]::FromFile($benchmarkPath)
    $current = [System.Drawing.Bitmap]::FromFile($currentPath)

    try {
      $canvasWidth = $benchmark.Width + $current.Width + 96
      $canvasHeight = [Math]::Max($benchmark.Height, $current.Height) + 124
      $canvas = New-Object System.Drawing.Bitmap $canvasWidth, $canvasHeight
      $graphics = [System.Drawing.Graphics]::FromImage($canvas)

      try {
        $graphics.Clear($background)
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

        $titleBrush = New-Object System.Drawing.SolidBrush($textPrimary)
        $labelBrush = New-Object System.Drawing.SolidBrush($textSecondary)
        $strokePen = New-Object System.Drawing.Pen($stroke, 1)

        try {
          $graphics.DrawString($proof.Title, $titleFont, $titleBrush, 32, 20)
          $graphics.DrawString('BENCHMARK', $labelFont, $labelBrush, 32, 56)
          $graphics.DrawString('CURRENT BUILD', $labelFont, $labelBrush, ($benchmark.Width + 64), 56)

          $graphics.DrawRectangle($strokePen, 31, 79, ($benchmark.Width + 1), ($benchmark.Height + 1))
          $graphics.DrawRectangle($strokePen, ($benchmark.Width + 63), 79, ($current.Width + 1), ($current.Height + 1))

          $graphics.DrawImage($benchmark, 32, 80, $benchmark.Width, $benchmark.Height)
          $graphics.DrawImage($current, ($benchmark.Width + 64), 80, $current.Width, $current.Height)
        }
        finally {
          $titleBrush.Dispose()
          $labelBrush.Dispose()
          $strokePen.Dispose()
        }

        $canvas.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
      }
      finally {
        $graphics.Dispose()
        $canvas.Dispose()
      }
    }
    finally {
      $benchmark.Dispose()
      $current.Dispose()
    }
  }
}
finally {
  $titleFont.Dispose()
  $labelFont.Dispose()
}
