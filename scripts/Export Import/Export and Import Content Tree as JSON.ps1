# Export Content Tree to JSON & Re-import

# Export
$item = Get-Item "master:/sitecore/content/Home"

$children = $item.Children | ForEach-Object {
    @{
        Name = $_.Name
        Template = $_.TemplateName
        Title = $_["Title"]
    }
}

$children | ConvertTo-Json -Depth 5 |
    Set-Content "C:\Temp\content.json"

# Import
$data = Get-Content "C:\Temp\content.json" -Raw | ConvertFrom-Json

foreach($row in $data)
{
    $newItem = New-Item `
        -Path "master:/sitecore/content/Home" `
        -Name $row.Name `
        -ItemType $row.Template

    $newItem.Editing.BeginEdit()
    $newItem["Title"] = $row.Title
    $newItem.Editing.EndEdit()
}
