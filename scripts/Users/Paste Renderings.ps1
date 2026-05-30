$targetItem = Get-Item -Path .

$targetItem.__Renderings = $sourceItem.__Renderings;

if ($sourceItem.PSObject.Properties.Match("__Final Renderings").Count) {
    $targetItem."__Final Renderings" = $sourceItem."__Final Renderings";
    $status = "Renderings pasted from '$($sourceItem.ProviderPath)' to '$($targetItem.ProviderPath)'"
} else {
    $status = "No renderings found on '$($sourceItem.ProviderPath)'"
}

Write-Progress -Activity "Paste renderings" -Status " " -CurrentOperation $status

