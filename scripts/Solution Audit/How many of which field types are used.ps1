<#
  What field types and in what numbers do you use in your solution?
 
  Before executing this script point the "Context Item" to where you store your solution templates e.g. "Sitecore/templates/My Site Templates"
#>
Import-Function Render-ReportField

$item = Get-Item -Path "master:\templates"
$icon =[regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$result = Read-Variable -Parameters `
    @{ Name = "item"; Title="Template branch to analyse"; Tooltip="Branch you want to analyse."; Root="/sitecore/templates/"} `
    -Description "This report will analyse the template branch and will tell you which field types are used in which quantities." `
    -Title "Count field types used by templates. " -Width 500 -Height 280 `
    -OkButtonName "Proceed" -CancelButtonName "Abort" -Icon $icon

if($result -ne "ok") {
    Close-Window
    Exit
}

# We need to change location to a Sitecore database do that PowerShell can recognize -Query as a valid parameter
$fields = $item.Axes.GetDescendants() | Where-Object { $_.TemplateId -eq "{455A3E98-A627-4B40-8035-E683A0331AC7}" } | Initialize-Item | Group-Object Type
$total = 0 
$fields | ForEach-Object { $total += $_.Count } > $null
$fields | ForEach-Object { Add-Member -InputObject $_ -MemberType NoteProperty -Name Percent -Value ([math]::Round($_.Count * 100 / $total)) }

$fields |
  Sort-Object count -Descending |
        Show-ListView -Property @{Name="Field Type"; Expression={$_.Name}}, @{Name="Number of usages"; Expression={$_.Count}}, @{Name="Percent of usages"; Expression={ Render-PercentValue $_.Percent}}`
            -Title "Field types used by templates" `
            -InfoDescription "Field types used by templates under $($item.Paths.Path) branch." 
Close-Window
