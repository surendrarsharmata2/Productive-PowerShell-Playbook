# Bulk Import Field Values from CSV
# Update existing items using CSV.

# CSV Example:
# ItemId,Title
# {GUID1},New Title 1
# {GUID2},New Title 2

$rows = Import-Csv "C:\Temp\UpdateItems.csv"

foreach($row in $rows)
{
    $item = Get-Item "master:" -ID $row.ItemId

    if($item)
    {
        $item.Editing.BeginEdit()
        $item["Title"] = $row.Title
        $item.Editing.EndEdit()

        Write-Host "Updated $($item.Name)"
    }
}
