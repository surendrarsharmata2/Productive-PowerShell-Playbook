<#
    .SYNOPSIS
        Lists all images with an empty Alt field.
     
    .NOTES
        Mike Reynolds
        Michael West
#>
 
function Get-ImageItemNoAltText {    
    $mediaItemContainer = Get-Item "master:/media library"
    $items = $mediaItemContainer.Axes.GetDescendants() | Where-Object { $_.TemplateID -ne [Sitecore.TemplateIDs]::MediaFolder -and $_.Fields["Alt"] -ne $null } | Initialize-Item
     
    foreach($item in $items) {
        if(-not($item."Alt")) {
            $item
        }
    }
}
 
$items = Get-ImageItemNoAltText
 
if($items.Count -eq 0) {
    Show-Alert "There are no images with an empty Alt field."
} else {
    $props = @{
        Title = $PSScript.Name
        InfoTitle = "Images with an empty Alt field"
        InfoDescription = "Lists all images with an empty Alt field."
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
