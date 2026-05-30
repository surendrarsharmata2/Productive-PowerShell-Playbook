<#
    This report will display all custom powershell commands made for Sitecore. 
    
    .NOTES
        In order to get help to format correctly you must allow remote script. 
        Step 1 : Open Windows PowerShell with elevated privileges.
        Step 2 : Run Set-ExecutionPolicy -ExecutionPolicy RemoteSigned. Enter Y. 
    
    http://blog.najmanowicz.com/2011/11/18/sample-scripts-for-sitecore-powershell-console/
#>


$cmds = Get-Command | Where-Object { $_.ModuleName -eq "" -and $_.CommandType -eq "cmdlet" } | % { Get-Help $_.Name | Select-Object -Property Name, Synopsis } | Sort-Object -Property Name

$props = @{
    Title = "Sitecore PowerShell Commands"
    InfoTitle = "Sitecore PowerShell Commands"
    InfoDescription = "Lists the Sitecore PowerShell commands"
    PageSize = 25
}

$cmds | Show-ListView @props -Property Name, Synopsis

Close-Window
