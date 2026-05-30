$sourceItem = Get-Item -Path .
$status = "Renderings copied from: `n$($sourceItem.ProviderPath)" 
Write-Progress -Activity "Copy renderings" -Status $status -CurrentOperation "Renderings copied. You can paste them in another item now."
