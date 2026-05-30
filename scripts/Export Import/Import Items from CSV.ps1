# Import Items from CSV
# Creates Sitecore items from CSV data.

$csv = Import-Csv "C:\Temp\Items.csv"

foreach ($row in $csv) {
    New-Item `
        -Path "master:/sitecore/content/Home" `
        -Name $row.ItemName `
        -ItemType "Sample Item"

    Write-Host "Created $($row.ItemName)"
}
