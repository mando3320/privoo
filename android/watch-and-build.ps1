$zip = Join-Path $env:USERPROFILE ".gradle\wrapper\dists\gradle-7.5.1-all\1ehga6e77gqps5uk2kc5kf1vc\gradle-7.5.1-all.zip"
$lck = "$zip.lck"
Set-Location -LiteralPath $PSScriptRoot
Write-Output "[watch] started at $(Get-Date -Format o) (watching $zip)"
while (Test-Path $lck) {
    if (Test-Path $zip) {
        $s = (Get-Item $zip).Length
        Write-Output ("[watch] {0} - {1:N2} MB downloaded" -f (Get-Date -Format o), ($s/1MB))
    } else {
        Write-Output ("[watch] {0} - zip missing" -f (Get-Date -Format o))
    }
    Start-Sleep -Seconds 10
}
Write-Output "[watch] lock removed — starting assembleRelease"
& .\gradlew assembleRelease --stacktrace --info | Tee-Object -FilePath '..\build_full.log' 
