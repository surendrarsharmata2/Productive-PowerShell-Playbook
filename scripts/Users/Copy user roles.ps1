<#
    .SYNOPSIS
        Copy roles from one user to another.
        
    .NOTES
        Gabe Streza
        https://www.sitecoregabe.com/2022/09/copy-sitecore-user-roles-from-one-user-to-another.html
        
        Michael West
#>

$icon = $PSScript.Appearance.Icon -replace "16x16","32x32" -replace "Office", "OfficeWhite"
$settings = @{
    Title = "Report Filter"
    Height = "325"
    OkButtonName = "Proceed"
    CancelButtonName = "Abort"
    Description = "Copy roles from one user to another. Useful when new members join the team."
    Parameters = @(
        @{ Name = "userSource"; Title="Source User"; Tooltip="Specify the user with membership to the desired roles."; Editor="user"; Validator={
            if([string]::IsNullOrEmpty($variable.Value)){
                $variable.Error = "Please specify a username."
            }
        }},
        @{ Name = "userTarget"; Title="Target User"; Tooltip="Specify the user to receive the updated roles."; Editor="user multiple"; Validator={
            if([string]::IsNullOrEmpty($variable.Value)){
                $variable.Error = "Please specify a user."
            }
        }},
        @{ Name = "isTestMode"; Title = "Run Test"; Value = $true; }
    )
    Icon = $icon
    ShowHints = $true
}

$result = Read-Variable @settings
if($result -ne "ok") {
    Exit
}

$user = Get-User -Id ($userSource | Select-Object -First 1)
Write-Host "Copying roles from $($user.Name) to the target account(s)."
foreach ($role in $user.Roles.Name) {
	Write-Host " - Updating '$($role)' with members '$($userTarget)'" -ForegroundColor Green
	Add-RoleMember -Identity $Role -Members $userTarget -WhatIf:$isTestMode
}

Show-Result -Text

Close-Window
