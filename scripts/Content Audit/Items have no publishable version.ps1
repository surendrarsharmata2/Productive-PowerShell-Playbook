<#
    .SYNOPSIS
        Lists the items with no publishable version or item is unpublishable.
        
    .NOTES
        Michael West
        Adapted from the Advanced System Reporter module.
#>

filter NoPublishableVersions {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Sitecore.Data.Items.Item]$Item
    )
    
    if($Item) {
        if(!$item.Publishing.NeverPublish) {
            $isValid = $item.Publishing.GetValidVersion([datetime]::Now, $true, $false)
            if($isValid -eq $null) {
                $Item
            }
        } else {
            $Item
        }
    }
}

$database = "master"
$root = Get-Item -Path (@{$true="$($database):\content\home"; $false="$($database):\content"}[(Test-Path -Path "$($database):\content\home")])
$props = @{
    Parameters = @(
        @{Name="root"; Title="Choose the report root"; Tooltip="Only items in this branch will be returned.";}
    )
    Title = "Report Filter"
    Description = "Choose the criteria for the report."
    Width = 550
    Height = 300
    ShowHints = $true
    Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

$result = Read-Variable @props

if($result -eq "cancel"){
    exit
}

$items = @($root) + @(($root.Axes.GetDescendants())) | NoPublishableVersions | Initialize-Item

if($items.Count -eq 0){
    Show-Alert "There are no items found which are non-publishable."
} else {
    $props = @{
        Title = "Items with No Publishable Version Report"
        InfoTitle = "Non-publishable items"
        InfoDescription = "Lists the items with no publishable version."
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
