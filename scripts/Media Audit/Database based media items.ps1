<#
    .SYNOPSIS
        Lists all media items that are database based.
    
    .NOTES
        Michael West
#>
function IsNotFileBased {
    param(
        $Item
    )
    
    !(New-Object Sitecore.Data.Items.MediaItem $item).FileBased
}

function Get-MediaItemNotFileBased {
    $mediaItemContainer = Get-Item "master:/media library"
    $items = $mediaItemContainer.Axes.GetDescendants() | Where-Object { $_.TemplateID -ne [Sitecore.TemplateIDs]::MediaFolder } | Initialize-Item
    
    foreach($item in $items) {
        if(IsNotFileBased($item)) {
            $item
        }
    }
}

$items = Get-MediaItemNotFileBased

if($items.Count -eq 0){
    Show-Alert "There are no database based media items"
} else {
    $props = @{
        InfoTitle = $PSScript.Name
        InfoDescription = "Lists all media items that are database based."
        PageSize = 25
        Title = $PSScript.Name
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
