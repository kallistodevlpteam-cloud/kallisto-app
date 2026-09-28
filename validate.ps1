param([switch]$SkipPubGet)
$ErrorActionPreference = 'Stop'
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
$flutterExecutable = if ($flutterCommand) { $flutterCommand.Source } else { Join-Path $env:USERPROFILE 'develop\flutter\bin\flutter.bat' }
if (-not (Test-Path -LiteralPath $flutterExecutable)) { throw 'Flutter SDK not found.' }
$dartExecutable = Join-Path (Split-Path $flutterExecutable) 'dart.bat'
Push-Location $PSScriptRoot
try {
  if (-not $SkipPubGet) {
    & $flutterExecutable pub get
    if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed.' }
  }
  & $dartExecutable format --output=none --set-exit-if-changed lib test
  if ($LASTEXITCODE -ne 0) { throw 'Formatting check failed.' }
  & $flutterExecutable analyze --no-pub
  if ($LASTEXITCODE -ne 0) { throw 'Static analysis failed.' }
  & $flutterExecutable test --no-pub
  if ($LASTEXITCODE -ne 0) { throw 'Widget tests failed.' }
  $buildArguments = @('build', 'web', '--release', '--no-web-resources-cdn', '--no-pub')
  if (Test-Path -LiteralPath '.env') { $buildArguments += '--dart-define-from-file=.env' }
  & $flutterExecutable @buildArguments
  if ($LASTEXITCODE -ne 0) { throw 'Web release build failed.' }
} finally {
  Pop-Location
}
