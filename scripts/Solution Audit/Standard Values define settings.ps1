<#
  How many of my templates define standard values? Which of those SVs define the desired properties from the Sitecore recommendation?
 
  Sitecore recommendation:
     _Standard Values — Define layout details, initial workflow, and insert options to a template. 
     This reduces administration and centrally manages system settings, rather than setting them on individual items.
 
  Before executing this script point the "Context Item" to where you store your solution templates e.g. "Sitecore/templates/My Site Templates"
 
  How to read this report?
  ------------------------
  The report will show you all templates in your solution that have no __Standard Values in the first list.
  Such templates cannot even begin to adhere to this practice as the required settings are set on __Standard Values.
  the second List will show you templates with standard values and will show whether those SV's define renderings, Insert Options, Insert Rules or have renderings defined.
  Just because SV does not define one or more of those values, doesn't mean it's a problem, but this report allows you to have a view on all of them and decide whether you can improve your user experience.
#>

$prompt = @{
    Parameters = @{
        Name = "item"
        Title = "Template branch to analyse"
        Tooltip = "Branch you want to analyse."
        Root = "/sitecore/templates"
    }
    Title = "Sitecore __Standard Values recommendation"
    Description = "How many of my templates define standard values? Which of those SVs define the desired properties from the Sitecore recommendation?"
    Height = 280
    Width = 500
    OkButtonName = "Proceed"
    CancelButtonName = "Abort"
    Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

$item = Get-Item master:\templates
$result = Read-Variable @prompt

if($result -ne "ok") {
    Close-Window
    Exit
}

$templates = @($item) + @(($item.Axes.GetDescendants() | Initialize-Item)) | Where-Object { $_.TemplateName -eq "Template" }

$template_sv = $templates |
    Select-Object @{Name="Template"; Expression={ $_.ItemPath -replace "/Sitecore/templates/", "" }}, 
        @{Name="_SV"; Expression={$_.Children["__Standard Values"] -ne $null }}    

$has_sv = $template_sv | Group-Object _SV | Where-Object { $_.Name -eq "True" } | Select-object Count
$has_no_sv = $template_sv | Group-Object _SV | Where-Object { $_.Name -eq "False" } | Select-object Count
Write-Host -f Yellow "Found $($has_sv.Count + $has_no_sv.Count) templates. $($has_no_sv.Count) of those have no Standard Values defined."

$props = @{
    Property = "Name", @{Name="Standard Values"; Expression={$_.Children["__Standard Values"] -ne $null}},
        @{Name="Default Workflow"; Expression={$_.Children["__Standard Values"]["__Default Workflow"] -ne ""}},
        @{Name="Insert Options";   Expression={$_.Children["__Standard Values"]["__masters"] -ne ""}},
        @{Name="Insert Rules";     Expression={$_.Children["__Standard Values"]["__Insert Rules"] -ne ""}},
        @{Name="Has Renderings";   Expression={$_.Children["__Standard Values"]["__Renderings"] -ne "" }},
        @{Name="Path";             Expression={ $_.Paths.Path -replace "/Sitecore/templates/", ""}}
    Title = "Standard values recommendations compliance."
    InfoTitle = "Sitecore recommendation:"
    InfoDescription = "<i>__Standard Values</i> - Define layout details, initial workflow, and insert options to a template. This reduces administration and centrally manages system settings, rather than setting them on individual items.<br/><br/>
                          Found <b>$($template_sv.Count)</b> templates. <b>$($has_no_sv.Count)</b> of those have no <i>__Standard Values</i> defined, while the remaining <b>$($has_sv.Count)</b> do.<br/>
                          Templates that do not define <i>__Standard Values</i> cannot even begin to adhere to this practice as the required settings are set on <i>__Standard Values</i>.<br/>
                          For the templates that have standard values defined you can see  whether those SV's define renderings, Insert Options, Insert Rules or have renderings defined.<br/>
                          Lack of <i>__Standard Values</i>, doesn't mean it's a problem, but this report allows you to have a view on all of them and decide whether you can improve your user's experience."
}

$templates | Show-ListView @props
Close-Window
