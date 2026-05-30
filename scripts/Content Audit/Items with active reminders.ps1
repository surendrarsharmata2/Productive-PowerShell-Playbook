<#
    .SYNOPSIS
        Lists the set reminders of all content elements.

    .NOTES
        Manuel Fischer
        
    .LINK
        https://gist.github.com/hombreDelPez/bee378203b82f12213460c9440c4e395
#>

filter IsReminderSet {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Sitecore.Data.Items.Item]$Item
    )
    $reminderDate = [Sitecore.DateUtil]::IsoDateToDateTime($Item.Fields[[Sitecore.FieldIDs]::ReminderDate].Value)
    $reminderRecipients = $Item.Fields[[Sitecore.FieldIDs]::ReminderRecipients].Value
    $reminderText = $Item.Fields[[Sitecore.FieldIDs]::ReminderText].Value
    
    $datebool = $true
    $recipientsBool = $true
    $textBool = $true
    
    if ($reminderDate.ToString() -eq [datetime]::MinValue.ToString()) {
        $datebool = $false
    }
    
    if ($reminderRecipients.Length -eq 0) {
        $recipientsBool = $false
    }
    
    if ($reminderText.Length -eq 0) {
        $textBool = $false
    }
    
    if ($datebool -Or $recipientsBool -Or $textBool) {
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

$items = @($root) + @(($root.Axes.GetDescendants())) | IsReminderSet | Initialize-Item

if($items.Count -eq 0){
    Show-Alert "There are no items matching the specified criteria."
} else {
    $props = @{
        Title = "Items with active reminders"
        InfoTitle = "Items with active reminders"
        InfoDescription = "Reminder Date shown in $([System.TimeZone]::CurrentTimeZone.StandardName)."
        PageSize = 25
    }
    
    $items |
        Show-ListView @props -Property @{Label="Item Name"; Expression={$_.DisplayName} },
            @{Label="Item Path"; Expression={$_.ItemPath} },
            @{Label="Reminder Date"; Expression={ [Sitecore.DateUtil]::ToServerTime($_."__Reminder date")} },
            @{Label="Reminder Recipients"; Expression={$_."__Reminder recipients"} },
            @{Label="Reminder Text"; Expression={$_."__Reminder text"} }
}

Close-Window
