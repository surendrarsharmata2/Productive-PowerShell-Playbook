foreach($session in $selectedData){
    [Sitecore.Web.Authentication.DomainAccessGuard]::Kick($session.SessionID);
}

Get-Session | Update-ListView
