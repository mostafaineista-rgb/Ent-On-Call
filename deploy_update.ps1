# deploy_update.ps1 - Automation script for ENT-ON-CALL updates

Write-Host "`n--- ENT-ON-CALL Update Deployment ---" -ForegroundColor Cyan

# 1. Get User Inputs
$newVersion = Read-Host "Enter New Version Number (e.g., 1.2.0)"
$buildNumber = Read-Host "Enter Build Number (e.g., 4)"
$downloadUrl = Read-Host "Enter GitHub APK Download Link"
$releaseNotes = Read-Host "Enter Release Notes/Summary"

if (-not $newVersion -or -not $buildNumber -or -not $downloadUrl) {
    Write-Host "`nError: All fields are required." -ForegroundColor Red
    exit
}

# 2. Prepare JSON Content
$manifest = @{
    latest_version = $newVersion
    build_number   = [int]$buildNumber
    download_url   = $downloadUrl
    release_notes  = $releaseNotes
}
$jsonContent = $manifest | ConvertTo-Json

# 3. Update Local Files
$webPath = "web/version.json"
$buildPath = "build/web/version.json"

Write-Host "`nUpdating local manifest files..." -ForegroundColor Yellow

if (Test-Path $webPath) {
    $jsonContent | Set-Content $webPath
    Write-Host "[OK] Updated $webPath" -ForegroundColor Green
} else {
    Write-Host "[!] Warning: $webPath not found." -ForegroundColor Yellow
}

if (Test-Path $buildPath) {
    $jsonContent | Set-Content $buildPath
    Write-Host "[OK] Updated $buildPath" -ForegroundColor Green
} else {
    Write-Host "[!] Warning: $buildPath not found. Ensure build/web exists if you intend to deploy." -ForegroundColor Yellow
}

# 4. Deploy to Firebase
Write-Host "`nStarting Firebase Deployment..." -ForegroundColor Yellow
# Using cmd /c to bypass PowerShell script execution policies
cmd /c "firebase deploy --only hosting"

Write-Host "`nDone! Your update manifest is now live at https://ent-on-call.web.app/version.json" -ForegroundColor Cyan
