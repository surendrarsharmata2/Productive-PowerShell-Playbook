<#
  Do my tree/list/link selection fields narrow selection?
 
  Sitecore recommendation:
     Use the special syntax to restrict the results on Treelists, DropTrees, and TreelistEx 
     to make sure users can only select the appropriate items, or Sitecore query in the other selection fields.
 
  Before executing this script point the "Context Item" to where you store your solution templates e.g. "Sitecore/templates/My Site Templates"
 
  How to read this report?
  ------------------------
  The report will show you all template fields in your solution and whether or not they define the Source query.
  Just because a field does not define source, doesn't mean it's a problem, but this report allows you to have a view on all of them and decide whether you can improve your user experience.
#>

$item = Get-Item -Path "master:\templates"
$icon =[regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$result = Read-Variable -Parameters `
    @{ Name="item"; Title="Template branch to analyse"; Tooltip="Branch you want to analyse."; Root="/sitecore/templates"}, `
    @{ Name="showAll"; Value=$false; Title="Include items even if they define their source"; Tooltip="Include items with Source defined.";} `
    -Title "Sitecore recommendation:" `
    -Description "Use the special syntax to restrict the results on Treelists, DropTrees, and TreelistEx 
            to make sure users can only select the appropriate items, or Sitecore query in the other selection fields." -Width 500 -Height 280 `
    -OkButtonName "Proceed" -CancelButtonName "Abort" -Icon $icon

if($result -ne "ok") {
    Close-Window
    Exit
}

@($item) + @(($item.Axes.GetDescendants() | Initialize-Item)) |
  Where-Object { $_.TemplateName -eq "Template Field" } |
  Where-Object { $_.Type -match "Drop" -or $_.Type -match "Tree" -or $_.Type -match "list"  } |
  Where-Object { $_._Source -eq "" -or $showAll } |
    Show-ListView -Property Name, Type, `
        @{Name="Template"; Expression={$_.Parent.Parent.Paths.Path -replace "/Sitecore/templates/", ""}}, `
        @{Name="Source"; Expression={$_._Source}}, `
        @{Name="Icon"; Expression={if($_._Source -eq "") {"Office/32x32/checkbox_unselected.png"} else {"Office/32x32/checkbox_selected.png"} }} `
        -Title "Use special tree syntax" `
        -InfoTitle "Sitecore recommendation:" `
        -InfoDescription "Use the special syntax to restrict the results on Treelists, DropTrees, and TreelistEx to make sure users can only select the appropriate items, or Sitecore query in the other selection fields. <br/>
                          The report will show you all link template fields in your solution and whether or not they define the Source query.Just because a field does not define source, doesn't mean it's a problem, but this report allows you to have a view on all of them and decide whether you can improve your user experience."

