Import-Function -Name Invoke-SqlCommand

$database = Get-Database -Name "master"

$connection = [Sitecore.Configuration.Settings]::GetConnectionString($database.Name)

$historyDays = [datetime]::Now.AddDays(-14)
$parameters = @{
    "date" = $historyDays
}

$query = "SELECT DISTINCT ItemID, Language FROM WorkflowHistory WHERE Date > @date"
$itemIds = Invoke-SqlCommand -Connection $connection -Query $query -Parameters $parameters | Select-Object -ExpandProperty "ItemId"

$reportItems = @()
foreach($itemId in $itemIds) {
    if($itemId) {
        $selectedItem = Get-Item -Path "master:" -ID ([Sitecore.Data.ID]::Parse($itemId))
        $workflowEvents = $selectedItem | Get-ItemWorkflowEvent | Where-Object { $_.Date -gt $historyDays -and $_.OldState -ne $_.NewState }
        
        foreach($workflowEvent in $workflowEvents) {
        
            $previousState = $null
            $currentState = $null
            if($workflowEvent.OldState) {
                $previousState = Get-Item -Path "master:" -ID $workflowEvent.OldState
            }
            
            if($workflowEvent.NewState) {
                $currentState = Get-Item -Path "master:" -ID $workflowEvent.NewState
            }
            $user = Get-User -Id $workflowEvent.User
            
            $comments = $null
            if($workflowEvent.CommentFields) {
                $comments = $workflowEvent.CommentFields["Comments"]
            }
            
            $reportItem = [pscustomobject]@{
                "User" = "$($user.Name)"
                "Date" = $workflowEvent.Date
                "OldState" = $previousState.Name
                "NewState" = $currentState.Name
                "Comments" = $comments
                "ID" = $selectedItem.ID
                "Name" = $selectedItem.Name
                "Icon" = $selectedItem.Appearance.Icon
            }

            $reportItems += $reportItem
        }
    }
}

$reportProperties = @{
    Property = @("Icon","Name","Date","OldState","NewState","User","Comments")
    Title = "Recent workflow history"
    InfoTitle = "Recent workflow history"
    InfoDescription = "View the most recent workflow history."
}

$reportItems | Show-ListView @reportProperties

Close-Window
