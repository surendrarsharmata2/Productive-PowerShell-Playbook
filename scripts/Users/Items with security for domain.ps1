<#
    .SYNOPSIS
        Find all items referencing the specified domain.
        
    .DESCRIPTION
        This report helps identify all of the items with explicit security set for a given domain.
        
    .NOTES
        Michael West
#>

Import-Function -Name Invoke-SqlCommand

$domainOptions = Get-Domain | ForEach-Object { $options = [ordered]@{} } { $options[$_.Name]=$_.Name } { $options }
$settings = @{
    Title = "Report Filter"
    OkButtonName = "Proceed"
    CancelButtonName = "Abort"
    Description = "Filter items explicitly referencing the specified domain."
    Parameters = @(
        @{
            Name="selectedDomain";
            Options=$domainOptions
            Title="Choose a domain for the report"; 
            Tooltip="Only items matching security with this domain will be returned."; 
        }
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
	AND [Value] <> '' AND [Value] LIKE '%|$($selectedDomain)%'
"@
$records = Invoke-SqlCommand -Connection $connection -Query $query

$reportProperties = @{
    Property = @("Name", "Id", "ItemPath", @{Name="Security";Expression={$_."__Security"}})
    Title = "Items assigned with explicit domain security"
    InfoTitle = "Items assigned with explicit domain security"
    InfoDescription = "Items which reference the domain '$($selectedDomain)'."
}
$records | Where-Object { $_.Value -match "$($selectedDomain)\\" } |
    ForEach-Object { Get-Item -Path "master:" -ID "$($_.ItemId.ToString())" } |
    Show-ListView @reportProperties

Close-Window    
