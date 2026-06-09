$distBase = Join-Path $env:USERPROFILE ".gradle\wrapper\dists"
Write-Output "distBase=$distBase"
# Remove specific partial gradle dirs
$patterns = @('gradle-7.6.3-all*','gradle-7.5.1-all*')
foreach ($p in $patterns) {
  Get-ChildItem -Path (Join-Path $distBase $p) -Force -ErrorAction SilentlyContinue | ForEach-Object {
    Try { Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop; Write-Output "Removed: $($_.FullName)" } Catch { Write-Output "RemoveFailed: $($_.FullName) - $_" }
  }
}

# Remove any .lck files under dists
Get-ChildItem -Path $distBase -Filter "*.lck" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
  Try { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop; Write-Output "Removed lock: $($_.FullName)" } Catch { Write-Output "RemoveLockFailed: $($_.FullName) - $_" }
}

# Kill java and gradle processes
Get-Process -Name java,gradle -ErrorAction SilentlyContinue | ForEach-Object {
  Try { Stop-Process -Id $_.Id -Force -ErrorAction Stop; Write-Output "Killed: $($_.Id) $($_.ProcessName)" } Catch { Write-Output "KillFailed: $($_.Id) - $_" }
}

# Remove build log if held
$log = 'D:\qoran\privoo\build_full.log'
if (Test-Path $log) {
  Try { Remove-Item -LiteralPath $log -Force -ErrorAction Stop; Write-Output "Removed log: $log" } Catch { Write-Output "RemoveLogFailed: $log - $_" }
}

Write-Output 'CLEANUP_DONE'