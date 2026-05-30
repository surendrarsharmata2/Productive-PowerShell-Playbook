$item = Get-Item -Path "."

$icon = $PSScript.Appearance.Icon -replace "32x32","16x16"
$source = [Sitecore.Resources.Images]::GetThemedImageSource($icon)

$title = "Elevated Unlock"
$text = "<img src='$($source)' />Use elevated privileges to unlock the current item."

$warning = $pipelineArgs.Add()
$warning.Title = $title
$warning.Text = $text

$script = Get-Item -Path "master:" -ID "{BD07C7D1-700D-450C-B79B-8526C6643BF3}"
$command = "item:executescript(id=$($item.ID),db=$($item.Database.Name),script=$($script.ID),scriptDb=$($script.Database.Name))"
$warning.AddOption("Unlock", $command)
$warning.HideFields = $false
