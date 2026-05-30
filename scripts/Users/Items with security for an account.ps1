<#
    .SYNOPSIS
        Find all items referencing the specified account.
        
    .DESCRIPTION
        This report helps identify all of the items with explicit security set for a given account.
        
    .NOTES
        Michael West
#>

Import-Function -Name Invoke-SqlCommand

$settings = @{
    Title = "Report Filter"
    OkButtonName = "Proceed"
    CancelButtonName = "Abort"
    Description = "Filter items explicitly referencing the specified domain."
    Parameters = @(
        @{ Name = "selectedAccount"; Title="Choose an account for the report"; Tooltip="Only items matching security with this account will be returned."; Editor="user role"}
    )
    Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
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
	AND [Value] <> '' AND [Value] LIKE '%|$($selectedAccount)%'
"@
$records = Invoke-SqlCommand -Connection $connection -Query $query

$reportProperties = @{
    Property = @("Name", "Id", "ItemPath", @{Name="Security";Expression={$_."__Security"}})
    Title = "Items assigned with explicit account security"
    InfoTitle = "Items assigned with explicit account security"
    InfoDescription = "Items which reference the domain '$($selectedAccount)'."
    ViewName = "ExplicitItemSecurity"
}

$escaped = [regex]::Escape($selectedAccount)
$records | Where-Object { $_.Value -match "$($escaped)" } |
    ForEach-Object { Get-Item -Path "master:" -ID "$($_.ItemId.ToString())" } |
    Show-ListView @reportProperties

Close-Window    
