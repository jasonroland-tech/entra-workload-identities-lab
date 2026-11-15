<#
.SYNOPSIS
  Signs in to Microsoft Graph as an app (no user, no password, no client secret)
  and lists users. Proves certificate based auth for a non-human identity.

.EXAMPLE
  .\Connect-GraphWithCert.ps1 -TenantId <tenant-guid> -ClientId <app-guid> -Thumbprint <cert-thumbprint>
#>
param(
    [Parameter(Mandatory)] [string] $TenantId,
    [Parameter(Mandatory)] [string] $ClientId,
    [Parameter(Mandatory)] [string] $Thumbprint
)

if (-not (Get-Module -ListAvailable Microsoft.Graph.Users)) {
    Install-Module Microsoft.Graph.Users -Scope CurrentUser -Force
}

# The private key never leaves the local certificate store.
Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $Thumbprint -NoWelcome

$ctx = Get-MgContext
Write-Host "Signed in as app: $($ctx.AppName). Auth type: $($ctx.AuthType). Scopes: $($ctx.Scopes -join ', ')"

Get-MgUser -Top 10 -Property DisplayName, UserPrincipalName, AccountEnabled |
    Select-Object DisplayName, UserPrincipalName, AccountEnabled |
    Format-Table -AutoSize

# This should FAIL: the app only has User.Read.All, so it cannot create users.
try {
    New-MgUser -DisplayName "Should Fail" -MailNickname "shouldfail" -AccountEnabled:$false `
        -UserPrincipalName "shouldfail@$((Get-MgOrganization).VerifiedDomains[0].Name)" `
        -PasswordProfile @{ Password = [guid]::NewGuid().ToString() + "Aa1!" } -ErrorAction Stop
    Write-Warning "Unexpected: the app was able to create a user. Check its permissions."
} catch {
    Write-Host "Expected: write blocked. Least privilege works." -ForegroundColor Green
}

Disconnect-MgGraph | Out-Null
