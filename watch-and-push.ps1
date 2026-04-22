$path = "C:\Users\Jeppe\OneDrive\Skrivebord\Cars"
$debounceSeconds = 8

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $path
$watcher.IncludeSubdirectories = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::FileName
$watcher.EnableRaisingEvents = $true

$global:lastChange = [DateTime]::MinValue

$action = {
    # Ignorer .git-mappen
    if ($Event.SourceEventArgs.FullPath -notmatch '\\.git\\') {
        $global:lastChange = [DateTime]::Now
    }
}

Register-ObjectEvent $watcher "Changed" -Action $action | Out-Null
Register-ObjectEvent $watcher "Created" -Action $action | Out-Null
Register-ObjectEvent $watcher "Deleted" -Action $action | Out-Null
Register-ObjectEvent $watcher "Renamed" -Action $action | Out-Null

Write-Host "Cars-watcher korer - gemmer til GitHub automatisk. Tryk Ctrl+C for at stoppe." -ForegroundColor Green

while ($true) {
    Start-Sleep -Seconds 2

    if ($global:lastChange -ne [DateTime]::MinValue) {
        $elapsed = ([DateTime]::Now - $global:lastChange).TotalSeconds

        if ($elapsed -ge $debounceSeconds) {
            $global:lastChange = [DateTime]::MinValue

            Set-Location $path
            git add . | Out-Null
            $status = git status --short

            if ($status) {
                $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
                git commit -m "Auto-save $timestamp" | Out-Null
                $result = git push origin main 2>&1

                if ($LASTEXITCODE -eq 0) {
                    Write-Host "$(Get-Date -Format 'HH:mm:ss') Pushed til GitHub" -ForegroundColor Cyan
                } else {
                    Write-Host "$(Get-Date -Format 'HH:mm:ss') Push fejlede: $result" -ForegroundColor Red
                }
            }
        }
    }
}
