Import-Function -Name Invoke-SqlCommand

$owner = [Sitecore.Context]::User.Name

$connection = [Sitecore.Configuration.Settings]::GetConnectionString("master")

$fieldId = [Sitecore.FieldIDs]::Lock

$query = @"
SELECT [ItemId], [Value], [Language], [Version]
  FROM [dbo].[VersionedFields]
  WHERE [FieldId] = '$($fieldId.ToString())'
    AND [Value] <> '' AND [Value] <> '<r />'
"@
$records = Invoke-SqlCommand -Connection $connection -Query $query

if($records -and ![string]::IsNullOrEmpty($owner)) {
    Write-Log "Unlocking items for $($owner)"
    $pattern = [regex]::Escape("owner=`"$($owner)`"")
    $records | Where-Object { $_.Value -match $pattern } | ForEach-Object { Get-Item -Path "master:" -ID $_.ItemId -Language $_.Language -Version $_.Version | Unlock-Item }
}
