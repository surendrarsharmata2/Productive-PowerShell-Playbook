Import-Function -Name Setup-PackageGenerator

$timestamp = Get-Date -Format "yyyyMMdd.HHss"
$selectedItem = Get-Item -Path .
$examplePackageName = "$($timestamp).$($selectedItem.Name)"
$includeLinkedItems = 0

$parameters = @(
    @{ Name = "packageName"; Title="Package Name"; Placeholder = $examplePackageName; Tab="Package Metadata"},
    @{ Name = "Author"; Value = [Sitecore.Context]::User.Profile.FullName; Tab="Package Metadata"},
    @{ Name = "Publisher"; Value = [Sitecore.SecurityModel.License.License]::Licensee; Tab="Package Metadata"},
    @{ Name = "Version"; Value = $selectedItem.Version; Tab="Package Metadata"},
    @{ Name = "Readme"; Title="Readme"; Lines=7; Tab="Package Metadata"},
    @{ Name = "AsXml"; Title="Download Package as XML"; Value=[bool]$False; Editor="bool"; Tab="Package Metadata" },
    @{ Name = "LeavePackage"; Title="Leave the package on the server"; Value=[bool]$False; Editor="bool"; Tab="Package Metadata" },
    @{ Name = "IncludeItems"; Title="Items to include in package"; Value="RootAndDescendants"; Options=$rootOptions; OptionTooltips = $rootOptionTooltips; Tooltip = "Hover over each option to view a short description."; Hint = "The package will dynamically include the items based on your selection below. <br /><br />Root : '$($selectedItem.ProviderPath)'"; Editor="combo"; Tab="Installation Options" },
    @{ Name = "Mode"; Title="Installation Options"; Value = "Merge-Merge"; Options = $installOptions; OptionTooltips = $installOptionsTooltips; Tooltip = "Hover over each option to view a short description."; Hint = "How should the installer behave if the package contains items that already exist?"; Editor="combo"; Tab="Installation Options"}
)

$parameters += @{ Name = "IncludeLinkOptions"; Title = "Include linked Items"; Value=0; Tooltip = "Define how linked items will be included in the package"; Options = $linkOptions; OptionTooltips = $linkOptionsTooltips; Editor = "radio" }

$props = @{} + $defaultProps
$props["Title"] = "Download Tree as Package"
$props["Description"] = "This Tool allows you to download the item tree as a package quickly."
$props["Parameters"] = $parameters
$props["Width"] = 600
$props["Height"] = 750

$result = Read-Variable @props

Resolve-Error
if($result -ne "ok") {
    Close-Window
    Exit
}

$InstallMode = [Sitecore.Install.Utils.InstallMode]::Undefined
$MergeMode = [Sitecore.Install.Utils.MergeMode]::Undefined
switch ($Mode) {
    "Overwrite" {
        $InstallMode = [Sitecore.Install.Utils.InstallMode]::Overwrite
    }
    
    "Merge-Merge" {
        $InstallMode = [Sitecore.Install.Utils.InstallMode]::Merge
        $MergeMode = [Sitecore.Install.Utils.MergeMode]::Merge
    }
    
    "Merge-Clear" {
        $InstallMode = [Sitecore.Install.Utils.InstallMode]::Merge
        $MergeMode = [Sitecore.Install.Utils.MergeMode]::Clear
    }
    
    "Merge-Append" {
        $InstallMode = [Sitecore.Install.Utils.InstallMode]::Merge
        $MergeMode = [Sitecore.Install.Utils.MergeMode]::Append
    }
    
    "Skip" {
        $InstallMode = [Sitecore.Install.Utils.InstallMode]::Skip
    }
    
    "SideBySide" {
        $InstallMode = [Sitecore.Install.Utils.InstallMode]::SideBySide
    }
    
    "AskUser" {
        $InstallMode = [Sitecore.Install.Utils.InstallMode]::Undefined
    }
}

# Linked items dialog
$itemsToPack = @()
$itemsToPack += Get-ChildrenToInclude $selectedItem $IncludeItems
$linkedItems = @()
$linkedItems += Get-LinkedItems $selectedItem $itemsToPack $IncludeLinkOptions

if ($linkedItems.Count -gt 0){
    $selectedLinks = Get-SelectedLinks $linkedItems
}

# Add selected linked items to package
if ($selectedLinks -AND $selectedLinks.Count -gt 0){
    foreach ($linkId in $selectedLinks) {
        $itemsToPack += $linkedItems | Where-Object -FilterScript { $_.ID.ToString() -like $linkId }
    }
}

# Adding items to package
foreach ($itemToPack in $itemsToPack) {
    $package = Add-ItemToPackage -Package $package -Item $itemToPack -IncludeDescendants $false
}


if([string]::IsNullOrEmpty($packageName)) {
    $packageName = $examplePackageName
}

$package.Name = $packageName
$package.Metadata.Author = $Author
$package.Metadata.Publisher = $Publisher
$package.Metadata.Version = $Version
$package.Metadata.Readme = $Readme

[string]$packageName = "$($package.Name)-$($package.Metadata.Version)".Trim('-')

if ($AsXml) {
    $packageFileName = "$($packageName).xml"
}
else {
    $packageFileName = "$($packageName).zip"
}


Export-Package -Project $package -Path $packageFileName -Zip:$(!$AsXml)
Download-File "$($SitecorePackageFolder)\$($packageFileName)"
if( -not $LeavePackage )
{
    Remove-Item "$($SitecorePackageFolder)\$($packageFileName)"
}
Close-Window
