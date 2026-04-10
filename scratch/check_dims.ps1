Add-Type -AssemblyName System.Drawing
$files = @(
  'assets\images\pixel_residents\admin_001.png',
  'assets\images\pixel_residents\resident_004.png',
  'assets\images\pixel_residents\resident_009.png'
)
foreach ($f in $files) {
  $img = [System.Drawing.Image]::FromFile((Resolve-Path $f))
  Write-Host "$f : $($img.Width)x$($img.Height)"
  $img.Dispose()
}
