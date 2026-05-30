<#
    .SYNOPSIS
        Lists all content items that contain one of the following tokens in at least one field - $name, $date, $parentname, $time, $now, $id, $parentid
        
    .NOTES
        Alex Washtell
#>
# Create a list of field names on the Standard Template. This will help us filter out extraneous fields.
$standardTemplate = Get-Item -Path "master:" -ID ([Sitecore.TemplateIDs]::StandardTemplate.ToString())
$standardTemplateTemplateItem = [Sitecore.Data.Items.TemplateItem]$standardTemplate
$standardFields = $standardTemplateTemplateItem.OwnFields + $standardTemplateTemplateItem.Fields | Select-Object -ExpandProperty key -Unique

filter Where-TokenInFields {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Sitecore.Data.Items.Item]$item,
        
        [string[]]$ExcludedFieldNames,
        
        [bool]$ReadAllFields
    )
    
    if($ReadAllFields) {
        $item.Fields.ReadAll()
    }
    
    $tokenPatterns = [regex]'\$name|\$date|\$parentname|\$time|\$now|\$id|\$parentid'
    foreach ($field in $item.Fields | Where-Object { !$ExcludedFieldNames -or $ExcludedFieldNames -notcontains $_.Name })
    {
        $foundMatches = $tokenPatterns.Matches($field.Value)
        if ($foundMatches -and $foundMatches.Count -gt 0) {
            # Return custom object so we can include both the item and the field in the report
            $foundTokens = $foundMatches.Value -join ','
            @{Item = $item; Field = $field; Token = $foundTokens}
        }
    }
}

$options = [ordered]@{"Include blank and Standard Value fields"=1;"Include Standard Template fields"=2;}
$database = "master"
$root = Get-Item -Path (@{$true="$($database):\content\home"; $false="$($database):\content"}[(Test-Path -Path "$($database):\content\home")])
$props = @{
    Parameters = @(
        @{Name="root"; Title="Choose the report root"; Tooltip="Only items in this branch will be returned.";}
        @{Name="selectedOptions"; Value=1; Title="Additional Options"; Tooltip="Use these to apply additional filtering. May run faster."; Options=$options; Editor="checklist";}
    )
    Title = "Report Filter"
    Description = "Choose the criteria for the report."
    ShowHints = $true
    Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

$result = Read-Variable @props

if($result -eq "cancel"){
    exit
}

$tokenOptions = @{}
if($selectedOptions -contains 1) {
    $tokenOptions["ReadAllFields"] = $true
}
if($selectedOptions -notcontains 2) {
    $tokenOptions["ExcludedFieldNames"] = $standardFields
}

$items = @($root) + @(($root.Axes.GetDescendants() | Initialize-Item)) | Where-TokenInFields @tokenOptions

if($items.Count -eq 0) {
    Show-Alert "There are no content items that have tokens in fields"
} else {
    $props = @{
        Title = "Item Field Token Report"
        InfoTitle = "Content items with tokens in fields"
        InfoDescription = 'Lists all content items that contain one of the following tokens in at least one field - $name, $date, $parentname, $time, $now, $id, $parentid.'
        PageSize = 25
    }
    
    $items |
        Show-ListView @props -Property @{Label="Icon"; Expression={$_.Item.__Icon} },
            @{Label="Name"; Expression={$_.Item.DisplayName} },
            @{Label="Field Name"; Expression={$_.Field.Name} },
            @{Label="Tokens"; Expression={$_.Token} },
            @{Label="Updated"; Expression={$_.Item.__Updated} },
            @{Label="Updated by"; Expression={$_.Item."__Updated by"} },
            @{Label="Created"; Expression={$_.Item.__Created} },
            @{Label="Created by"; Expression={$_.Item."__Created by"} },
            @{Label="Path"; Expression={$_.Item.ItemPath} }
}

Close-Window
