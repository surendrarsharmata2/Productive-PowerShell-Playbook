<#
    .SYNOPSIS
        Moves items to the recycle bin which are more than 30 days old and have no references.
    
    .NOTES
        Michael West
#>

filter Skip-MissingReference {
    $linkDb = [Sitecore.Globals]::LinkDatabase
    if($linkDb.GetReferrerCount($_) -eq 0) {
        $_
    }
}

$lastMonth = [datetime]::Today.AddDays(-30)

$items = Get-ChildItem -Path "master:\sitecore\media library" -Recurse | 
    Where-Object { $_.TemplateID -ne [Sitecore.TemplateIDs]::MediaFolder } |
    Where-Object { $_.__Owner -ne "sitecore\admin" -and $_.__Updated -lt $lastMonth } |
    Skip-MissingReference

if($items) {
    Write-Log "Removing $($items.Length) item(s) older than 30 days."
    $items | Remove-Item
}
