Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile((Resolve-Path 'assets\images\pixel_residents\doctors.png'))
Write-Host "$($img.Width)x$($img.Height)"
$img.Dispose()
