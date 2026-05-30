$runScript = Show-Confirm "This script might take a long while on a larger branches - are you sure you want to run this script?"

Set-HostProperty -HostWidth 60

if($runScript -eq "yes"){
    $props = @{
        Property = @(
            "Name",
            @{Label="Items Updated"; Expression={$_.count}},
            @{Label="Icon"; Expression={ [Sitecore.Security.Accounts.User]::FromName("$($_.name)", $false).Profile.Portrait } }
        )
        Modal = $true
        Width = 790
        Height = 600
        Title = "Author Statistics"
    }
    
    $root = Get-Item -Path "."
    @($root) + @(($root.Axes.GetDescendants() | Initialize-Item))  | 
        Group-Object -Property "__Updated By" |
        Sort-Object -Property count -Descending |
        Show-ListView @props
    Close-Window
} else {
  Close-Window
}
