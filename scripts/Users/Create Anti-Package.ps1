Import-Function -Name New-PackagePostStep

$response = Show-ModalDialog -HandleParameters @{
    "h"="Create an Anti-Package"; 
    "t" = "Select a package that needs an anti-package"; 
    "ic"="Office/32x32/die.png"; 
    "ok"="Pick";
    "ask"="";
    "path"= "packPath:$SitecorePackageFolder";
    "mask"="*.zip";
} -Control "Installer.Browse"

if(!$response -or $response -eq "undetermined") {
    Write-Verbose "Operation cancelled by user."
    return $null
}

$path = Join-Path -Path $SitecorePackageFolder -ChildPath $response
Write-Verbose "Selected package at the path $($path) to process."

function Get-PackageItem {
    param(
        [string]$Entry
    ) 
    
    $pi = @{}
    $split = $Entry -split "/"
    $pi["Database"] = $split[1]
    $pi["Name"] = $split[$split.Length - 4]
    $pi["ID"] = $split[$split.Length - 3]
    $pi["ItemPath"] = ({
        $path = ""
        for ($index = 2; $index -lt $split.Length - 3; ++$index) {
            $path = $path + "/" + $split[$index]
        }
        $path
    }.Invoke())
    
    [pscustomobject]$pi
}

function Get-PackageFile {
    param (
        [string]$Entry
    )
    
    $pf = @{}
    
    $filename = $Entry
    $pf["FileName"] = $filename
    
    [pscustomobject]$pf
}

$packageItems = @()
$packageFiles = @()

$project = Get-Package -Path $path

# Create the new anti-package
$packagePath = [System.IO.Path]::GetFileNameWithoutExtension($path) + ".anti" + [System.IO.Path]::GetExtension($path)
$package = New-Package -Name ("Anti Package for " + $project.Metadata.PackageName)
$package.Sources.Clear()

$readMe = [string]::Format("Anti Package for {0}. Created {1} by {2}.", $project.Metadata.PackageName, [datetime]::Now.ToString(), [Sitecore.Context]::GetUserName())
if($project.Metadata.PostStep) {
    $readMe += "$([Environment]::NewLine + [Environment]::NewLine)WARNING:$([Environment]::NewLine)The original package contains a poststep which may have made modifications that is not known to this antipackage."
}
$package.Metadata.ReadMe = $readMe
$package.Metadata.Publisher = $project.Metadata.Publisher

# Sources
$newPackageItems = @()
$newPackageFiles = @()
foreach($source in $project.Sources) {
    $items = @()
    $files = @()
    $installMode = [Sitecore.Install.Utils.InstallMode]::Undefined
    $mergeMode = [Sitecore.Install.Utils.MergeMode]::Undefined
    
    $sourceTypeName = $source.GetType().Name
    $isItemSource = $sourceTypeName -like "*ItemSource"
    $isFileSource = $sourceTypeName -like "*FileSource"
    $isExplicit = "ExplicitItemSource","ExplicitFileSource" -contains $sourceTypeName
    
    if([string]::IsNullOrEmpty($source.Name)) {
        $guid = [guid]::NewGuid().ToString()
        Write-Verbose "Changing the source name to $($guid) because it's missing."
        $source.Name = $guid
    }
    
    Write-Verbose "Processing $($sourceTypeName) : $($source.Name)"
    if($isExplicit) {
        foreach($entry in $source.Entries) {
            Write-Verbose "Processing entry : $($entry)"
            
            if($isItemSource) {
                $packageItem = Get-PackageItem -Entry $entry
                $database = Get-Database -Name $packageItem.Database
                if($database) {
                    $item = $database.GetItem($packageItem.ID)
                    if(!$item) {
                        $newPackageItems += $packageItem
                    } else {
                        $items += $item
                    }   
                } else {
                    Write-Verbose "Skipping item because the database $($packageItem.Database) does not exist."
                }
            } elseif ($isFileSource) {
                $packageFile = Get-PackageFile -Entry $entry
                $filename = $packageFile.FileName
                $path = Join-Path -Path $AppPath -ChildPath $filename
                if(!(Test-Path -Path $path)) {
                    $newPackageFiles += $packageFile
                } else {
                    $files += Get-Item -Path $path
                } 
            }
        }
    } else {
        if($isItemSource) {
            Write-Verbose "Processing item $($source.Root) from the $($source.Database) database."
            $itemRoot = & { 
                if([Sitecore.Data.ID]::IsID($source.Root)) { 
                    Get-Item -Path "$($source.Database):" -ID $source.Root -ErrorAction SilentlyContinue
                } else { 
                    Get-Item -Path "$($source.Database):$($source.Root)" -ErrorAction SilentlyContinue
                }
            }
            
            if($itemRoot) {
                Write-Verbose "Processing items at the path $($itemRoot)."
                $items = @($itemRoot) + (Get-ChildItem -Path $itemRoot.PSPath -Recurse)
            } else {
                Write-Verbose "No items found at that path. This is likely because it was removed after installation."
            }
        } elseif($isFileSource) {
            $fileRoot = Get-Item -Path "$AppPath\$($source.Root)"
            $files = @($fileRoot)
        }
    }
    
    if($source.TransForms) {
        $installMode = $source.TransForms.Options.ItemMode
        $mergeMode = $source.TransForms.Options.ItemMergeMode
    }
    
    $props = @{
        "Name" = $source.Name
        "InstallMode" = $installMode
    }

    if($isItemSource -and $items) {
        $props["MergeMode"] = $mergeMode
        if($source.SkipVersions) {
            $props["SkipVersions"] = $source.SkipVersions
        }
        if($isExplicit) {
            $package.Sources.Add(($items | New-ExplicitItemSource @props))
        } else {
            $package.Sources.Add(($items | New-ItemSource @props))
        }
    } elseif($isFileSource -and $files) {
        if($isExplicit) {
            $package.Sources.Add(($files | New-ExplicitFileSource @props))
        } else {
            $package.Sources.Add(($files | New-FileSource @props))
        }
    }
}

$source = Get-Item "$AppPath\bin\Spe.Package.dll" | New-ExplicitFileSource -Name "PowerShell PostStep Binary"
$package.Sources.Add($source)

$package.Metadata.PostStep = "Spe.Package.Install.PackagePostStep, Spe.Package"
$package.Metadata.Comment = New-PackagePostStep -PackageItems $newPackageItems -PackageFiles $newPackageFiles

# TODO: I think SkipVersions is never set in the UI. Should we still handle it?
# TODO: Handle security.
Export-Package -Project $package -Path $packagePath -Zip
