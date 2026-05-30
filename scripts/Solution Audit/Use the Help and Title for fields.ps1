<#
  How many of my template fields define Help and Title?
 
  Sitecore recommendation:
     Use the Help option in the individual field definition items to provide extra information to users about fields. 
     Also consider using the Title field of the definition item to present a different name for the field to the user.
 
  Before executing this script point the "Context Item" to where you store your solution templates e.g. "Sitecore/templates/My Site Templates"
 
  How to read this report?
  ------------------------
  The report will show you all template fields in your solution and whether or not they have User Friendly strings defined.
#>

$item = Get-Item -Path "master:\templates\user defined"
$props = @{
    Title = "Sitecore Recommendations:"
    Description = "<b>How many of my template fields define Help and Title? </b>Use the Help option in the individual field definition items to provide extra information to users about fields. Also consider using the Title field of the definition item to present a different name for the field to the user."
    Parameters = @(
        @{ Name = "item"; Title="Template branch to analyse"; Tooltip="Branch you want to analyse."; Root="/sitecore/templates"}
    )
    Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}
$result = Read-Variable @props

if($result -ne "ok") {
    Close-Window
    Exit
}

$fields = @($item) + @(($item.Axes.GetDescendants() | Initialize-Item)) | Where-Object { $_.TemplateName -eq "Template Field"};
    
$checks = $fields | Select-Object -Property Name, `
      @{Name="Template"; Expression={$_.Parent.Parent.Paths.Path -replace "/Sitecore/templates/", "" }}, `
      @{Name="Help Defined"; Expression={$_."__Long description" -ne "" -or $_."__Short description" -ne "" -or $_."__Help link" -ne "" }},
      @{Name="Title Specified"; Expression={$_.Title -ne "" }}

$has_no_title = $checks | Group-Object "Title Specified" | Where-Object {$_.Name -eq "False" } | Select-Object -Property Count
$has_no_help = $checks | Group-Object "Help Defined" | Where-Object {$_.Name -eq "False" } | Select-Object -Property Count

Write-host -f Yellow "Found $($fields.Count) template fields. $($has_no_title.Count) of those have no user friendly Title. $($has_no_help.Count) of those have no Help information defined."

$fields |
  where-object { $_."__Long description" -eq "" -or $_."__Short description" -eq "" -or $_."__Help link" -eq "" -or $_.Title -eq ""} | `
    Show-ListView -ViewName "HelpAndTitle" -Property DisplayName, 
        @{Name="Template"; Expression={$_.Parent.Parent.Paths.Path -replace "/Sitecore/templates/", "" }}, `
        Title, `
        @{Name="Short Description"; Expression={$_."__Long description" }}, `
        @{Name="Help Link"; Expression={$_."__Long description" }}, `
        @{Name="Long Description"; Expression={$_."__Long description" }} `
        -Title "Template fields not providing user friendly information." `
        -InfoTitle "Sitecore recommendation:" `
        -InfoDescription "Use the Help option in the individual field definition items to provide extra information to users about fields. <br/>
                          Also consider using the Title field of the definition item to present a different name for the field to the user. <br/><br/>
                          Fields below fail to deliver on this recomendation."
