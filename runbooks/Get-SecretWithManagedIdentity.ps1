# Azure Automation runbook (PowerShell 7.2 runtime).
# Reads a Key Vault secret using the Automation account's system assigned managed identity.
# There is no credential anywhere in this script: Azure issues the token to the identity.

param(
    [string] $VaultName  = "kv-lakeview-lab",
    [string] $SecretName = "demo-api-key"
)

Connect-AzAccount -Identity | Out-Null

$secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -AsPlainText

# Never print the secret itself. Prove access without exposing it.
Write-Output "Read '$SecretName' from $VaultName using managed identity. Length: $($secret.Length) characters."
