<#
    Based on Blog by @Techphoria414 - Nick Wesselman
    http://www.techphoria414.com/Blog/2012/March/Change-Item-Templates-With-Sitecore-PowerShell
#>

$database = "master"
$root = Get-Item -Path (@{$true="$($database):\content\home"; $false="$($database):\content"}[(Test-Path -Path "$($database):\content\home")])

$sourceTemplate = Get-Item 'master:\templates\Sample\Sample Item'
$targetTemplate = Get-Item 'master:\templates\Sample\Sample Item'

$dialogProps = @{
    Title = "Bulk Template Changer"
    Description = "This will change all items matching the source template with the new target template."
    OkButtonName = "Replace"
    CancelButtonName = "Cancel"
    Icon = "OfficeWhite/32x32/arrow_circle2.png"
    ShowHints = $true
    Parameters = @(
        @{ Name = "root"; Title="Branch to work on"; Root="/sitecore/"; Tooltip="Items you want to work on."},
        @{ Name = "sourceTemplate"; Title="Current template"; Root="/sitecore/templates/"; Tooltip="Template you want to replace."},
        @{ Name = "targetTemplate"; Title="New template"; Root="/sitecore/templates/"; Tooltip="Template you want to use."}
    )
}
$result = Read-Variable @dialogProps

if($result -ne "ok") {
    Exit
}

$path = $root.ProviderPath

$targetTemplateItem = New-Object -TypeName "Sitecore.Data.Items.TemplateItem" -ArgumentList $targetTemplate

$items = Get-ChildItem $path -Recurse | Where-Object { $_.TemplateID -eq $sourceTemplate.ID }
$items | Set-ItemTemplate -TemplateItem $targetTemplateItem

if($items.Count -eq 0) {
    Show-Alert "There are no items matching the specified criteria."
} else {
    $props = @{
        Title = "Bulk Template Changer Report"
        InfoTitle = "Results from changing templates"
        InfoDescription = "The following items were modified as part of the bulk change process from '$($sourceTemplate.Name)' to '$($targetTemplate.Name)'."
        PageSize = 25
        Property = @(
            @{Label="Name"; Expression={$_.DisplayName} },
            @{Label="Updated"; Expression={$_.__Updated} },
            @{Label="Updated by"; Expression={$_."__Updated by"} },
            @{Label="Created"; Expression={$_.__Created} },
            @{Label="Created by"; Expression={$_."__Created by"} },
            @{Label="Path"; Expression={$_.ItemPath} }
        )
    }
    
    $items | Show-ListView @props
}
Close-Window
