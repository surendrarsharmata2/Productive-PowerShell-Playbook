<#
    .SYNOPSIS
        Restore items in the recycle bin and show in a report.
        
    .LINK
        https://gist.github.com/technomaz/58890edff903123083c77ad8f1b1b2e2
        
    .NOTES
        Michael West
        Adapted from Mark Mazelin's script to restore items from the recycle bin.
#>

$availableArchives = Get-Archive -Name "recyclebin"
$options = $availableArchives | ForEach-Object { $o = [ordered]@{} } { $o[$_.Database.Name] = $_.Database.Name } { $o }

$selectedDatabaseName = "master"
$selectedDate = [datetime]::Today.AddDays(-1)
$dryRun = $true
$props = @{
    Parameters = @(
        @{Name="selectedDatabaseName"; Title="Database"; Tooltip="Each database contains a recyclebin"; Options=$options; }
        @{Name="selectedUser"; Title="User"; Tooltip="User responsible for archiving the items."; Editor="user"; },
        @{Name="selectedDate"; Title="Date"; Tooltip="Restore all items between this date and now"; Editor = "date" }
        @{Name="dryRun"; Title="Dry Run"; Tooltip="When selected the items will remain in the recyclebin"; }
    )
    Title = "Bulk Item Restorer"
    Icon = "OfficeWhite/32x32/undo.png"
    Description = "Choose the database and how far back to restore."
    ShowHints = $true
}

$result = Read-Variable @props
if($result -ne "ok") {
    exit
}

if($dryRun) {
    Write-Host "Running in dry run mode" -ForegroundColor Yellow
}
Write-Host "Restoring items recycled after $($selectedDate.ToShortDateString())"

$restoredItems = [System.Collections.ArrayList]@()
foreach($archive in $availableArchives | Where-Object { $_.Database.Name -eq $selectedDatabaseName }) {
    $database = $archive.Database
    Write-Host "- Found $($archive.GetEntryCount()) entries in the $($database.Name) database"
    $filterByUser = ![string]::IsNullOrEmpty($selectedUser)
    $entries = Get-ArchiveItem -Archive $archive | Where-Object { $_.ArchiveLocalDate -ge $selectedDate -and (!$filterByUser -or $_.ArchivedBy -eq $selectedUser) }
    if(!$entries) {
       Write-Host "- No matching entries found" -ForegroundColor Yellow 
    }
    
    foreach($entry in $entries) {
        $itemId = $entry.ItemId
        Write-Host "- [R] $($entry.ArchiveLocalDate) $($itemId) $($entry.OriginalLocation)" -ForegroundColor Yellow
        if(!$dryRun) {
            $restored = $archive.RestoreItem($entry.ArchivalId)
            $item = Get-Item -Path "$($database.Name):" -ID $itemId
            if($restored -and $item) {
                $restoredItems.Add($item) > $null
            }
        }
    }
}

if(!$dryRun) {
    $props = @{
        Title = "Bulk Item Restorer Report"
        InfoTitle = "Items restored from the recycle bin"
        InfoDescription = "Restored items were recycled as far back as $($selectedDate.ToString('yyyy-MM-dd'))."
        PageSize = 50
    }
    $restoredItems | Show-ListView @props
    Close-Window
} else {
    Show-Result -Text
}
