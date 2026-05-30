$props = @{
    Index = "sitecore_master_index"
    Where = 'Paths.Contains(@0) Or Paths.Contains(@1)'
    WhereValues = [ID]::Parse("{0DE95AE4-41AB-4D01-9EB0-67441B7C2450}"), [ID]::Parse("{3D6658D8-A0BF-4E75-B3E2-D050FABCF4E1}")
    FacetOn = "Path"
    FacetMinCount = 2
}

$facetedResults = Find-Item @props | Select-Object -Expand Categories | Select-Object -Expand Values | Select-Object -Expand Name

$items = [System.Collections.ArrayList]@()
foreach($facetedResult in $facetedResults) {
    if(!$facetedResult.StartsWith("/sitecore")) {
        $facetedResult = "/sitecore/media library$($facetedResult)"
    }
    $duplicateItems = @(Get-Item -Path "master:" -Query $facetedResult)
    if($duplicateItems -and $duplicateItems.Count -gt 1) {
        $items.AddRange($duplicateItems)
    }
}

if($items.Count -eq 0) {
    Show-Alert "There are no items matching the specified criteria."
} else {
    
    $description = "Items in this report reflect those from the search index which contain the same name. An accurate referrer count depends on the Link database to be up-to-date."
    $hasProblem = [Sitecore.Configuration.Settings]::GetBoolSetting("AllowDuplicateItemNamesOnSameLevel", $false)
    if($hasProblem) {
        $description += " The setting 'AllowDuplicateItemNamesOnSameLevel' should be changed to false."
    }
    $props = @{
        Title = "Items with duplicate names"
        InfoTitle = "Items with duplicate names"
        InfoDescription = $description
        PageSize = 25
        Property = @(
            @{Label="Name"; Expression={$_.DisplayName} },
            @{Label="Referrers"; Expression={Get-ItemReferrer -Id $_.ID -ItemLink | Measure-Object | Select-Object -Expand Count}},
            @{Label="Updated"; Expression={$_.__Updated} },
            @{Label="Updated by"; Expression={$_."__Updated by"} },
            @{Label="Created"; Expression={$_.__Created} },
            @{Label="Created by"; Expression={$_."__Created by"} },
            @{Label="Path"; Expression={$_.ItemPath} }
        )
    }
    
    $items | Show-ListView @props
}
Close-Window
