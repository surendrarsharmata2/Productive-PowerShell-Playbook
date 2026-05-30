$sites = [Sitecore.Sites.SiteManager]::GetSites()
$usedUrls = @();
$outSites = @();
$conflicts = 0;
$progress = 0;
$ignoredSites = @("system", "publisher", "scheduler") # + @("shell", "login", "admin", "service", "modules_shell", "modules_website");

foreach ($siteObj in $sites) {

	Write-Progress -PercentComplete ($progress / $sites.Count) -Activity "Processing Sites List" -CurrentOperation "Analysing $($siteObj.Name)" -Status "Analysing";
	$site = $siteObj.Properties;
	$hostName = $site["hostName"];
    $sitename = $siteObj.Name;
    
	if ($hostName -eq $null -or $hostName -eq "") {
		$hostName = "*";
	}
	if($ignoredSites -contains $sitename){
	    continue;
	}

    $virtualVolder = if($site["virtualFolder"]) {$site["virtualFolder"].Trim("/")} else {[string]::Empty};
	$currUrls = $hostName.Split("|") | % { $hostName + "/" + $virtualVolder };

	$conflicted = $false
	foreach ($currUrl in $currUrls) {
		foreach ($url in $usedUrls) {
			if ($currUrl -like $url.Url) {
				$conflictText = "<italics>$currUrl</italics>&nbsp; hidden by <italics>$($url.url)</italics> from <b>$($url.UsedBy)</b>";
				if (-not $conflicted) {
					#"New conflict"
					if (Get-Member -InputObject $siteObj -Name "Conflict" -MemberType NoteProperty) {
						$siteObj.Conflict = $conflictText;
					} else
					{
						Add-Member -InputObject $siteObj -MemberType NoteProperty -Name "Conflict" -Value $conflictText;
					}
				}
				else {
					#"Conflicted already"
					$siteObj.Conflict = "$($siteObj.Conflict) <span style='color:red;'>and</span> $conflictText";
				}
				$conflicted = $true;
			}
		}
		$usedUrls += @{ Url = $currUrl; UsedBy = $siteObj.Name };
	}
	if ($conflicted) {
		$conflicts++;
	}
	$outSites +=,$siteObj;
}


if ($conflicts -gt 0) {
	$conflictText = "There are <b>$conflicts</b> conflicts in your site management configuration.<br/>" + `
 		"Consider moving the more generic sites that hide your other sites down the list so they don't hijack the requests.";
} else {
	$conflictText = "Congratulations your Sitecore instance has no domain collisions!";
}

$outSites | Show-ListView -Title "Site Manager Report" -InfoTitle "Site domain collision report" -InfoDescription $conflictText -MissingDataMessage "No domains defined" `
 	-Property `
 	@{ Label = "Site"; Expression = { $_.Name } },
@{ Label = "Host"; Expression = { $_.Properties["hostName"] } },
@{ Label = "Virtual Folder"; Expression = { $_.Properties["virtualFolder"] } },
@{ Label = "State"; Expression = { if ($_.Conflict -ne $null) { "Conflict" } else { "OK" } } },
@{ Label = "Hidden domains"; Expression = { $_.Conflict } },
@{ Label = "Icon"; Expression = { if ($_.Conflict -ne $null) { "Office/32x32/sign_forbidden.png" } else { "Office/32x32/check.png" } } };

Close-Window 
