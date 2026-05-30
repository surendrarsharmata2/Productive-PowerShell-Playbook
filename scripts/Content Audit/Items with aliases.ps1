<#
    .SYNOPSIS
        Lists the items with at least one alias
        
    .NOTES
        Alex Washtell
        Adapted from the Advanced System Reporter module.
#>

$database = "master"
$root = Get-Item -Path (@{$true="$($database):\content\home"; $false="$($database):\content"}[(Test-Path -Path "$($database):\content\home")])

$props = @{
    Parameters = @(
        @{Name="root"; Title="Choose the report root"; Tooltip="Only items from this root will be returned.";}
    )
    Title = "Items With Aliases Report"
    Description = "Choose the criteria for the report."
    ShowHints = $true
    Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

$result = Read-Variable @props

if($result -eq "cancel"){
    exit
}

$aliasPath = "/sitecore/system/aliases/"
$allAliases = Get-ChildItem -Path "master:$aliasPath" -Recurse

filter WithAliases {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Sitecore.Data.Items.Item]$Item
    )
    
    if($Item) {
        $matchingAliases = $allAliases | ? { $_."Linked item" -match $Item.ID }
        if ($matchingAliases)
        {
            
            @{ Item = $Item; Aliases = ($matchingAliases | Select -Expand FullPath) -replace $aliasPath,"" -join ", " }
        }
    }
}

$items = @($root) + @(($root.Axes.GetDescendants() | Initialize-Item)) | WithAliases

if($items.Count -eq 0){
    Show-Alert "There are no items found which have aliases."
} else {
    $props = @{
        Title = "Item Alias Report"
        InfoTitle = "Items with aliases"
        InfoDescription = "Lists the items with at least one alias."
        PageSize = 25
    }
    
    $items |
        Show-ListView @props -Property @{Label="Name"; Expression={$_.Item.DisplayName} },
            @{Label="Aliases"; Expression={$_.Aliases}},
            @{Label="Path"; Expression={$_.Item.ItemPath} },
            @{Label="Updated"; Expression={$_.Item.__Updated} },
            @{Label="Updated by"; Expression={$_.Item."__Updated by"} },
            @{Label="Created"; Expression={$_.Item.__Created} },
            @{Label="Created by"; Expression={$_.Item."__Created by"} }
}
Close-Window

