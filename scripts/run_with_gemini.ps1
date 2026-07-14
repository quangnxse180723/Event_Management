$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root '.env.local'

if (-not (Test-Path -LiteralPath $envFile)) {
  throw "Missing .env.local. Copy .env.example to .env.local and set GEMINI_API_KEY."
}

$values = @{}
Get-Content -LiteralPath $envFile | ForEach-Object {
  $line = $_.Trim()
  if ($line.Length -eq 0 -or $line.StartsWith('#')) {
    return
  }

  $parts = $line.Split('=', 2)
  if ($parts.Length -eq 2) {
    $values[$parts[0].Trim()] = $parts[1].Trim()
  }
}

if (-not $values.ContainsKey('GEMINI_API_KEY') -or [string]::IsNullOrWhiteSpace($values['GEMINI_API_KEY'])) {
  throw "Missing GEMINI_API_KEY in .env.local."
}

$model = if ($values.ContainsKey('GEMINI_MODEL') -and -not [string]::IsNullOrWhiteSpace($values['GEMINI_MODEL'])) {
  $values['GEMINI_MODEL']
} else {
  'gemini-3.1-flash-lite'
}

$flutterArgs = @(
  'run',
  "--dart-define=GEMINI_API_KEY=$($values['GEMINI_API_KEY'])",
  "--dart-define=GEMINI_MODEL=$model"
)

if ($values.ContainsKey('OCR_SPACE_API_KEY') -and -not [string]::IsNullOrWhiteSpace($values['OCR_SPACE_API_KEY'])) {
  $flutterArgs += "--dart-define=OCR_SPACE_API_KEY=$($values['OCR_SPACE_API_KEY'])"
}

& flutter @flutterArgs
