<#
    .SYNOPSIS
        Lists all media items that have validation warnings or errors.
        
    .NOTES
        Michael West
#>
function Get-ValidationWarning {
    param(
        $Item
    )
    
    $mediaItem = New-Object Sitecore.Data.Items.MediaItem $Item
    $res = $mediaItem.ValidateMedia()
         
    $res.Warnings
}

function Get-MediaItemWithError {
    $mediaItemContainer = Get-Item "master:/media library"
    $items = $mediaItemContainer.Axes.GetDescendants() | Where-Object { $_.TemplateID -ne [Sitecore.TemplateIDs]::MediaFolder } | Initialize-Item
    
    foreach($item in $items) {
        $warnings = Get-ValidationWarning -Item $item
        if($warnings) {
            $item | Add-Member -MemberType NoteProperty -Name "Warnings" -Value $warnings
            $item
        }
    }
}

$items = Get-MediaItemWithError

if($items.Count -eq 0) {
    Show-Alert "There are no media items with warnings."
} else {
    $props = @{
        Title = $PSScript.Name
        InfoTitle = "Media items with warnings"
        InfoDescription = "Lists all media items that have validation warnings or errors."
        PageSize = 25
    }
    
    $items |
        Show-ListView @props -Property @{Label="Name"; Expression={$_.DisplayName} },
            @{Label="Size"; Expression={$_.Size}},
            @{Label="Extension"; Expression={$_.Extension}},
            @{Label="Warnings"; Expression={$_.Warnings}},
            @{Label="Updated"; Expression={$_.__Updated} },
            @{Label="Updated by"; Expression={$_."__Updated by"} },
            @{Label="Created"; Expression={$_.__Created} },
            @{Label="Created by"; Expression={$_."__Created by"} },
            @{Label="Path"; Expression={$_.ItemPath} } `
}
Close-Window
