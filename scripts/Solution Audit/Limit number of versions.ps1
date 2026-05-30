<#
  Which of my items have most children? Are there too many?
 
  Sitecore recommendation:
     Limit the number of versions of any item to the fewest possible. 
     Sitecore recommends keeping 10 or fewer versions on any item, but policy may dictate this to be a higher number. 
 
  Before executing this script point the "Context Item" to your site e.g. "Sitecore/content/My Site"
 
  How to read this report?
  ------------------------
  The report will show you all the nodes that have more than 10 versions. 
  If the list is empty (no results shown) it means your solution is not violating the recommendation and you can give yourself a pat on the back.
#>

$item = Get-Item -Path "master:\content"

$dialogProps = @{
    Parameters = @(
        @{ Name = "item"; Title="Branch to analyse"; Tooltip="Branch you want to analyse."; Root="/sitecore/"},
        @{ Name = "count"; Value=10; Title="Show if over this number of versions"; Tooltip="Show if over this number of versions."; Editor="number"}
    )
    Title = "Limit item version count"
    Description = "Sitecore recommends keeping 10 or fewer versions on any item, but policy may dictate this to be a higher number."
    Width = 500
    Height = 280
    OkButtonName = "Proceed"
    CancelButtonName = "Abort"
    Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

$result = Read-Variable @dialogProps 

if($result -ne "ok") {
    Close-Window
    Exit
}

$items = @($item) + @(($item.Axes.GetDescendants())) | 
    Where-Object { $_.Versions.Count -gt $count } | 
    Initialize-Item |
    Sort-Object -Property @{Expression={$_.Versions.Count}; Descending=$true}

$reportProps = @{
    Property = @(
        "DisplayName",
        @{Name="Versions"; Expression={$_.Versions.Count}},
        @{Name="Path"; Expression={$_.ItemPath}}
    )
    Title = "Which of my items have the most versions?"
    InfoTitle = "Sitecore recommendation: Limit the number of versions of any item to the fewest possible."
    InfoDescription = "The report shows all items that have more than <b>$count versions</b> to allow you to address any potential issues arising. Sitecore recommends keeping 10 or fewer versions on any item, but policy may dictate this to be a higher number.  <br> <br> Use the command <b>Remove-ItemVersion</b> to remove unnecessary versions in your scripts."
}

$items | Show-ListView @reportProps
Close-Window
