<#
    Based on Blog by @Techphoria414 - Nick Wesselman
    http://www.techphoria414.com/Blog/2012/September/Use_Sitecore_Powershell_to_Find_Templates_with_Layout
#>

$layout = Get-Item -Path "master:\layout\Layouts\Sample Layout"
$icon =[regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$dialogProps = @{
    Title = "Layout Usage"
    OkButtonName = "Find"
    CancelButtonName = "Abort"
    Icon = $icon
    Description = "This report analyses all of the templates with a reference to the specified layout."
    Parameters = @(
        @{ Name = "layout"; Title="Layout"; Root="/sitecore/layout/Layouts/"; Tooltip="Layout you want to find."}
    )
}
$result = Read-Variable @dialogProps

if($result -ne "ok") {
    Exit
}

$items = Get-ItemReferrer -Item $layout | Where-Object { $_.ItemPath.StartsWith("/sitecore/templates") }
if($items.Count -eq 0) {
    Show-Alert "There are no items matching the specified criteria."
} else {
    $props = @{
        Title = "Layout Usage Report"
        InfoTitle = "Layout usage for each template"
        InfoDescription = "The report shows all Standard Values items with a reference to the $($layout.Name) layout."
        Property = @(
            @{Label="Name"; Expression={$_.DisplayName} },
            @{Label="Updated"; Expression={$_.__Updated} },
            @{Label="Updated by"; Expression={$_."__Updated by"} },
            @{Label="Created"; Expression={$_.__Created} },
            @{Label="Created by"; Expression={$_."__Created by"} },
            @{Label="Path"; Expression={$_.ItemPath} }
        )
    }
    
    $items | Show-ListView @props
}
Close-Window
