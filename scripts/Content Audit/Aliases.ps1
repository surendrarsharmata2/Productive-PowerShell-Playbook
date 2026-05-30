<#
    .SYNOPSIS
        Lists all aliases and their linked items
        
    .NOTES
        Alex Washtell
        Adapted from the Advanced System Reporter module.
#>


function Get-LinkedItem {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Sitecore.Data.Items.Item]$AliasItem
    )
    
    if($AliasItem) {
        
        [Sitecore.Data.Fields.LinkField]$linkField = $AliasItem.Fields["Linked item"]
        
        if ($linkField)
        {
            return $linkField.TargetItem
        }
    }
}

$aliasPath = "/sitecore/system/aliases/"
$items = Get-ChildItem -Path "master:$aliasPath" -Recurse

if($items.Count -eq 0){
    Show-Alert "There are no aliases."
} else {
    $props = @{
        Title = "Alias Report"
        InfoTitle = "Aliases"
        InfoDescription = "Lists all aliases and their linked items."
        PageSize = 25
    }
    
    $items |
        Show-ListView @props -Property @{Label="Alias"; Expression={ $_.Paths.FullPath -replace $aliasPath, "" } },
            @{Label="Target Item"; Expression={($_ | Get-LinkedItem).Paths.FullPath}},
            @{Label="Created"; Expression={$_.__Created} },
            @{Label="Created by"; Expression={$_."__Created by"} }
            
}
Close-Window

