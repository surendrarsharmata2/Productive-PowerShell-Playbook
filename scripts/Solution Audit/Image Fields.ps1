<#
  What "Image" type fields do I have and in which template? Do they have Source defined?
 
  Sitecore recommendation:
     Image Fields — Define the source field to show the point 
                    in the media library that is relevant to the item being created.
 
  Before executing this script point the "Context Item" to where you store your solution templates e.g. "Sitecore/templates/My Site Templates"
 
  How to read this report?
  ------------------------
  The report will show all fields of type "Image" and a path ot a template it's defined in.
  Just because field does not define Source, doesn't mean it's a problem, but this report allows you to have a view on all of them and decide.
#>

$item = Get-Item -Path "master:\templates"
$icon =[regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$result = Read-Variable -Parameters `
    @{ Name = "item"; Title="Template branch to analyse"; Tooltip="Branch you want to analyse."; Root="/sitecore/templates/"} `
    -Description "What Image fields do I have and in which template? Do they have Source defined? The report will show all fields of type 'Image' and a path to a template it's defined in." `
    -Title "Report Filter" -Width 500 -Height 280 `
    -OkButtonName "Proceed" -CancelButtonName "Abort" -Icon $icon

if($result -ne "ok") {
    Close-Window
    Exit
}

@($item) + @(($item.Axes.GetDescendants() | Initialize-Item)) |
  Where-Object { $_.TemplateName -eq "Template Field" -and $_.Type -eq "Image" } |
  Show-ListView -Property `
    @{Name="Field Name"; Expression={$_.Name }}, `
    @{Name="Template"; Expression={$_.Parent.Parent.Paths.Path -replace "/Sitecore/templates/", "" }}, `
    @{Name="Source"; Expression={$_._Source }},
    @{Name="Icon"; Expression={ if($_._Source -eq "") { "Office/32x32/lightbulb_off.png" } else { "Office/32x32/lightbulb_on.png" }  }} `
    -Title "Templates with Image fields" `
    -InfoTitle "The report will show all fields of type Image and a path to a template it's defined in." `
    -InfoDescription "Just because field does not define Source, doesn't mean it's a problem, but this report allows you to have a view on all of them and decide." `
    -PageSize 100
Close-Window
