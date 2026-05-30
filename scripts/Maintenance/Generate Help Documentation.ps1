$documentation = Join-Path -Path "$SitecoreDataFolder\temp" -ChildPath "documentation"
if(-not (Test-Path -Path $documentation)) {
    New-Item -Path $documentation -ItemType Directory
}

$summaryUrl = "https://github.com/SitecorePowerShell/Book/blob/master/SUMMARY.md"
$response = Invoke-WebRequest -UseBasicParsing -Uri $summaryUrl
$pages = $response.Links | 
    Where-Object { $_.href.StartsWith("/SitecorePowerShell/Book/blob/master/appendix/") } |
    Where-Object { !$_.href.EndsWith("README.md") } |
    ForEach-Object { "https://raw.githubusercontent.com$($_.href)".Replace("blob/","") }

function ConvertPage {
    param(
        [string]$Page
    )

    $markdown = Invoke-WebRequest -UseBasicParsing -Uri $Page | Select-Object -ExpandProperty Content

    $r = $markdown
    $options = [System.Text.RegularExpressions.RegexOptions]::Multiline
    # h1 - h4 and hr
    $r = [regex]::new("^#### (.*)=*", $options).Replace($r, "`$1")

    $r = [regex]::new("^# (.*)=*", $options).Replace($r, ".SYNOPSIS`n`$1")

    $r = [regex]::new("^## Detailed Description(.*)=*", $options).Replace($r, ".DESCRIPTION`n`$1")
    $r = [regex]::new("^## Parameters(.*)=*", $options).Replace($r, "")
    $r = [regex]::new("^## Notes(.*)=*", $options).Replace($r, ".NOTES")
    $r = [regex]::new("^## Syntax(.*)=*", $options).Replace($r, ".SYNTAX")
    $r = [regex]::new("^## Notes(.*)=*", $options).Replace($r, ".NOTES")
    
    $r = [regex]::new("^## Examples(.*)=*", $options).Replace($r, "")
    $r = [regex]::new("^## Related Topics(.*)=*", $options).Replace($r, ".LINK")
    $r = [regex]::new("^## Inputs(.*)=*", $options).Replace($r, ".INPUTS")
    $r = [regex]::new("^## Outputs(.*)=*", $options).Replace($r, ".OUTPUTS")

    $r = [regex]::new("^### -(.*)=*", $options).Replace($r, ".PARAMETER `$1")
    $r = [regex]::new("^### EXAMPLE [0-9]{0,2}(.*)=*", $options).Replace($r, ".EXAMPLE `$1")

    #$r = [regex]::new("^[-*][-*][-*]+", $options).Replace($r, "<hr />")

    # Replace links
    $r = [regex]::new("\[https?.*\]\((https?.*)\)", $options).Replace($r, "`$1")
    # Replace page references to just the command name
    $r = [regex]::new("\[(?<name>.*)\]\(.*\)", $options).Replace($r, "`$1")
    # Replace code sample format
    $r = [regex]::new("[\r\n]``````text", $options).Replace($r, "")
    $r = [regex]::new("[\r\n]``````", $options).Replace($r, "")

    # Remove Aliases table
    $r = [regex]::new("[\r\n](\|.*\|.*\|)", $options).Replace($r, "")

    $r = $r.Replace("&lt;","<").Replace("&gt;",">")
    $r = $r.Replace("\[","[").Replace("\]","]")
    $r = $r.Replace("\_","_")
    $r = $r.Replace("&copy;","(c)")
    $r = $r.Replace("2010-2018","2010-$([datetime]::Today.Year)")
    $r = $r.Replace("2010-2017","2010-$([datetime]::Today.Year)")
    $r = [regex]::new("\.SYNTAX[\s\S]*(?=\.DESCRIPTION)", $options).Replace($r, "")
    
    $linkSection = [regex]::new("\.LINK[\r\n]*([\*\s\w\W])*(?=\.[\w])", $options).Match($r).Value
    $linkSection = [regex]::new("\.LINK[\r\n]*", $options).Replace($linkSection, "")
    $linkSection = [regex]::new("^\*\s(.*)$", $options).Replace($linkSection, ".LINK`n`$1`n")
    $r = [regex]::new("\.LINK[\r\n]*([\*\s\w\W])*(?=\.[\w])", $options).Replace($r, $linkSection)

    $r
}

foreach($page in $pages) {
    Write-Host "Processing $($page)"
    $pageName = $page.Split("/")[-1].Replace(".md",".ps1")
    $convertedPage = ConvertPage -Page $page
    $content = "<#`n$($convertedPage)`n#>"
    [System.IO.File]::WriteAllText("$($documentation)\$($pageName)",$content, [System.Text.Encoding]::UTF8)
}

$help = Join-Path -Path $AppPath -ChildPath "sitecore modules\PowerShell\Assets"
$moduleLibraryPath = (Join-Path -Path $AppPath -ChildPath "bin\Spe.dll")
if(!(Test-Path -Path $moduleLibraryPath)) {
    Write-Error "Module Library Path not found"
}
$helpLibraryPath = (Join-Path -Path $AppPath -ChildPath "bin\PowerShell.MamlGenerator.dll")
if(!(Test-Path -Path $helpLibraryPath)) {
    Write-Error "Help Library Path not found"
}

if(-not(Test-Path -Path $documentation)) {
    Write-Error "The documenation directory is empty"
}
$files = [System.IO.Directory]::GetFiles($documentation, "*.ps1")
Add-Type -Path $helpLibraryPath

[PowerShell.MamlGenerator.CmdletHelpGenerator]::GenerateHelp($moduleLibraryPath, $help, $files)
Remove-Item "$help/*.maml" -Force
Get-Item "$help/*.xml" | Rename-Item -NewName { $_.name -replace '\.xml','.maml' }
Send-File -Path "$help/Spe.dll-help.maml"
