# Get the item based on the current context
$item = Get-Item -Path .

$props = @{
    Parameters = @(
        @{
            Name = "from"
            Value = [System.DateTime]::Now.AddDays(-7)
            Title = "Changes from"
            Tooltip = "Since when you want the activity to be reported?"
            ShowTime=$true
        },
        @{
            Name = "to"
            Value = [System.DateTime]::Now
            Title = "Changes to"
            Tooltip = "Until when you want the activity to be reported?"
            ShowTime =$true
        },
        @{
            Name = "item"
            Title="Branch to Analyse"
            Tooltip="Narrow the results down to this item and its children."
        }
    )
    Title = "Analyse author activilty"
    Description = "This report will analyse the branch you select and will tell you which of the pages have been changed since your selected date/time"
    OkButtonName = "Proceed"
    CancelButtonName = "Abort"
    Width = 500
    Height = 300
    ShowHints = $true
    Icon = "OfficeWhite/32x32/user.png"
}

$result = Read-Variable @props

if($result -ne "ok") {
    Exit
}

$root = Get-Item -Path "."
@($root) + @(($root.Axes.GetDescendants() | Initialize-Item)) |
    Where-Object { $from.CompareTo($_.__Updated.ToLocalTime()) -lt 0 -and $to.CompareTo($_.__Updated.ToLocalTime()) -gt 0 } |
    Show-ListView -Property Name, ItemPath, @{Label="Updated by"; Expression={$_."__Updated By"} }, @{Label="Modified"; Expression={ $_.__Updated.ToLocalTime() } } -Title "Recent Author Activity"

Close-Window
