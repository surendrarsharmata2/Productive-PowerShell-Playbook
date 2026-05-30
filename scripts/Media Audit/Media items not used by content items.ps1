<#
    .SYNOPSIS
        Lists all media items that are not linked to content items.
        
    .NOTES
        Michael West
#>
function HasContentReference {
    param(
        $Item
    )
    
    $linkDb = [Sitecore.Globals]::LinkDatabase
    $links = $linkDb.GetReferrers($Item)
    
    $result = $false
    
    foreach($link in $links) {
        $linkItem = $link.GetSourceItem()
        if ($linkItem) {
            $path = New-Object Sitecore.Data.ItemPath ($linkItem)
            if($path.IsContentItem) {
                $result = $true
                break
            }
        }
    }
    
    $result
}

function Get-MediaItemWithNoReference {
    $mediaItemContainer = Get-Item "master:/media library"
    $items = $mediaItemContainer.Axes.GetDescendants() | Where-Object { $_.TemplateID -ne [Sitecore.TemplateIDs]::MediaFolder } | Initialize-Item
    
    foreach($item in $items) {
        if(!(HasContentReference($item))) {
            $item
        }
    }
}

$items = Get-MediaItemWithNoReference 

if($items.Count -eq 0) {
    Show-Alert "There are no media items not used by content items"
} else {
    $props = @{
        Title = $PSScript.Name
        InfoTitle = "Media items not used by content items"
        InfoDescription = "Lists all media items that are not linked to content items."
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
