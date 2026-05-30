$props = @{
    Title = "Logged in Session Manager"
    InfoTitle = "User Sessions"
    InfoDescription = "Logged in sessions are unique to each browser. Encourage users to not login in multiple places if sessions near the number allowed by the Sitecore license."
    Property = @(
        @{Label="User"; Expression={ $_.UserName} },
        @{Label="Logged In"; Expression={ $_.Created } },
        @{Label="Last Activity"; Expression={ $_.LastRequest} },
        @{Label="Session ID"; Expression={ $_.SessionID} },
        @{Label="Icon"; Expression={ "Office/32x32/businessperson.png" } }
    )
}

Get-Session | Show-ListView @props
Close-Window
