<#
    .SYNOPSIS
        Lists all content items that inherit from a given template
        
    .NOTES
        Alex Washtell
#>

$database = "master"
$root = Get-Item -Path (@{$true="$($database):\content\home"; $false="$($database):\content"}[(Test-Path -Path "$($database):\content\home")])
$baseTemplate = Get-Item master:\templates

$props = @{
    Parameters = @(
        @{Name="root"; Title="Choose the report root"; Tooltip="Only items from this root will be returned."; }
        @{ Name = "baseTemplate"; Title="Base Template"; Tooltip="Select the item to use as a base template for the report"; Root="/sitecore/templates/"}
    )
    Title = "Items With Template Report"
    Description = "Choose the criteria for the report."
    Width = 550
    Height = 300
    ShowHints = $true
    Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

$result = Read-Variable @props

if($result -eq "cancel") {
    exit
}

filter Where-InheritsTemplate {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Sitecore.Data.Items.Item]$item
    )
    
    if ($item) {
        $itemTemplate = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item)

        if ($itemTemplate.DescendsFromOrEquals($baseTemplate.ID)) {
            $Item
        }
    }
}

$items = @($root) + @(($root.Axes.GetDescendants() | Initialize-Item)) | Where-InheritsTemplate

if($items.Count -eq 0) {
    Show-Alert "There are no content items that inherit from this template"
} else {
    $props = @{
        Title = "Item Template Report"
        InfoTitle = "Items that inherit from the '$($baseTemplate.Name)' template"
        InfoDescription = "The following items all inherit from the '$($baseTemplate.FullPath)' template."
        PageSize = 25
    }
    
    $items |
        Show-ListView @props -Property @{Label="Icon"; Expression={$_.__Icon} },
            @{Label="Name"; Expression={$_.DisplayName} },
            @{Label="Updated"; Expression={$_.__Updated} },
            @{Label="Updated by"; Expression={$_."__Updated by"} },
            @{Label="Created"; Expression={$_.__Created} },
            @{Label="Created by"; Expression={$_."__Created by"} },
            @{Label="Path"; Expression={$_.ItemPath} }
}

Close-Window
