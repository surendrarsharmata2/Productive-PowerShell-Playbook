<#
    .SYNOPSIS
        Find all items with the specified user or role assigned.
        
    .DESCRIPTION
        This report helps identify all of the items with a specific user or role assigned and transfers to another role.
        
    .NOTES
        Michael West
#>

Import-Function -Name Invoke-SqlCommand

$scriptItem = Get-Item -Path $SitecoreCommandPath
$icon = $scriptItem.Appearance.Icon -replace "16x16","32x32" -replace "Office", "OfficeWhite"
$settings = @{
    Title = "Transfer item security"
    Height = "325"
    OkButtonName = "Proceed"
    CancelButtonName = "Abort"
    Description = "Transfer item security from the current user or role to a new role."
    Parameters = @(
        @{ Name = "userOrRoleOwner"; Title="Current User or Role"; Tooltip="Items with explicit security assigned matching this user or role."; Editor="user role"; Domain="sitecore"; Validator={
            if([string]::IsNullOrEmpty($variable.Value)){
                $variable.Error = "Please specify a username or role."
            }
        }},
        @{ Name = "roleNewOwner"; Title="New Role"; Tooltip="Items matching the current user or role will be assigned this role instead."; Editor="role"; Domain="sitecore"; Validator={
            if([string]::IsNullOrEmpty($variable.Value)){
                $variable.Error = "Please specify a role."
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

$connection = [Sitecore.Configuration.Settings]::GetConnectionString("master")

$securityFieldId = [Sitecore.FieldIDs]::Security

# Find all the items which explicitly hae security assigned.
$query = @"
SELECT [ItemId], [Value]
  FROM [dbo].[SharedFields]
  WHERE [FieldId] = '$($securityFieldId.ToString())'
	AND [Value] <> '' AND [Value] LIKE '%|$($userOrRoleOwner)%'
"@
$records = Invoke-SqlCommand -Connection $connection -Query $query

$reportProperties = @{
    Property = @("Name", "Id", "ItemPath", @{Name="Security";Expression={$_."__Security"}}, "Security-Original")
    Title = "Items with security reassigned"
    InfoTitle = "Items with security reassigned"
    InfoDescription = "Items with the account set to '$($userOrRoleOwner)' have been transferred to $($roleNewOwner)."
}

if($isTestMode) {
    $reportProperties["Title"] += " (Test Mode)"
}

$valueToMatch = [System.Text.RegularExpressions.Regex]::Escape($userOrRoleOwner)
$records | Where-Object { $_.Value -match $valueToMatch } |
    ForEach-Object { 
        $item = Get-Item -Path "master:" -ID "$($_.ItemId.ToString())"
        $item | Add-Member -Name "Security-Original" -Value $item."__Security" -MemberType NoteProperty
        if($isTestMode) {
            Write-Host "Replacing security on item $($item.ItemPath)"
        } else {
            $item."__Security" = $item."__Security".Replace("$userOrRoleOwner","$roleNewOwner")
        }
        $item
    } | Show-ListView @reportProperties

Close-Window    
