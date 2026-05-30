<#
    .SYNOPSIS
        How many times is each rendering used in your solution?
        
    .NOTES
        Michael West
#>
Import-Function Render-ReportField

filter IsRendering {
    # Look for Controller and View renderings
    $renderingIds = @("{2A3E91A0-7987-44B5-AB34-35C2D9DE83B9}","{99F8905D-4A87-4EB8-9F8B-A9BEBFB3ADD6}")
    if(($renderingIds -contains $_.TemplateID)) { $_; return }
}

$database = "master"

# Renderings Root
$renderingsRootItem = Get-Item -Path "$($database):{32566F0E-7686-45F1-A12F-D7260BD78BC3}"
$items = $renderingsRootItem.Axes.GetDescendants() | Initialize-Item | IsRendering

$reportItems = @()
foreach($item in $items) {
    $count = 0
    $referrers = Get-ItemReferrer -Item $item
    if ($referrers -ne $null) {
        $count = $referrers.Count
    }

    $reportItem = [PSCustomObject]@{
        "Icon" = $item."__Icon"
        "Name"=$item.Name
        "UsageCount"=$count
        "ItemPath" = $item.ItemPath
        "TemplateName" = $item.TemplateName
        "Controller" = $item.Controller
    }
    $reportItems += $reportItem
}

$reportProps = @{
    Property = @(
        "Icon",@{Name="Rendering Name"; Expression={$_.Name}}, 
        @{Name="Number of usages"; Expression={$_.UsageCount}}, "ItemPath",
        @{Label="Rendering Type"; Expression={$_.TemplateName} },
        "Controller"
    )
    Title = "Custom rendering report"
    InfoTitle = "Available Renderings"
    InfoDescription = "Count of references for each rendering. Results include only MVC Controller and View renderings." 
}

$reportItems | 
        Sort-Object UsageCount -Descending |
        Show-ListView @reportProps

Close-Window
