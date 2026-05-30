<#
    .SYNOPSIS
        Lists all items last updated before/after than the date selected.
    
    .NOTES
        Michael West, Alex Washtell
#>

$database = "master"
$root = Get-Item -Path (@{$true="$($database):\content\home"; $false="$($database):\content"}[(Test-Path -Path "$($database):\content\home")])
$periodOptions = [ordered]@{Before=1;After=2;}
$maxDaysOptions = [ordered]@{"-- Skip --"=[int]::MaxValue;30=30;90=90;120=120;365=365;}
$settings = @{
    Title = "Report Filter"
    OkButtonName = "Proceed"
    CancelButtonName = "Abort"
    Description = "Filter the results for items updated on or after the specified date"
    Parameters = @(
        @{
            Name="root"; 
            Title="Choose the report root"; 
            Tooltip="Only items from this root will be returned.";
        },
        @{ 
            Name = "selectedDate"
            Value = [System.DateTime]::Now
            Title = "Date"
            Tooltip = "Filter the results for items updated on or before/after the specified date"
            Editor = "date time"
        },
        @{
            Name = "selectedPeriod"
            Title = "Period"
            Value = 1
            Options = $periodOptions
            Tooltip = "Pick whether the items should have been last updated before or after the specified date"
            Editor = "radio"
        },
        @{
            Name = "selectedMaxDays"
            Title = "Max Days"
            Value = [int]::MaxValue
            Options = $maxDaysOptions
            Tooltip = "Pick the maximum number of days to include starting with the specified date"
            Editor = "combo"
        }
    )
    Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    ShowHint = $true
}

$result = Read-Variable @settings
if($result -ne "ok") {
    Exit
}

filter Where-LastUpdated {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Sitecore.Data.Items.Item]$Item,
        
        [datetime]$Date=([datetime]::Today),
        [switch]$IsBefore,
        
        [int]$MaxDays
    )
    
    $convertedDate = [Sitecore.DateUtil]::IsoDateToDateTime($item.Fields[[Sitecore.FieldIDs]::Updated].Value)
    $isWithinDate = $false
    if($IsBefore.IsPresent) {
        if($convertedDate -le $Date) {
            $isWithinDate = $true
        }
    } else {
        if($convertedDate -ge $Date) {
            $isWithinDate = $true
        }
    }
    
    if($isWithinDate) {
        if($MaxDays -lt [int]::MaxValue) {
            if([math]::Abs(($convertedDate - $Date).Days) -le $MaxDays) {
                $item
            }
        } else {
            $item
        }
    }
}

$items = @($root) + @(($root.Axes.GetDescendants())) | Where-LastUpdated -Date $selectedDate -IsBefore:($selectedPeriod -eq 1) -MaxDays $selectedMaxDays | Initialize-Item

$message = "before"
if($selectedPeriod -ne 1) {
    $message = "after"
}

if($items.Count -eq 0) {
    Show-Alert "There are no items updated on or after the specified date"
} else {
    $props = @{
        Title = "Items Last Updated Report"
        InfoTitle = "Items last updated $($message) date"
        InfoDescription = "Lists all items last updated $($message) the date selected."
        PageSize = 25
    }
    
    $items |
        Show-ListView @props -Property @{Label="Name"; Expression={$_.DisplayName} },
            @{Label="Updated"; Expression={$_.__Updated} },
            @{Label="Updated by"; Expression={$_."__Updated by"} },
            @{Label="Created"; Expression={$_.__Created} },
            @{Label="Created by"; Expression={$_."__Created by"} },
            @{Label="Path"; Expression={$_.ItemPath} }
}
Close-Window
