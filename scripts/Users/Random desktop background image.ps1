<#
    Adapted from:
    http://www.sitecore.net/Learn/Blogs/Technical-Blogs/John-West-Sitecore-Blog/Posts/2010/07/Randomize-Sitecore-Desktop-Background-Image.aspx
#>

$path = [Sitecore.IO.FileUtil]::MapPath([Sitecore.Configuration.Settings]::WallpapersPath)

if (!([System.IO.Directory]::Exists($path))) {
    Write-Log "Background images directory not found."
    return
}

$files = [System.IO.Directory]::GetFiles($path)

if ($files.Length -lt 1) {
    Write-Log "No background images found."
    return
}

$pipelineArgs = Get-Variable -Name pipelineArgs -ValueOnly
$username = $pipelineArgs.UserName
Write-Log "Changing background for $($username)"
$user = Get-User -Identity $username -Authenticated
$which = (New-Object System.Random).Next($files.Length - 1)
$user.Profile.SetCustomProperty("Wallpaper", [Sitecore.IO.FileUtil]::UnmapPath($files[$which]))
$user.Profile.Save();
