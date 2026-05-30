<#
    .SYNOPSIS
        Lists all media items that are file system based.
    
    .NOTES
        Michael West
#>
function IsFileBased {
    param(
        $Item
    )
    
    (New-Object Sitecore.Data.Items.MediaItem $item).FileBased
}

function Get-MediaItemFileBased {
    $mediaItemContainer = Get-Item "master:/media library"
    $items = $mediaItemContainer.Axes.GetDescendants() | Where-Object { $_.TemplateID -ne [Sitecore.TemplateIDs]::MediaFolder } | Initialize-Item
    
    foreach($item in $items) {
        if(IsFileBased($item)) {
            $item
        }
    }
}

$items = Get-MediaItemFileBased

if($items.Count -eq 0) {
    Show-Alert "There are no file-based media items."
} else {
    $props = @{
        Title = $PSScript.Name
        InfoTitle = "File based media items"
        InfoDescription = "Lists all media items that are file system based."
        PageSize = 25
    }
    
    Get-MediaItemFileBased |
        Show-ListView @props -Property @{Label="Name"; Expression={$_.DisplayName} },
            @{Label="Size"; Expression={$_.Size}},
            @{Label="Extension"; Expression={$_.Extension}},
            @{Label="Updated"; Expression={$_.__Updated} },
            @{Label="Updated by"; Expression={$_."__Updated by"} },
            @{Label="Created"; Expression={$_.__Created} },
            @{Label="Created by"; Expression={$_."__Created by"} },
            @{Label="Path"; Expression={$_.ItemPath} },
            @{Label="File Path"; Expression={$_."File Path"} }
}

Close-Window
