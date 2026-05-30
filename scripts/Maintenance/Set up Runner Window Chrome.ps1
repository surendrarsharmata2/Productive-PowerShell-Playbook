<#
    .SYNOPSIS
        Script is part of the set that adapts SPE to run on the version of Sitecorethat it is deployed to.
        The script test up proper Script Runner Window Chrome.
        
    .NOTES
        Adam Najmanowicz
#>

if([CurrentSitecoreVersion]::IsAtLeast([SitecoreVersion]::V80)){
    (Get-Item "core:\content\Applications\PowerShell\PowerShell Runner").Chrome = "WindowHeaderlessChrome"

} else {
    (Get-Item "core:\content\Applications\PowerShell\PowerShell Runner").Chrome = "WindowChrome"    
}

