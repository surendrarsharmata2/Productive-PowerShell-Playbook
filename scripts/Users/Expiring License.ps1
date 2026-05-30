$license = [Sitecore.Reflection.Nexus]::LicenseApi
$date = [Sitecore.DateUtil]::IsoDateToDateTime($license.Expiration)

if($date -gt [datetime]::Today.AddDays(14)) {
    exit
}

$title = "Your Sitecore license is about to expire!"
$text = "Your Sitecore license will expire on $($date.ToLongDateString())"
$icon = "Office/32x32/information.png"

$warning = $pipelineArgs.Add($title, $text);
$warning.Icon = $icon

