<#
Get-Item -Path "master:" -ID "{A6F2C29F-2797-4105-B714-034248D523AB}" | Remove-Item -Force
exit
$item = Get-Item -Path "master:" -ID "{6DFDBCED-9059-4700-9D3B-C3A9C6EA301C}"
$newTemplate = Get-Item -Path "master:" -ID "{B0B6FB08-6BBE-43F2-8E36-FCE228325B63}"

Set-ItemTemplate -ID $item.ID -TemplateItem $newTemplate
#>

Import-Function -Name Invoke-SqlCommand

$connection = [Sitecore.Configuration.Settings]::GetConnectionString("master")

$query = @"
SELECT [ID] FROM [dbo].[Items] WHERE [TemplateID] NOT IN (SELECT DISTINCT [ID] FROM [dbo].[Items])
"@
$records = Invoke-SqlCommand -Connection $connection -Query $query

$items = [System.Collections.ArrayList]@()
foreach($record in $records) {
    $item = Get-Item -Path "master:" -ID $record.ID
    $items.Add($item) > $null
}

$reportProps = @{
    Title = "Items with a missing template"
    InfoTitle = "Items with a template missing from the database"
    InfoDescription = "The items listed may cause errors within Sitecore."
    Property = @("Name","Language","Version","ID","Database","Template","ItemPath")
}
$items | Show-ListView @reportProps
Close-Window
