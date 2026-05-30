<#
    .SYNOPSIS
        Lists all aliases and their linked items
        
    .NOTES
        Adam Najmanowicz
        Adapted from Stack Overflow answer by Derek Hunziker.
        [http://stackoverflow.com/questions/38340617/sitecore-powershell-find-users-last-login]
#>

$props = @{
    Title = "Recently logged in users"
    InfoTitle = "Recently logged in users"
    InfoDescription = "Details about users that have logged in recently."
    PageSize = 25
    Property = @(
        @{Label="Icon"; Expression={ 
            if ($_.IsLockedOut){ "Office/32x32/lock.png"} 
            elseif (-not ($_.IsApproved)){ "Office/32x32/dude5.png"}
            elseif($_.IsOnline -and $_.IsAdministrator) { "Office/32x32/astrologer.png" }
            elseif($_.IsOnline) { "Office/32x32/businessperson.png" } 
            else {"Office/32x32/clock.png"}}},
        @{Label="User"; Expression={ $_.UserName} },
        @{Label="Is Online"; Expression={ $_.IsOnline} },
        @{Label="Is Locked Out"; Expression={ $_.IsLockedOut} },
        @{Label="Is Disabled"; Expression={ -not $_.IsApproved} },
        @{Label="Is Administrator"; Expression={ $_.IsAdministrator } },
        @{Label="Last Activity Date"; Expression={ $_.LastActivityDate } },
        @{Label="Last Login Date"; Expression={ $_.LastLoginDate} },
        @{Label="Creation Date"; Expression={ $_.CreationDate} }
    )
}

$users = [System.Web.Security.Membership]::GetAllUsers()
foreach($user in $users) {
    Add-Member -InputObject $user -MemberType NoteProperty -Name "IsAdministrator" -Value (Get-User -Id $user.UserName).IsAdministrator
}
$users | Sort-Object -Property LastActivityDate -Descending | Show-ListView @props
        
Close-Window

