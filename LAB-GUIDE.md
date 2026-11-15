# Lab guide: Entra workload identities (apps, consent, managed identity, Key Vault)

**Time:** about 75 minutes. **Cost:** a few cents at most (Key Vault operations; Automation has free minutes).
**Why this lab:** Cloud IAM posts from Applied Materials, BlackRock and Regions ask for service principals, app registrations and managed identities by name. These are the non-human identities that outnumber people in the cloud.

Uses the Lakeview tenant and subscription. Run Part 1 on DC01 (start it, then stop it after). 📸 = screenshot. Redact IDs.

## Part 1: App registration with a certificate (30 min)

**1. Register the app.** Entra admin > App registrations > New registration > name `app-lakeview-user-report`, single tenant > Register. Note the **Application (client) ID** and **Directory (tenant) ID**.

**2. Least privilege permission.** API permissions > Add a permission > Microsoft Graph > **Application permissions** > `User.Read.All` > Add. Remove the default `User.Read` delegated permission. Click **Grant admin consent**. 📸
*Why:* application permissions work with no user signed in, so admins must approve them. Only grant what the script needs.

**3. Create a certificate on DC01** (PowerShell as admin):
```powershell
$cert = New-SelfSignedCertificate -Subject "CN=app-lakeview-user-report" -CertStoreLocation Cert:\CurrentUser\My -KeyExportPolicy NonExportable -NotAfter (Get-Date).AddMonths(6)
Export-Certificate -Cert $cert -FilePath C:\Temp\app-lakeview.cer
$cert.Thumbprint
```
Upload `app-lakeview.cer`: app > Certificates & secrets > Certificates > Upload. 📸
*Why:* a client secret is a password that can be copied. A certificate's private key stays on DC01.

**4. Run the script.** Copy [`scripts/Connect-GraphWithCert.ps1`](scripts/Connect-GraphWithCert.ps1) to DC01:
```powershell
.\Connect-GraphWithCert.ps1 -TenantId <tenant-id> -ClientId <client-id> -Thumbprint <thumbprint>
```
It lists users, then tries to create one and is blocked. 📸 the green "write blocked" line.

## Part 2: Managed identity reading Key Vault (30 min)

**5. Create a Key Vault.** Portal > Key vaults > Create > `kv-lakeview-lab` (must be globally unique, add digits) in `rg-lakeview-dev` > Access configuration: **Azure role based access control**. Give yourself **Key Vault Secrets Officer** on the vault, then add a secret `demo-api-key` with any value.

**6. Create an Automation account** `aa-lakeview` in the same resource group. Identity tab: **System assigned: On** (it's on by default).

**7. Grant the identity, not a person.** Key vault > Access control (IAM) > Add role assignment > **Key Vault Secrets User** > Assign access to **Managed identity** > `aa-lakeview`. 📸
*Why:* the identity can read secrets in this one vault and nothing else.

**8. Run the runbook.** Automation account > Runbooks > Create > PowerShell, runtime 7.2 > paste [`runbooks/Get-SecretWithManagedIdentity.ps1`](runbooks/Get-SecretWithManagedIdentity.ps1) (fix the vault name) > Publish > Start. Output shows the secret was read, without printing it. 📸

## Part 3: Govern app access (15 min)

**9. Stop users consenting to random apps.** Enterprise applications > Consent and permissions > User consent settings > **Do not allow user consent**. Then Admin consent settings > **Users can request admin consent: Yes** > reviewer: you. 📸
*Why:* illicit consent grants are a common way attackers take over accounts.

**10. Inventory.** Enterprise applications > filter Application type: **Managed identities**, then **All applications**. Check `app-lakeview-user-report` > Permissions. Note in the README which apps have application permissions and who owns them.

**11. Clean up.** Delete `aa-lakeview` and the Key Vault, and stop DC01. Keep the app registration for screenshots, then delete it or set its certificate to expire.
