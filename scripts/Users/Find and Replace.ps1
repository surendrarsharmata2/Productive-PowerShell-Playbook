<#
    .LINK
        https://vandsh.github.io/sitecore/2018/07/13/spe-search-replace-v2.html
#>

$searchOptions = [ordered]@{
    "Value Contains" = "Contains"
    "Exact Match" = "Equals"
    "Close Match" = "Fuzzy"
}

$indexOptions = [ordered]@{}
foreach($index in Get-SearchIndex | Sort-Object -Property Name) {
    $indexOptions[$index.Name] = $index.Name
}

$index="sitecore_master_index";
$fieldRequiredValidator = { 
    if([string]::IsNullOrEmpty($variable.Value)){
        $variable.Error = "Please provide a value."
    }
}

$dialogProps = @{
    Parameters = @(
        @{ Name = "searchRoot"; Title="Search Root"; Tooltip="The starting point when performing a search."; Source="Datasource=/sitecore/content/"; editor="droptree";},
        @{ Name = "targetIndex"; Value=$index; Title="Target Index"; Tooltip="The index used while performing a search."; Options=$indexOptions; Columns=6;},
                @{ Name = "searchOption"; Value="Contains"; Title="Search Type"; Tooltip="What type of search do you want to run"; editor="combo"; options=$searchOptions; Columns=6;}, 
        @{ Name = "fieldName"; Value=""; Title="Field Name"; Tooltip="The field name containing the text."; Placeholder="Title"; Columns=6; Validator=$fieldRequiredValidator;},
        @{ Name = "searchText"; Value=""; Title="Search Text"; Tooltip="The word or phrase to search."; Placeholder="SiteCore"; Columns=6; Validator=$fieldRequiredValidator;},
        @{ Name = "shouldReplaceText"; Value=$false; Title="Check to replace text"; Tooltip="Check when the text should be replaced."; editor="checkbox"; GroupId="ReplaceOption";},
        @{ Name = "replacementText"; Value=""; Title="Replacement Text"; Tooltip="The keyword or phrase to replace."; Placeholder="Sitecore"; ParentGroupId="ReplaceOption";HideOnValue="0"}
    )
    Description = "Find and replace based on the specified text."
    Title = "Find and Replace"
    Width = 700
    Height = 575
    OkButtonName = "Proceed"
    CancelButtonName = "Abort"
    ShowHint = $true
    Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}
$result = Read-Variable @dialogProps
    
if($result -ne "ok") {
    Exit
}

$searchProps = @{
    Index = $targetIndex
    Criteria = @(
        @{Filter = "DescendantOf"; Field = ("master:/" + $searchRoot.Paths.Path) },
        @{Filter = $searchOption; Field = $fieldName; Value = $searchText}
    )
}

$foundItems = @((Find-Item @searchProps | Initialize-Item))

$reportItems = [System.Collections.ArrayList]@()
foreach($currentItem in $foundItems) {
	
	if($shouldReplaceText){
        $newHaystack = $currentItem[$fieldName].Replace($searchText, $replacementText);
        $currentItem.Editing.BeginEdit()
        $currentItem[$fieldName] = $newHaystack
        $currentItem.Editing.EndEdit() > $null
	}
	$reportItems.Add($currentItem) > $null
}

$reportProps = @{
    Property = @(
        "ID","Name","ItemPath","Language","Version"
    )
    Title = "Find and Replace Report"
    InfoTitle = "Report Details"
    InfoDescription = "The following report shows items found with the specified criteria."
}
$reportItems | Show-ListView @reportProps
Close-Window
