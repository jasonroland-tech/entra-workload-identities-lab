# Entra Workload Identities: App Registrations, Consent and Managed Identity

> **Loom walkthrough:** _link coming soon_

Lab 8 of the Lakeview Health series. People are not the only identities in the cloud. I secured two kinds of non-human identity: an app registration that signs in with a certificate and holds one read permission, and a managed identity that reads a Key Vault secret with no credential at all. Then I locked down who can consent to apps.

## What this proves

| Skill | Evidence |
| --- | --- |
| App registrations and service principals | `app-lakeview-user-report` with Graph `User.Read.All` only |
| Certificate auth over secrets | Non exportable cert on DC01; script in [`scripts/`](scripts) |
| Least privilege, verified | The app can read users; a create attempt is blocked |
| Managed identities | Automation account reads Key Vault through its own identity ([`runbooks/`](runbooks)) |
| Secrets management | Key Vault with RBAC; the identity has Secrets User on one vault |
| Consent governance | User consent off, admin consent workflow on |

## Identity inventory

| Identity | Type | Permission | Credential | Owner |
| --- | --- | --- | --- | --- |
| app-lakeview-user-report | App registration | Graph User.Read.All (application) | Certificate, 6 month expiry | Jason |
| aa-lakeview | System assigned managed identity | Key Vault Secrets User on kv-lakeview-lab | None (Azure issued token) | Jason |

## Results

| Test | Expected | Result |
| --- | --- | --- |
| Script lists users as the app | Success | _pending_ |
| Script tries to create a user | Blocked (403) | _pending_ |
| Runbook reads the secret | Success, secret not printed | _pending_ |
| User tries to consent to a new app | Must request admin approval | _pending_ |

## Run it

See [LAB-GUIDE.md](LAB-GUIDE.md).
