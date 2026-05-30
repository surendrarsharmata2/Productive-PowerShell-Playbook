<#
  Which of my Templates inherit from Standard Item template?
 
  Sitecore recommendation:
     Make good use of inheritance — Place commonly used sections and fields in their own template, 
     so that more specific templates can inherit them. For example, the Title and Text fields in the Page Title 
     and Text section are used in multiple different content templates. Rather than duplicate these fields 
     in each content template, simply inherit the Page Title and Text template.
 
  Before executing this script point the "Context Item" to where you store your solution templates e.g. "Sitecore/templates/My Site Templates"
#>

$item = Get-Item -Path "master:\templates"
$icon =[regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$result = Read-Variable -Parameters `
    @{ Name = "item"; Title="Template branch to analyse"; Tooltip="Branch you want to analyse."; Root="/sitecore/templates"} `
    -Description "This script analyses which of your templates inherit directly from <i>Standard Item</i> template?." `
    -Title "Sitecore recommendation: Make good use of inheritance" -Width 500 -Height 280 `
    -OkButtonName "Proceed" -CancelButtonName "Abort" -Icon $icon

if($result -ne "ok") {
    Close-Window
    Exit
}


@($item) + @(($item.Axes.GetDescendants() | Initialize-Item)) |
  Where-Object { $_.TemplateName -eq "Template" -and $_."__base template" -eq "{1930BBEB-7805-471A-A3BE-4858AC7CF696}" } | `
    Show-ListView -Property DisplayName, @{Name="Path"; Expression={$_.ItemPath}} `
        -Title "Templates inheriting directly from Standard Item template" `
        -InfoTitle "Sitecore recommendation: Make good use of inheritance" `
        -InfoDescription "Place commonly used sections and fields in their own template, so that more specific templates can inherit them. <br/>
                          For example, the Title and Text fields in the Page Title and Text section are used in multiple different content templates. <br/>
                          Rather than duplicate these fields in each content template, simply inherit the Page Title and Text template. <br/><br/>
                          Listed below are templates inheriting directly from <i>Standard Item</i> template"
Close-Window
