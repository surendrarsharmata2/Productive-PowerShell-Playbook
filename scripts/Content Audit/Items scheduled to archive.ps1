<#
    .SYNOPSIS
        Lists the items scheduled to archive.

    .NOTES
        Michael West
#>

filter IsScheduleSet {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Sitecore.Data.Items.Item]$Item
    )
    $archiveDate = [Sitecore.DateUtil]::IsoDateToDateTime($Item.Fields[[Sitecore.FieldIDs]::ArchiveDate].Value)

    if ($archiveDate.Year -ne 1) {
        $Item
    }
}

$database = "master"
$root = Get-Item -Path (@{$true="$($database):\content\home"; $false="$($database):\content"}[(Test-Path -Path "$($database):\content\home")])

$settings = @{
    Title = "Report Filter"
    OkButtonName = "Proceed"
    CancelButtonName = "Abort"
    Description = "Filter the results for items with a reminder set"
    Parameters = @(
        @{
            Name="root"; 
            Title="Choose the report root"; 
            Tooltip="Only items from this root will be returned.";
        }
    )
    Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    ShowHints = $true
}

$result = Read-Variable @settings
if($result -ne "ok") {
    Exit
}

$items = @($root) + @(($root.Axes.GetDescendants())) | IsScheduleSet | Initialize-Item

if($items.Count -eq 0){
    Show-Alert "There are no items matching the specified criteria."
} else {
    $props = @{
        Title = "Items scheduled to archive"
        InfoTitle = "Items scheduled to archive"
        InfoDescription = "Archive Date shown in $([System.TimeZone]::CurrentTimeZone.StandardName)."
        PageSize = 25
    }
    
    $items |
        Show-ListView @props -Property @{Label="Item Name"; Expression={$_.DisplayName} },
            @{Label="Item Path"; Expression={$_.ItemPath} },
            @{Label="Archive Date"; Expression={ [Sitecore.DateUtil]::ToServerTime([Sitecore.DateUtil]::IsoDateToDateTime($_.Fields[[Sitecore.FieldIDs]::ArchiveDate].Value))} }
}

Close-Window
