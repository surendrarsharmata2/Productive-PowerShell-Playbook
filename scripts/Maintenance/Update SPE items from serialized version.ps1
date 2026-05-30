Write-Host "Updating master database" -ForegroundColor Green
Import-Item -Database (Get-Database master)
Write-Host "Updating core database" -ForegroundColor Green
Import-Item -Database (Get-Database core)
Write-Host "Setting up Runner Window Chrome" -ForegroundColor Green
Invoke-Script -Path "master:\system\Modules\PowerShell\Script Library\Platform\Development\PowerShell Extensions Maintenance\Set up Runner Window Chrome"
Write-Host "Recovering Version Specific Icons" -ForegroundColor Green
Invoke-Script -Path "master:\system\Modules\PowerShell\Script Library\Platform\Development\PowerShell Extensions Maintenance\Recover Version Specific Icons"
Write-Host "Recovering Version 7.0 rules if needed" -ForegroundColor Green
Invoke-Script -Path "master:\system\Modules\PowerShell\Script Library\Platform\Development\PowerShell Extensions Maintenance\Restore Rules on Sitecore 7dot0"

