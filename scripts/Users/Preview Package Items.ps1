$items = Get-PackageItem -Project $package -SkipDuplicates

if($items.Count -eq 0) {
    Show-Alert "There are no items currently added to the package."
} else {
    $previewProps = @{
        Property = @("Name", "DisplayName", "Language", "Version", "ID", "TemplateName", "ItemPath")
        Title = "Preview Package Items"
        InfoTitle = "Preview Package Items"
        InfoDescription = "A preview of items currently added into the package generator for this session."
    }
    $items | Show-ListView @previewProps
}

Close-Window
