<# 
  Do my items assign rights to users?
 
  Sitecore recommendation:
     Apply security to roles rather than users — 
       We recommend that you configure security rights for a role security account rather than a user account. 
       Even if there is only one user in the system with this unique access level, 
       it is still better to have permissions configured for a role account. 
       It is much easier to maintain a security system in which all the security configuration is set on role security accounts.
 
  Before executing this script point the "Context Item" to where you store your solution templates e.g. "/sitecore/content/My Site"
 
  How to read this report?
  ------------------------
  The report will show you all items that restrict rights rather than break inheritance, potantially breaking this recommendation.
  It does not necessarily mean that the approach is wrong, but you should consider restructuring your security setting 
  according to the Sitecore best practice.
#>

$item = Get-Item -Path "master:\"
$icon ="OfficeWhite/32x32/shield.png"
$result = Read-Variable -Parameters `
    @{ Name = "item"; Title="Analyse subitems of"; Tooltip="Branch you want to analyse."} `
    -Description "This report will analyse the branch and will tell you which items have security set at a user level rather than role level." `
    -Title "Find items with security set for a user instead of role" -Width 600 -Height 200 `
    -OkButtonName "Proceed" -CancelButtonName "Abort" -Icon $icon

if($result -ne "ok") {
    Close-Window
    Exit
}

@($item) + @(($item.Axes.GetDescendants() | Initialize-Item))  |
    Where-Object { $_.__Security -match "au\|" } |
    Show-ListView -Property `
        @{Name="Item assigning rights to users"; Expression={$_.ItemPath}}, `
        @{Name="Security setting"; Expression={$_.__Security}} `
        -Title "Items with rights assigned to a user"

Close-Window
