<#
	.SYNOPSIS
		Lists the items with broken links searching all or the latest version in the current language.

    .DESCRIPTION
        The following report lists items with broken links.
        
        * Supports checking internal links
		* Ability to ignore checking broken links in the renderings field. (Makes sense in come clone scenarios)
		* Supports checking external links of field type "General Link with Search"
		* Supports checking external protocol independent links (URL's starting with //)
		* Supports checking external links of field type "Rich Text"

	.NOTES
		Adam Najmanowicz, Michael West, Daniel Scherrer, Mikael Högberg
		Adapted from the Advanced System Reporter module & Daniel Scherrer's external links checker: 
		https://gist.github.com/daniiiol/143db3e2004afe9a55c1dd3e33048940
		
		Updated with improvements found here:
		https://gist.github.com/mikaelnet/9d4345d73db257e1e81c3bc9ebd8280c
#>

$database = "master"
$root = Get-Item -Path (@{$true="$($database):\content\home"; $false="$($database):\content"}[(Test-Path -Path "$($database):\content\home")])
$linksToCheck =  @("internal")
$linkTypes = [ordered]@{"Internal Links"="internal";"External Links"="external";"Renderings"="renderings"};

$versionOptions = [ordered]@{
	"Latest"="1"
}

$props = @{
	Parameters = @(
		@{Name="root"; Title="Choose the report root"; Tooltip="Only items in this branch will be returned."; Columns=9},
		@{Name="searchVersion"; Value="1"; Title="Version"; Options=$versionOptions; Tooltip="Choose a version."; Columns="3"; Placeholder="All"},
		@{Name="linksToCheck"; Title="Link types to check"; Options=$linkTypes; Tooltip="Link types you want to check"; Editor="checklist"} 
	)
	Title = "Broken Links Report"
	Description = "Choose the criteria for the report."
	Width = 550
	Height = 300
	ShowHints = $true
	Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

$result = Read-Variable @props

if($result -eq "cancel"){
	exit
}

filter HasBrokenLink {
	param(
		[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[Sitecore.Data.Items.Item]$Item,
		
		[Parameter()]
		[bool]$IncludeAllVersions
	)
	
	if(!$Item) { return }
	if($linksToCheck.Contains("internal")) {
		$brokenLinks = $item.Links.GetBrokenLinks($IncludeAllVersions)
		if($brokenlinks -ne $null -and $brokenlinks.Length -gt 0) {
			$finalRenderings = Get-Rendering -Item $Item -FinalLayout
			$sharedRenderings = Get-Rendering -Item $Item
			$uniqueIdLookup = New-Object System.Collections.Generic.HashSet[string]
			foreach($brokenLink in $brokenLinks) {
				if([Sitecore.Data.ID]::IsNullOrEmpty($brokenLink.SourceFieldID)) { continue }
				$fieldItem = Get-Item -Path "$($Item.Database.Name):\" -ID $brokenLink.SourceFieldID
				if(!$fieldItem) { continue }
				$renderings = & {
					switch($fieldItem.ID) {
						"{04BF00DB-F5FB-41F7-8AB7-22408372A981}" {
							$finalRenderings
						}
						default {
							$sharedRenderings
						}
					}
				}
				$brokenRendering = $renderings | Where-Object { $_.Datasource -eq $brokenLink.TargetPath -and !$uniqueIdLookup.Contains($_.UniqueId) } | Select-Object -First 1
				if(!$brokenRendering -or !$linksToCheck.Contains("renderings")) { continue }
				$uniqueIdLookup.Add($brokenRendering.UniqueId) > $null
				$brokenRenderingItem = Get-Item -Path "master:" -ID $brokenRendering.ItemId
				$brokenItem = [pscustomobject]@{
					"ID"=$Item.ID
					"Icon"=$Item.__Icon
					"DisplayName"=$Item.DisplayName
					"ItemPath"=$Item.ItemPath
					"Version"=$Item.Version
					"Language"=$Item.Language
					"__Updated"=$Item.__Updated
					"__Updated by"=$Item."__Updated by"
					"Link Field"=$fieldItem.Name
					"Rendering" = $brokenRenderingItem.Name
					"Placeholder" = $brokenRendering.Placeholder
					"Target Path"=$brokenLink.TargetPath
					"Status Code"="Missing Target Item"
					"BrokenLink"=$brokenLink
					"Link Type" = "Internal"
				}

				$brokenItem
				
			}
		}
	}
	
	if($linksToCheck.Contains("external")){
		if($IncludeAllVersions){
			$allItems = Get-Item "$($item.Database.Name):" -Version * -Language * -Id $item.Id
		} else {
			$allItems = @(Get-Item "$($item.Database.Name):" -Language * -Id $item.Id)
		}
		foreach($checkedItem in $allItems){
			foreach($field in $checkedItem.Fields) {
				$urls = @()
				if ($field.TypeKey -like 'general link*' -and $field.Value -like '*linktype="external"*') { 
					$found = $field.Value -match '.*url="(.*?)".*'
					if($found) {
						$url = $matches[1]
						if ($url.StartsWith('//')) {
							$url = 'http:{0}' -f $url
						}
						$urls += $url
					}
				}
				if ($field.TypeKey -like 'rich text') { 
					$field.Value | Select-String '\shref="([^"]+)"' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object {
						$match = $_
						$url = $match.Groups[1].Value
						if ($url.StartsWith('//')) {
							$url = 'http:{0}' -f $url
						}
						if ($url.StartsWith('http://') -or $url.StartsWith('https://')) {
							$urls += $url
						}
					}
				}

				$urls | ForEach-Object {
					$url = $_
					try{ 
						$response = Invoke-WebRequest -Uri $url -UseBasicParsing -Method head
					} 
					catch {
						$statuscode = $_.Exception.Response.StatusCode.Value__
						
						if(!$statuscode) {
							$statuscode = "Not reachable"
						}
						
						$brokenItem = [pscustomobject]@{
							"ID"=$checkedItem.ID
							"Icon"=$checkedItem.__Icon
							"DisplayName"=$checkedItem.DisplayName
							"ItemPath"=$checkedItem.ItemPath
							"Version"=$checkedItem.Version
							"Language"=$checkedItem.Language
							"__Updated"=$checkedItem.__Updated
							"__Updated by"=$checkedItem."__Updated by"
							"Link Field"=$field.Name
							"Target Path"=$url
							"Status Code"=$statuscode
							"Link Type"="External"
						}

						$brokenItem
					}
				}
			}
		}
	}
}

$items = @($root) + @(($root.Axes.GetDescendants() | Initialize-Item)) | HasBrokenLink -IncludeAllVersions (!$searchVersion)

if($items.Count -eq 0){
	Show-Alert "There are no items found which have broken links in the current language."
} else {
	$props = @{
		Title = "Broken Links Report"
		InfoTitle = "Found $($items.Count) items with broken links!"
		InfoDescription = "The report checked for $($linksToCheck -join ' & ') links in $(@('all versions','latest versions')[[byte]($searchVersion='1')]) of items."
		MissingDataMessage = "There are no items found which have broken links in the current language."
		PageSize = 25
		ViewName = "BrokenLinks"
		Property = @(
			"Icon","Status Code", 
			@{Label="Name"; Expression={$_.DisplayName} }, 
			@{Label="Item Path"; Expression={$_.ItemPath} },"Link Field", "Rendering","Placeholder","Target Path",
			"Link Type",
			"Version",
			"Language",
			@{Label="Updated"; Expression={$_.__Updated} },
			@{Label="Updated by"; Expression={$_."__Updated by"} }
		)
	}
	
	$items | Show-ListView @props
}
Close-Window
