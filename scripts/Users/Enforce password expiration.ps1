<#
    Adapted from:
    http://sitecorejunkie.com/2013/06/08/enforce-password-expiration-in-the-sitecore-cms/
#>

$pipelineArgs = Get-Variable -Name pipelineArgs -ValueOnly
$username = $pipelineArgs.UserName

$user = Get-User -Identity $username

if($user.IsAdministrator) { 
    Write-Log "The user $($username) is an administrator. Skipping password expiration check."
    return
}

$membershipUser = [System.Web.Security.Membership]::GetUser($username)

$expireTimeSpan = [timespan]"90:00:00:00"
$difference = [datetime]::Today - $membershipUser.LastPasswordChangedDate.Add($expireTimeSpan)
if($difference.Days -ge 0) {
    Write-Log "The password for $($username) has expired. Enforcing password update policy."
    $changePassUrl = "/sitecore/login/changepassword.aspx"
    [Sitecore.Web.WebUtil]::Redirect($changePassUrl)
} else {
    Write-Log "The password for $($username) expires in $($difference.Days) days."
}
