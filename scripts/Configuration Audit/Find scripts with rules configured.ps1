<#
    .SYNOPSIS
        Report all the PowerShell Script (Library) items which contain a ShowRule or EnableRule
        
    .NOTES
        Michael West
#>

$items = Get-ChildItem -Path "master:" -ID "{A3572733-5062-43E9-A447-54698BC1C637}" -Recurse |
    Where-Object { $_.TemplateID -eq "{AB154D3D-1126-4AB4-AC21-8B86E6BD70EA}" -or $_.TemplateID -eq "{DD22F1B3-BD87-4DB2-9E7D-F7A496888D43}" } |
    Where-Object { (![string]::IsNullOrEmpty($_.ShowRule) -and $_.ShowRule -ne "<ruleset />") -or (![string]::IsNullOrEmpty($_.EnableRule) -and $_.EnableRule -ne "<ruleset />") }

function Render-Rule {
    param(
        [string]$rule
    )
    
    if([string]::IsNullOrEmpty($rule) -or $rule -eq "<ruleset />") {
        return $null
    }
    
    $output = New-Object System.Web.UI.HtmlTextWriter (New-Object System.IO.StringWriter)
    $renderer = New-Object Sitecore.Shell.Applications.Rules.RulesRenderer ($rule)
    $renderer.Render($output)
    $output.InnerWriter.ToString()
}

$reportProps = @{
    Title = "PowerShell scripts with rules"
    InfoTitle = "PowerShell scripts with rules configured"
    InfoDescription = "PowerShell scripts and script libraries where the ShowRule or EnableRule are configured."
    Property = @("Name","ItemPath",@{Name="ShowRule";Expression={Render-Rule -Rule $_.ShowRule}}, @{Name="EnableRule";Expression={Render-Rule -Rule $_.EnableRule}})
}

$items | Show-ListView @reportProps
Close-Window
