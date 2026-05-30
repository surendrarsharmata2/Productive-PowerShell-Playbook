<#
    .SYNOPSIS
        Lists all the items locked by the specified user.
    .NOTES
        Adam Najmanowicz, Michael West
#>
Import-Function -Name Invoke-SqlCommand
filter Where-LockedOnDate {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Sitecore.Data.Items.Item]$Item,
        [datetime]$Date=([datetime]::Today),
        [switch]$IsBefore,
        [int]$MaxDays
    )
    $convertedDate = [Sitecore.DateUtil]::ToServerTime(([Sitecore.Data.Fields.LockField]($item.Fields[[Sitecore.FieldIDs]::Lock])).Date)
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
filter Where-InactiveGreaterThan {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Sitecore.Data.Items.Item]$Item,
        [int]$MinDays
    )
    if($MinDays -gt 0) {
        if([math]::Round(([datetime]::UtcNow - $item.__Updated).TotalDays) -ge $MinDays) {
            $item
        }
    } else {
        $item
    }
}
$item = Get-Item -Path "master:\content\"
$user = ""
$periodOptions = [ordered]@{Before=1;After=2;}
$maxDaysOptions = [ordered]@{"-- Skip --"=[int]::MaxValue;30=30;90=90;120=120;365=365;}
$minInactiveDaysOptions = [ordered]@{"-- Skip --"=0;14=14;30=30;60=60;90=90;120=120;365=365;}
$dialogProps = @{
    Title = "Items Locked"
    Description = "Lists all the items locked by the specified user."
    OkButtonName = "Proceed"
    CancelButtonName = "Abort"
    Width = 600
    Parameters = @(
        @{ Name = "info"; Title="Details"; Tooltip="Analyse the branch and report which items are currently locked. Optionally filter by user."; Editor="info";},
        @{ Name = "item"; Title="Root Item"; Tooltip="Branch you want to analyse."},
        @{ Name = "user"; Title="Locking User"; Tooltip="Specify the user associated with the locked items."; Editor="user"},
        @{ 
            Name = "selectedDate"
            Value = [System.DateTime]::Now
            Title = "Locked Date"
            Tooltip = "Filter the results for items locked on or before/after the specified date"
            Editor = "date time"
        },
        @{
            Name = "selectedPeriod"
            Title = "Period"
            Value = 1
            Options = $periodOptions
            Tooltip = "Pick whether the items should have been locked before or after the specified date"
            Editor = "radio"
        },
        @{
            Name = "selectedMaxDays"
            Title = "Maximum Days Locked"
            Value = [int]::MaxValue
            Options = $maxDaysOptions
            Tooltip = "Pick the maximum number of days to include starting with the specified date."
            Editor = "combo"
        },
        @{
            Name = "selectedMinimumInactiveDays"
            Title = "Minimum Inactive Days"
            Value = [int]::MaxValue
            Options = $minInactiveDaysOptions
            Tooltip = "Pick the minimum number of inactive days to include starting with the specified date."
            Editor = "combo"
        }
    )
    Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    ShowHints = $true
}
$result = Read-Variable @dialogProps
if($result -ne "ok") {
    Close-Window
    Exit
}
$connection = [Sitecore.Configuration.Settings]::GetConnectionString("master")
$query = @"
SELECT [ItemId], [Value], [Language], [Version]
  FROM [dbo].[VersionedFields]
  WHERE [FieldId] = '$([Sitecore.FieldIDs]::Lock.ToString())'
	AND [Value] <> '' AND [Value] <> '<r />'
"@
if($user) {
    $query += "	AND [Value] LIKE '<r owner=`"$($user)`"%'"
}
$records = Invoke-SqlCommand -Connection $connection -Query $query
$items = $records | ForEach-Object { Get-Item -Path "master:" -ID $_.ItemId -Language $_.Language -Version $_.Version } | 
    Where-LockedOnDate -Date $selectedDate -IsBefore:($selectedPeriod -eq 1) -MaxDays $selectedMaxDays |
    Where-InactiveGreaterThan -MinDays $selectedMinimumInactiveDays
if($items.Count -eq 0) {
    Show-Alert "There are no items items locked by the specified user."
} else {
    $reportProps = @{
        Title = "Locked Items Report"
        InfoTitle = "Items Locked"
        InfoDescription = 'Lists all the items locked by the specified user.'
        PageSize = 25
        ViewName = "LockedItems"
    }
    function Get-FormattedDate {
        param(
            [datetime]$Date
        )
        if($Date -ge [datetime]::MinValue) {
            $Date
        }
    }
    $items |
        Show-ListView @reportProps -Property @{Label="Name"; Expression={$_.DisplayName} },
            @{Label="Version"; Expression={$_.Version } },
            @{Label="Language"; Expression={$_.Language } },
            @{Label="Locked by"; Expression={$_.Locking.GetOwner() } },
            @{Label="Locked on"; Expression={ Get-FormattedDate -Date ([Sitecore.Data.Fields.LockField]($_.Fields[[Sitecore.FieldIDs]::Lock])).Date} },
            @{Label="Inactive days"; Expression={[math]::Round(([datetime]::UtcNow - $_.__Updated).TotalDays)}},
            @{Label="Path"; Expression={$_.ItemPath} },
            ID,
            @{Label="Updated"; Expression={$_.__Updated} },
            @{Label="Updated by"; Expression={$_."__Updated by"} },
            @{Label="Created"; Expression={$_.__Created} },
            @{Label="Created by"; Expression={$_."__Created by"} },
            @{Label="Owner"; Expression={ $_.__Owner} }
}
Close-Window
