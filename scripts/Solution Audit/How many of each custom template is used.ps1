<#
    .SYNOPSIS
        How many custom templates are in use in your solution?
        Before executing this script point the "Context Item" to where you store your solution templates e.g. "Sitecore/templates/My Site Templates"
        
    .NOTES
        Michael West
        Adam najmanowicz

    .LINKS
        https://gist.github.com/AdamNaj/3b1f7c9519c3c36ecb8ccbe5401f3966
#>
Import-Function Render-ReportField

$ignorePattern = "^(" + ("Branches/System","Common","List Manager", "Sample", "System" -join "|") + ")"
$templates = [Sitecore.Data.Managers.TemplateManager]::GetTemplates((Get-Database "master"))
$reportItems = @()
foreach($template in $templates) {
    if($template -and ($template.Value.FullName -notmatch $ignorePattern) -and -not ($template.GetType().Name -match "ErrorRecord")) {
        $templateItem = Get-Item master:\ -ID $template.Value.ID
        $itemLinks = @(Get-ItemReferrer -Database "master" -ID $template.Value.ID -ItemLink)
        $reportItem = [PSCustomObject]@{
            "Icon" = $templateItem."__Icon"
            "Name"=$template.Value.Name
            "UsageCount"=$itemLinks.Count
        }
        $reportItems += $reportItem
    }
}

$reportItems | 
        Sort-Object UsageCount -Descending |
        Show-ListView -Property Icon,@{Name="Template Name"; Expression={$_.Name}}, @{Name="Number of usages"; Expression={$_.UsageCount}}`
            -Title "Custom templates report" `
            -InfoTitle "Usage Data"`
            -InfoDescription "Count of custom templates used." 

Close-Window
