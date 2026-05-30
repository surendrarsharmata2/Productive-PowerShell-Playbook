<#
  Which of my Templates use TreeList fields?
 
  Sitecore recommendation:
     Use TreelistEx instead of Treelist when showing very big trees — like the Home node and its descendants — 
     or have lots of Treelist fields in one single item. TreelistEx only computes the tree 
     when you click Edit whereas a Treelist will compute it every time it is rendered.
 
  Before executing this script point the "Context Item" to where you store your solution templates e.g. "Sitecore/templates/My Site Templates"
#>

$item = Get-Item -Path "master:\templates"
$icon =[regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$result = Read-Variable -Parameters `
    @{ Name = "item"; Title="Template branch to analyse"; Tooltip="Branch you want to analyse."; Root="/sitecore/templates"} `
    -Description "Sitecore recommendation: Use TreelistEx instead of Treelist when showing very big trees — like the Home node and its descendants" `
    -Title "Which of my templates use TreeList fields?" -Width 500 -Height 280 `
    -OkButtonName "Proceed" -CancelButtonName "Abort" -Icon $icon

if($result -ne "ok") {
    Close-Window
    Exit
}

@($item) + @(($item.Axes.GetDescendants() | Initialize-Item)) |
  Where-Object { $_.TemplateName -eq "Template Field" -and $_.Type -eq "Treelist" } |  `
    Show-ListView -Property Name, @{Name="Template"; Expression={$_.Parent.Parent.Paths.Path -replace "/Sitecore/templates/", "" }}, `
        @{Name="Source"; Expression={$_._Source }} `
        -Title "Templates using TreeList fields" `
        -InfoTitle "Sitecore recommendation:" `
        -InfoDescription "Use TreelistEx instead of Treelist when showing very big trees — like the Home node and its descendants — 
                          or have lots of Treelist fields in one single item. TreelistEx only computes the tree
                          when you click Edit whereas a Treelist will compute it every time it is rendered. <br/><br/>
                          This report shows which of your templates use TreeList fields."
Close-Window
