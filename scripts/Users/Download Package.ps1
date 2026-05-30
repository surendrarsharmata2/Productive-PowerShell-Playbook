if(!$Author) {
    $Author = [Sitecore.Context]::User.Profile.FullName;
}

if(!$Publisher) {
    $Publisher = [Sitecore.SecurityModel.License.License]::Licensee;
}

$timestamp = Get-Date -Format "yyyyMMdd.HHss"
$examplePackageName = "$($timestamp).Content"

$parameters = @(
    @{ Name = "packageName"; Title="Package Name"; Placeholder = $examplePackageName },
    @{ Name = "Author"; Title="Author"},
    @{ Name = "Publisher"; Title="Publisher"},
    @{ Name = "Version"; Title="Version"},
    @{ Name = "Readme"; Title="Readme"; Lines=10;},
    @{ Name = "AsXml"; Title="Download Package as XML"; Value=[bool]$False; Editor="bool" }
)

$props = @{} + $defaultProps
$props["Title"] = "Download Package"
$props["ShowHints"] = $False
$props["Description"] = "This tool allows you to download the package built in the current session."
$props["Parameters"] = $parameters

$result = Read-Variable @props

if($result -ne "ok") {
    Close-Window
    Exit
}

if([string]::IsNullOrEmpty($packageName)) {
    $packageName = $examplePackageName
}

$package.Name = $packageName
$package.Metadata.PackageName = $packageName
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
Remove-Item "$($SitecorePackageFolder)\$($packageFileName)"
Close-Window
