$selectedItem = Get-Item -Path .
$includeLinkedItems = 0

$parameters = @(
    @{ Name = "Mode"; Title="Installation Options"; Value = "Merge-Merge"; Options = $installOptions; OptionTooltips = $installOptionsTooltips; Tooltip = "Hover over each option to view a short description."; Hint = "How should the installer behave if the package contains items that already exist?<br/><br/>Item : $($selectedItem.ProviderPath)"; Editor="combo"})

$parameters += @{ Name = "IncludeLinkOptions"; Title = "Include linked Items"; Value=0; Tooltip = "Define how linked items will be included in the package"; Options = $linkOptions; OptionTooltips = $linkOptionsTooltips; Editor = "radio" }

$result = Read-Variable @defaultProps -Parameters $parameters -Description "Set installation options for this package source."

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
$itemsToPack = @($selectedItem)
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

Close-Window
