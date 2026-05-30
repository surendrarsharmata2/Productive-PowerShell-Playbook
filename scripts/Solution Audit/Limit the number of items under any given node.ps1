<#
  Which of my items have most children? Are there too many?
 
  Sitecore recommendation:
     Limit the number of items under any given node that share the same parent, to 100 items or less for performance and usability.
 
  Before executing this script point the "Context Item" to your site e.g. "Sitecore/content/My Site"
 
  How to read this report?
  ------------------------
  The report will show you all the nodes that have more than 50 direct descendants to allow you to address any potential issues arising. 
  If the list is empty (no results shown) it means your solution is not even close to violating the recommendation and you can give yourself a pat on the back.
#>

$item = Get-Item -Path "master:\content"
$icon =[regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$result = Read-Variable -Parameters `
    @{ Name = "item"; Title="Branch to analyse"; Tooltip="Branch you want to analyse."; Root="/sitecore/"}, `
    @{ Name = "maxCount"; Value=50; Title="Children number threshhold"; Tooltip="List items with more than this number of children.";} `
    -Description "Which of my items have most children? Are there too many? The report will show you all the nodes that have more than your selected number of direct descendants to allow you to address any potential issues arising. " `
    -Title "Report Filter" -Width 500 -Height 280 `
    -OkButtonName "Proceed" -CancelButtonName "Abort" -Icon $icon

if($result -ne "ok") {
    Close-Window
    Exit
}

@($item) + @(($item.Axes.GetDescendants())) | Where-Object { $_.Children.Count -gt $maxCount } | 
    Initialize-Item |
    Sort-Object -Property @{Expression={$_.Children.Count}; Descending=$true} |
    Show-ListView -Property Name, `
        @{Name="Children"; Expression={$_.Children.Count}}, `
        @{Name="Path"; Expression={$_.ItemPath}} `
        -Title "Which of my items have the most children?" `
        -InfoTitle "Sitecore recommendation: Limit the number of items under any given node that share the same parent, to 100 items or less for performance and usability." `
        -InfoDescription "The report shows all nodes that have more than $maxCount direct descendants to allow you to address any potential issues arising. <br>
                          If the list is empty (no results shown) it means your solution is not even close to violating the recommendation and you can give yourself a pat on the back."

Close-Window
