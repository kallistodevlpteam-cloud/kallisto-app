param(
  [ValidateSet('emulators','api','web','tests')]
  [string]$Part = 'web',
  [string]$JavaHome = ''
)
$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
  if ($Part -eq 'emulators') {
    if ($JavaHome) { $env:JAVA_HOME = $JavaHome }
    if (-not $env:JAVA_HOME) {
      $localJdk = Join-Path $env:USERPROFILE 'develop\kallisto-jdk\jdk-21.0.12.1+1'
      if (Test-Path -LiteralPath (Join-Path $localJdk 'bin\java.exe')) { $env:JAVA_HOME = $localJdk }
    }
    if ($env:JAVA_HOME) { $env:PATH = "$(Join-Path $env:JAVA_HOME 'bin');$env:PATH" }
    $env:CI = 'true'
    Set-Location backend
    & .\node_modules\.bin\firebase.cmd emulators:start --project demo-kallisto --only 'auth,firestore' --config firebase.emulators.json
  } elseif ($Part -eq 'api') {
    Set-Location backend
    & .\node_modules\.bin\tsx.cmd src/dev/emulator-server.ts
  } elseif ($Part -eq 'tests') {
    Set-Location backend
    $env:RUN_FIREBASE_EMULATOR_TESTS = 'true'
    npm test
  } else {
    $flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
    $flutterExecutable = if ($flutterCommand) { $flutterCommand.Source } else { Join-Path $env:USERPROFILE 'develop\flutter\bin\flutter.bat' }
    # Debug is deliberate: FlutterFire restores emulator configuration before Auth init only in debug builds.
    & $flutterExecutable build web --debug --no-pub --dart-define=KALLISTO_EMULATORS=true --dart-define=BACKEND_URL=http://127.0.0.1:4000 --dart-define=FIREBASE_API_KEY=local-emulator-key --dart-define=FIREBASE_AUTH_DOMAIN=demo-kallisto.firebaseapp.com --dart-define=FIREBASE_PROJECT_ID=demo-kallisto --dart-define=FIREBASE_APP_ID=1:123456789:web:abcdef1234 --dart-define=FIREBASE_MESSAGING_SENDER_ID=123456789
    if ($LASTEXITCODE -ne 0) { throw 'Local test web build failed.' }
    python -m http.server 8080 --bind 127.0.0.1 --directory build/web
  }
  if ($LASTEXITCODE -ne 0) { throw 'Local test command failed. Check the reported error.' }
} finally { Pop-Location }
