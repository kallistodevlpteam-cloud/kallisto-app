param(
  [ValidateSet('chrome', 'edge', 'web-server', 'windows')]
  [string]$Device = 'chrome',
  [switch]$SkipPubGet
)
$ErrorActionPreference = 'Stop'
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
$flutterExecutable = if ($flutterCommand) { $flutterCommand.Source } else { Join-Path $env:USERPROFILE 'develop\flutter\bin\flutter.bat' }
if (-not (Test-Path -LiteralPath $flutterExecutable)) {
  throw 'Flutter was not found. Install Flutter and add its bin folder to PATH.'
}
Push-Location $PSScriptRoot
try {
  if (-not $SkipPubGet) {
    & $flutterExecutable pub get
    if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed.' }
  }
  $runArguments = @('run', '-d', $Device, '--no-pub')
  if (Test-Path -LiteralPath '.env') { $runArguments += '--dart-define-from-file=.env' }
  if ($Device -ne 'windows') { $runArguments += @('--web-hostname=localhost', '--web-port=5000') }
  & $flutterExecutable @runArguments
  if ($LASTEXITCODE -ne 0) { throw 'Flutter could not launch. Check flutter doctor -v.' }
} finally {
  Pop-Location
}
