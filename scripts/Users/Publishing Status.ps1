<#
    Adapted from:
    http://www.partechit.nl/en/blog/2013/03/display-item-publication-status-in-the-sitecore-gutter
#>
 
# The $item variable is populated in the GutterStatusRenderer class using session.SetVariable.
$item = Get-Item -Path .
if(-not $item) {
    Write-Log "The item is null."
    return $null
}
$publishingTargetsFolderId = New-Object Sitecore.Data.ID "{D9E44555-02A6-407A-B4FC-96B9026CAADD}"
$targetDatabaseFieldId = New-Object Sitecore.Data.ID "{39ECFD90-55D2-49D8-B513-99D15573DE41}"
 
$existsInAll = $true
$existsInOne = $false
 
# Find the publishing targets item folder
$publishingTargetsFolder = [Sitecore.Context]::ContentDatabase.GetItem($publishingTargetsFolderId)
if ($publishingTargetsFolder -eq $null) {
    return $null
}
 
# Retrieve the publishing targets database names
# Check for item existance in publishing targets
foreach($publishingTargetDatabase in $publishingTargetsFolder.GetChildren()) {
    Write-Log "Checking the $($publishingTargetDatabase[$targetDatabaseFieldId]) for the existence of $($item.ID)"
    if([Sitecore.Data.Database]::GetDatabase($publishingTargetDatabase[$targetDatabaseFieldId]).GetItem($item.ID)) {
        $existsInOne = $true
    } else {
        $existsInAll = $false
    }
}

# Better performance and readability if we don't show any flag if there is nothing to be concerned about.
if ($existsInAll) {
    Write-Log "Exists in all"
    return $null
}
 
# Return descriptor with tooltip and icon
if ($existsInOne) {
    $tooltip = [Sitecore.Globalization.Translate]::Text("This item has been published to at least one target")
    $icon = "Office/16x16/information.png"
    Write-Log "Exists in one"
} else {
    $tooltip = [Sitecore.Globalization.Translate]::Text("This item has not yet been published")
    $icon = "Office/16x16/question.png"    
}
 
$gutter = New-Object Sitecore.Shell.Applications.ContentEditor.Gutters.GutterIconDescriptor
$gutter.Icon = $icon
$gutter.Tooltip = $tooltip
$gutter.Click = [String]::Format("item:publish(id={0})", $item.ID)
$gutter
