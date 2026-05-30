<#
    Adapted from:
    http://www.sitecore.net/Learn/Blogs/Technical-Blogs/John-West-Sitecore-Blog/Posts/2012/12/Automatically-Show-the-Quick-Info-Section-in-the-Content-Editor-of-the-Sitecore-ASPNET-CMS.aspx
#>

$pipelineArgs = Get-Variable -Name pipelineArgs -ValueOnly
$username = $pipelineArgs.UserName

$user = Get-User -Identity $username -Authenticated
$domain = Get-Domain -Name "sitecore"

if($user.Domain -ne $domain.Name -or $user.Name -eq $domain.AnonymousUserName) {
    Write-Log "Unexpected domain or user: $($user.Name)" -Log Warning
    return
}

$key = "/" + $username + "/UserOptions.ContentEditor.ShowQuickInfo"
if([System.String]::IsNullOrEmpty($user.Profile[$key])) {
    Write-Log "Configuring the ShowQuickInfo to be visible."
    $user.Profile[$key] = "true"
    $user.Profile.Save()
}
