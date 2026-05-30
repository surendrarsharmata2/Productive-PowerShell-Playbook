<#
    .SYNOPSIS
        Removes inactive user sessions after a specified amount of time.
    
    .NOTES
        Michael West
#>

$idleLimit = New-TimeSpan -Minutes 30
foreach($session in Get-Session) {
    $span = ([datetime]::UtcNow - $session.LastRequest)
    if($span -gt $idleLimit){
        Write-Log "Removing session for user $($session.UserName) after exceeding the idle time of $([math]::($idleLimit.TotalMinutes)) minutes. Current idle time is $([math]::Round($span.TotalMinutes)) minutes."
        $session | Remove-Session
    }
}
