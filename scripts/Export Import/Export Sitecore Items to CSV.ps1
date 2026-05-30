$items = Get-ChildItem "master:/sitecore/content/Home" -Recurse

$result = foreach($item in $items)
{
    [PSCustomObject]@{
        ItemName = $item.Name
        ItemId = $item.ID
        Template = $item.TemplateName
        Path = $item.Paths.FullPath
        Title = $item["Title"]
    }
}

$result | Export-Csv "C:\Temp\Items.csv" -NoTypeInformation