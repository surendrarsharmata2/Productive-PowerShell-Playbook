$settings = @{
    Title = "Lock Transfer"
    Width = "450"
    Height = "250"
    OkButtonName = "Proceed"
    CancelButtonName = "Abort"
    Description = "Select the new lock owner."
    Parameters = @(
        @{ Name = "userNewLockOwner"; Title="New User"; Editor="user"; }
    )
    Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

$result = Read-Variable @settings
if($result -ne "ok") {
    Exit
}

$userNewLockOwner = $userNewLockOwner[0]

foreach($selectedItem in $selectedData) {
    $item = Get-Item -Path "master:" -ID $selectedItem.ID
    $userLockOwner = $item.Locking.GetOwner()
    $item."__Lock" = $item."__Lock".Replace("$userLockOwner","$userNewLockOwner")

    $allData.Remove($selectedItem)
}

$allData | Update-ListView
