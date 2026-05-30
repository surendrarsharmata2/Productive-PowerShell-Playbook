<#
    .SYNOPSIS
        Lists all media items that have obsolete versions that are not used.
        
    .NOTES
        Michael West
#>
function HasOlderVersion {
    param(
        $Item
    )
    
    $versions = $Item.Versions.GetVersions($true)
    
    $result = $false
    foreach($version in $versions) {
        if(!$version.Versions.IsLatestVersion()) {
            $result = $true
        }
    }
    
    $result
}

function Get-MediaItemWithObsoleteVersion {
    $mediaItemContainer = Get-Item "master:/media library"
    $items = $mediaItemContainer.Axes.GetDescendants() | Where-Object { $_.TemplateID -ne [Sitecore.TemplateIDs]::MediaFolder } | Initialize-Item
    
    foreach($item in $items) {
        if(HasOlderVersion($item)) {
            $item
        }
    }
}

$items = Get-MediaItemWithObsoleteVersion

if($items.Count -eq 0) {
    Show-Alert "There are no media items with obsolete versions."
} else {

    $props = @{
        Title = $PSScript.Name
        InfoTitle = "Media items with obsolete versions"
        InfoDescription = "Lists all media items that have obsolete versions that are not used."
        PageSize = 25
    }

    $items |
        Show-ListView @props -Property @{Label="Name"; Expression={$_.DisplayName} },
            @{Label="Size"; Expression={$_.Size}},
            @{Label="Extension"; Expression={$_.Extension}},
            @{Label="Updated"; Expression={$_.__Updated} },
            @{Label="Updated by"; Expression={$_."__Updated by"} },
            @{Label="Created"; Expression={$_.__Created} },
            @{Label="Created by"; Expression={$_."__Created by"} },
            @{Label="Path"; Expression={$_.ItemPath} }
}

Close-Window
