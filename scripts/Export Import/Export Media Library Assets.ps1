# Export Media Library Assets
# Exports all media item metadata.

$mediaItems = Get-ChildItem "master:/sitecore/media library" -Recurse

$result = foreach($item in $mediaItems)
{
    [PSCustomObject]@{
        Name = $item.Name
        Id = $item.ID
        Path = $item.Paths.FullPath
        Template = $item.TemplateName
    }
}

$result | Export-Csv "C:\Temp\MediaLibrary.csv" -NoTypeInformation
