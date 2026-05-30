param([string]$name="Good morning")
$license = [Sitecore.Reflection.Nexus]::LicenseApi
$date = [Sitecore.DateUtil]::IsoDateToDateTime($license.Expiration)

$PSEmailServer = [Sitecore.Configuration.Settings]::MailServer

$email = @{
    To = "License Manager < noreply@test.com >"
    From = "SPE Team < noreply@spe.com >"
    Subject = "Sitecore license expiration : $($date.ToString('MM/dd/yyyy'))"
    BodyAsHtml = $true
    Body = ""
}

$head = @"
<style>
    body{font-family:'Calibri',sans-serif;font-size:14px;margin:0} 
</style>
"@

$body = @"
$($name),<br/>
Your Sitecore license will expire on <strong>$($date.ToLongDateString())</strong>.<br/>
<br/>
Make sure you update the license to your Sitecore environment to keep it up and running.<br/>
<br/>
Sincerely,<br/>
The SPE Team
"@

$email.Body = ConvertTo-Html -Head $head -Body $body | Out-String

Send-MailMessage @email -Encoding UTF8
