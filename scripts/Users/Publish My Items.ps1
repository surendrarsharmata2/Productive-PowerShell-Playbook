Get-Item -Path . | Where-Object { $_.UpdatedBy –eq $me } | Publish-Item -verbose
Get-ChildItem -Path . -Recurse | Where-Object { $_.UpdatedBy –eq $me } | Publish-Item -Verbose
