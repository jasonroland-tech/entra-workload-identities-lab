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

$users = Get-MgUser -Top 10 -Property DisplayName, UserPrincipalName, AccountEnabled
$users | Select-Object DisplayName, UserPrincipalName, AccountEnabled | Format-Table -AutoSize

# This should FAIL with 403: the app only has User.Read.All, so it cannot create users.
$domain = ($users[0].UserPrincipalName -split '@')[1]
try {
    New-MgUser -DisplayName "Should Fail" -MailNickname "shouldfail" -AccountEnabled:$false `
        -UserPrincipalName "shouldfail@$domain" `
        -PasswordProfile @{ Password = [guid]::NewGuid().ToString() + "Aa1!" } -ErrorAction Stop
    Write-Warning "Unexpected: the app was able to create a user. Check its permissions."
} catch {
    if ($_.Exception.Message -match 'Authorization_RequestDenied|Insufficient privileges|403') {
        Write-Host "Expected: write blocked (403). Least privilege works." -ForegroundColor Green
    } else {
        Write-Warning "Create failed for a different reason: $($_.Exception.Message)"
    }
}

Disconnect-MgGraph | Out-Null
