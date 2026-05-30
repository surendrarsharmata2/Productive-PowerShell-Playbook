<# 
  Do my items restrict access rights?
 
  Sitecore recommendation:
     Break inheritance rather than explicitly deny access rights — 
       It is a recommended practice to break inheritance in cases where the access right should be denied 
       instead of explicitly denying it for a security account. If you deny an access right explicitly to a security account, 
       the only way to override this denial of access is to do it directly on a user account. 
       This creates an overhead in security management when you would like a user to inherit this role and some other role 
       that should allow the same right access.
 
  Before executing this script point the "Context Item" to where you store your solution templates e.g. "/sitecore/content/My Site"
 
  How to read this report?
  ------------------------
  The report will show you all items that restrict rights rather than break inheritance, potentially breaking this recommendation.
  It does not necessarily mean that the approach is wrong, but you should consider restructuring your security setting 
  according to the Sitecore best practice.
#>

$item = Get-Item -Path "master:\"
$icon =[regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$result = Read-Variable -Parameters `
    @{ Name = "item"; Title="Analyse subitems of"; Tooltip="Branch you want to analyse."} `
    -Description "This report will analyse the branch and will tell you which items restrict rights to fields or themselves." `
    -Title "Find items with security set for a user instead of role" -Width 525 -Height 280 `
    -OkButtonName "Proceed" -CancelButtonName "Abort" -Icon $icon

if($result -ne "ok") {
    Close-Window
    Exit
}

@($item) + @(($item.Axes.GetDescendants() | Initialize-Item)) | `
  Where-Object { $_.__Security -match "-item"  -or $_.__Security -match "-field" } |  `
    Show-ListView -Property `
        @{Name="Item restricting right"; Expression={$_.ItemPath}}, `
        @{Name="Security setting"; Expression={$_.__Security}} `
        -Title "Items that restrict rights"

Close-Window
