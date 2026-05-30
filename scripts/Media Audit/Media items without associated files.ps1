<#
    .SYNOPSIS
        Lists all file system based media items which associated files on the file system no longer exists.
    
    .NOTES
        Michael West
#>
function IsFileBasedLost {
    param(
        $Item
    )
    
    $mediaItem = New-Object Sitecore.Data.Items.MediaItem $item
    if($mediaItem.FileBased) {
        !(Test-Path -Path ([Sitecore.IO.FileUtil]::MapPath($mediaItem.FilePath)))
    } else {
        $false
    }
}

function Get-MediaItemFileBasedLost {
    
    if(Test-Path -Path $SitecoreDataFolder) {
        $mediaItemContainer = Get-Item "master:/media library"
        $items = $mediaItemContainer.Axes.GetDescendants() | Where-Object { $_.TemplateID -ne [Sitecore.TemplateIDs]::MediaFolder } | Initialize-Item
        
        foreach($item in $items) {
            if(IsFileBasedLost($item)) {
                $item
            }
        }
    }
}

$items = Get-MediaItemFileBasedLost

if($items.Count -eq 0) {
    Show-Alert "There are no media items without associated files."
} else {
    $props = @{
        Title = $PSScript.Name
        InfoTitle = "Media items without associated files"
        InfoDescription = "Lists all file system based media items which associated files on the file system no longer exists."
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
            @{Label="Path"; Expression={$_.ItemPath} },
            @{Label="File Path"; Expression={$_."File Path"} }
}        
Close-Window

