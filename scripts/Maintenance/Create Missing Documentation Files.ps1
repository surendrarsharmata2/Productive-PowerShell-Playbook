$DocumentationFolder = "C:\Sites\spe\Data\temp\documentation"

$documented = Get-ChildItem $DocumentationFolder | % { $_.BaseName } 
$undocumented = Get-Command -CommandType Cmdlet | ? { $_.DLL -match "Spe"}  | ? { "$($_.Verb)-$($_.Noun)" -Notin $documented } | %{ "$($_.Verb)-$($_.Noun)" }
$year = (Get-Date).Year

$commonParameters = 
    @{ Path = "Path to the item to be processed - can work with Language parameter to narrow the publication scope.";
       Id="Id of the item to be processed - can work with Language parameter to specify the language other than current session language. Requires the Database parameter to be specified.";
       Database="Database containing the item to be fetched with Id parameter.";
       Language="If you need the item in specific Language You can specify it with this parameter. Globbing/wildcard supported.";
       Recurse="Process the item and all of its children.";
       Item="The item to be processed.";
       Identity="User name including domain. If no domain is specified - 'sitecore' will be used as the default value";
       Debug = "#skip#";
       ErrorAction = "#skip#";
       ErrorVariable = "#skip#";
       OutVariable = "#skip#";
       OutBuffer = "#skip#";
       PipelineVariable = "#skip#";
       Verbose = "#skip#";
       WarningAction = "#skip#";
       WarningVariable = "#skip#";
       Confirm = "Prompts you for confirmation before running the cmdlet.";
       WhatIf = "Shows what would happen if the cmdlet runs. The cmdlet is not run.";
       PassThru = "Passes the processed object back into the pipeline."
       };
       

$undocumented | % { 
    $command = (get-command $_)
    $parameters = $command.Parameters.Values
    $outputs = $command.OutputType | %{ "* " + $_.Name } 

    $content = @"
<#
    # $_.

    Description of $_.
    
    ## Detailed Description

    Detailed description of $_.

    &copy; 2010-$year Adam Najmanowicz, Michael West. All rights reserved. Sitecore PowerShell Extensions
    
    ## Parameters
    
"@

foreach($parameter in $parameters){
    if($commonParameters.ContainsKey($parameter.Name)){
        $description = $commonParameters[$parameter.Name];
    }
    else{
        $description = "TODO: Provide description for this parameter";
    }
    if($description -eq "#skip#"){
        continue;
    }
    $content = $content + @" 

    ### -$($parameter.Name)
        
    $description
    
"@
}

    $content = $content + @"
    
    ## Inputs
    
    The input type is the type of the objects that you can pipe to the cmdlet.
    
    * Sitecore.Data.Items.Item
    
    ## Outputs
    
    The output type is the type of the objects that the cmdlet emits.
    
    $($outputs -Join "`n        " )

    ## Notes

    Help Author: Adam Najmanowicz, Michael West

    ## Examples
    
    ### EXAMPLE 1
    
    Example description
    
    ```text
    PS master:\> $_ -Path master:\content\home
    ```
#>
"@

    $fileName = "$DocumentationFolder\$_.TODO.ps1" 
    
    if(Test-Path $fileName){
        Remove-Item $filename
    } 
    
    New-Item $fileName -Type File | Set-Content -Value $content
    Write-Host Generated $fileName

}
