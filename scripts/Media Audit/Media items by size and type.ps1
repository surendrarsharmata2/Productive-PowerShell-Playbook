$sizeOptions = [ordered]@{
    "0 KB (any size)" = 0
    "100 KB" = 100000
    "250 KB" = 250000
    "500 KB" = 500000
    "1 MB" = 1000000
    "5 MB" = 5000000
    "10 MB" = 10000000
}

$typeOptions = [ordered]@{
    "gif" = 1
    "jpg, jpeg" = 2
    "pdf" = 3
    "png" = 4
    "svg" = 5
    "doc, docx" = 6
    "xls, xlsx" = 7
    "csv" = 8
}

$settings = @{
    Title = "Report Filter"
    Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    OkButtonName = "Proceed"
    CancelButtonName = "Abort"
    Description = "Filter the results based on the media size and type"
    ShowHint = $true
    Parameters = @{ 
        Name = "selectedSize"
        Value = 250000
        Options=$sizeOptions
        Title = "Larger Than"
        Tooltip = "Filter the results for items larger than the specified size"
        Editor = "combo"
    }, @{
        Name = "selectedTypeValues"
        Value = 2,4
        Options = $typeOptions
        Title = "Media Extension"
        Tooltip = "Filter the results for items with the specified extension"
        Editor = "checklist"
        Validation = { $_.Value -ne $null }
    }
}

$result = Read-Variable @settings
if($result -ne "ok") {
    exit
}

$selectedType = @()
foreach($val in $selectedTypeValues) {
    switch($val) {
        1 { $selectedType += "gif" }
        2 { $selectedType += "jpg","jpeg"}
        3 { $selectedType += "pdf" }
        4 { $selectedType += "png" }
        5 { $selectedType += "svg" }
        6 { $selectedType += "doc","docx" }
        7 { $selectedType += "xls","xlsx" }
        8 { $selectedType += "csv" }
    }
}

$mediaItemContainer = Get-Item -Path "master:\media library"
$items = $mediaItemContainer.Axes.GetDescendants() | 
    Where-Object { $selectedType -contains $_.Fields["Extension"].Value -and [int]$_.Fields["Size"].Value -gt $selectedSize } | 
    Initialize-Item | Sort-Object -Property Size -Descending

$reportProps = @{
    Title = "Media by size and type"
    InfoTitle = "Media filtered by file size and extension"
    InfoDescription = "Media found larger than $($selectedSize) bytes. Some paths included with a default installation were ignored."
    Property = @("Name","TemplateName","Size", "Extension","ItemPath")
}
$items | Show-ListView @reportProps

Close-Window
