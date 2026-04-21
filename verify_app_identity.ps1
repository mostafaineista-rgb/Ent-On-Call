param(
    [string]$ExpectedAppName,
    [string]$ExpectedProjectId
)

# Get app name from pubspec.yaml
$pubspecPath = "pubspec.yaml"
if (-not (Test-Path $pubspecPath)) {
    Write-Error "pubspec.yaml not found!"
    exit 1
}

$content = Get-Content $pubspecPath -Raw
$appName = ($content | Select-String -Pattern "name: ([a-z_]+)" | ForEach-Object { $_.Matches[0].Groups[1].Value })

# Get Firebase project from environment variable (optional, might be empty in some shells)
$firebaseProject = $env:FIREBASE_PROJECT

Write-Host "Verifying App Identity: $appName (Expected: $ExpectedAppName)"
if ($firebaseProject) {
    Write-Host "Targeting Firebase Project: $firebaseProject (Expected: $ExpectedProjectId)"
} else {
    Write-Host "Targeting Firebase Project: [Unknown/Not Set]"
}

if ($appName -ne $ExpectedAppName) {
    Write-Error "CRITICAL ERROR: App name mismatch! Attempting to deploy '$appName' instead of '$ExpectedAppName'."
    exit 1
}

if ($firebaseProject -and ($firebaseProject -ne $ExpectedProjectId)) {
    Write-Error "CRITICAL ERROR: Project mismatch! Attempting to deploy to '$firebaseProject' instead of '$ExpectedProjectId'."
    exit 1
}

Write-Host "✅ Identity Verified. Proceeding with deployment."
exit 0
