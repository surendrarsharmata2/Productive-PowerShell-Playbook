# Export Users and Roles
# Useful for migrations and audits.

$users = Get-User

$result = foreach($user in $users)
{
    [PSCustomObject]@{
        UserName = $user.Name
        IsAdministrator = $user.IsAdministrator
        Roles = ($user.RolesInRoles | ForEach-Object {$_.Name}) -join ";"
    }
}

$result | Export-Csv "C:\Temp\Users.csv" -NoTypeInformation
