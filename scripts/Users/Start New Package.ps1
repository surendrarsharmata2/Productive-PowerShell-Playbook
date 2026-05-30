Import-Function -Name Setup-PackageGenerator

$props = @{} + $defaultProps
$props["Title"] = "Starting New Package"
$props["Description"] = "A new package has been prepared for you."
$props["OkButtonName"] = "Add"
$props["CancelButtonName"] = "Skip"

$selectionOptions = [ordered]@{"Add Item to Package"=1;"Add Tree to Package"=2;}
$selectionOptionsTooltips = [ordered]@{
    "1" = "Choosing this option will prompt you with a dialog for adding a single item."
    "2" = "Choosing this option will prompt you with a dialog for adding a tree of items."
}
$selectedOption = 1
$parameters = @(
    @{ Name = "selectedOption"; Title="Selected Item"; Hint = "If you would like to add the selected item or tree to the new package, choose an option below."; Options=$selectionOptions; OptionTooltips = $selectionOptionsTooltips; Editor="radio" }
)
$result = Read-Variable @props -Parameters $parameters

Resolve-Error

if($result -ne "ok") {
    Close-Window
    Exit
}

switch($selectedOption) {
    1 {
        Get-Item -Path "master:" -ID "{A6D3CE99-9BDE-4344-911D-CFB3FB742DE6}" | Invoke-Script
    }
    
    2 {
        Get-Item -Path "master:" -ID "{E6B36111-8411-414B-A7E9-58E75B365EA7}" | Invoke-Script
    }
}

Close-Window
