<#
	.NOTES
		Michael West
		Big thanks to kverheire for helping test against real content.
#>
$database = "master"
$root = Get-Item -Path (@{$true="$($database):\content\home"; $false="$($database):\content"}[(Test-Path -Path "$($database):\content\home")])
$settings = @{
   Title = "Report Filter"
   ShowHint = $true
   OkButtonName = "Proceed"
   CancelButtonName = "Abort"
   Description = "Filter the results for item renderings with personalization rules."
   Parameters = @(
       @{
           Name="root"
           Title="Choose the report root"
           Tooltip="Only items from this root will be returned."
           Root="/sitecore/content/"
       }
   )
   Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

$result = Read-Variable @settings
if($result -ne "ok") {
   Exit
}

$query = "$($root.ItemPath)//*[@__renderings='%<conditions%' or @#__Final Renderings#='%<conditions%']"
$items = @($root) + @((Get-Item -Path "master:" -Query $query))

function HasRuleOnRendering {
   param(
       [Sitecore.Layouts.RenderingDefinition]$Rendering
   )

   $hasRules = $false

   if($rendering -and ![string]::IsNullOrEmpty($rendering.Rules) ) {
       $hasRules = $true
   }

   $hasRules
}

$renderingLookup = @{}
$reportItems = [System.Collections.ArrayList]@()

$db = Get-Database -Name $database
foreach($item in $items) {
   $renderings = Get-Rendering -Item $item -FinalLayout
   foreach($rendering in $renderings) {
       if((HasRuleOnRendering -Rendering $rendering) -and ![string]::IsNullOrEmpty($rendering.ItemId)) {
           $renderingName = $rendering.ItemId.ToString()
           if($renderingLookup.ContainsKey($rendering.ItemId)) {
               $renderingName = $renderingLookup[$rendering.ItemId]
           } else {
               $renderingName = $db.GetItem($rendering.ItemId) | Select-Object -Expand Name
           }

           $datasource = $rendering.Datasource
           if([Sitecore.Data.ID]::IsID($datasource)) {
               $datasource = $db.GetItem($rendering.Datasource) | Select-Object -Expand Paths | Select-Object -Expand Path
           }

           $reportItem = [PSCustomObject]@{
               "Icon" = $item.Appearance.Icon
               "ItemPath" = $item.Paths.Path
               "Rendering" = $renderingName
               "Placeholder" = $rendering.Placeholder
               "Datasource" = $datasource
           }
           $reportItems.Add($reportItem) > $null
       }
   }
}

if($reportItems.Count -eq 0) {
   Show-Alert "There are no items matching the specified criteria."
} else {
   $reportProps = @{
       Title = "Item Renderings with Personalization Report"
       InfoTitle = "Renderings with personalization rules"
       InfoDescription = "This report provides details about which items have renderings configured with personalization rules."
   }

   $reportItems | Show-ListView @reportProps
}
Close-Window
