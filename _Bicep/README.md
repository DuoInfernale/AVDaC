# Azure Virtual Desktop (AVD) — Cloud-only Landing Zone Deployment

This document describes required permissions, resource provider registrations, and step‑by‑step deployment instructions for the subscription‑scoped Bicep templates in this repository that deploy an AVD environment (spoke‑only). The deployment provisions:

- Resource groups (AVD, Storage, Network)
- Spoke Virtual Network and AVD subnet
- Private DNS zone + link
- Storage account & file share for FSLogix
- Private endpoint for storage + DNS zone group
- Network Security Group
- AVD Host Pool, Application Group, Workspace
- Configurable number of AVD Session Host VMs

> **IMPORTANT:** Replace all placeholders (subscription ID, principal/user names/IDs, passwords, CIDRs) before running commands.

---

## 1. Authentication and subscription selection

```bash
az login
az account set --subscription "00000000-0000-0000-0000-000000000000"
```

---

## 2. Required permissions (least-privilege guidance)

Recommended minimum to deploy successfully:

- **Contributor** (or **Owner**) on the subscription — required to create resource groups, VNets, storage accounts, private endpoints, and AVD resources.
- **User Access Administrator** on the subscription — required because the deployment performs role assignments for VM access (AVD users/admins) and storage (FSLogix file share permissions). Without this role, the role-assignment steps in the deployment will fail.
  - Alternatively, **Owner** covers both Contributor and User Access Administrator permissions in one role.
- For network operations, **Network Contributor** privileges are implicitly required; these are included in Contributor.

Ensure you have Microsoft Entra ID object IDs ready for:

- `dpar_rbacObjectIdFullDesktopUsers`
- `dpar_rbacObjectIdRBACAVDUsers`
- `dpar_rbacObjectIdRBACAVDAdmin`

If you plan to use custom/restricted roles, make sure the role includes permissions for:

- `Microsoft.Resources/subscriptions/resourceGroups/*`
- `Microsoft.Network/*`
- `Microsoft.Storage/*`
- `Microsoft.Compute/*`
- `Microsoft.DesktopVirtualization/*`
- `Microsoft.Authorization/*` (required — the deployment creates role assignments for VM access and storage)

---

## 3. Required resource providers

Register these providers in the subscription if they are not already registered.

**Check status:**

```bash
az provider show --namespace Microsoft.Compute --query "registrationState" -o tsv
az provider show --namespace Microsoft.Network --query "registrationState" -o tsv
az provider show --namespace Microsoft.Storage --query "registrationState" -o tsv
az provider show --namespace Microsoft.DesktopVirtualization --query "registrationState" -o tsv
az provider show --namespace Microsoft.Resources --query "registrationState" -o tsv
az provider show --namespace Microsoft.Authorization --query "registrationState" -o tsv
```

**Register if necessary:**

```bash
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.DesktopVirtualization
az provider register --namespace Microsoft.Resources
az provider register --namespace Microsoft.Authorization
```

> Provider registration can take several minutes. Re-run the checks until the state is `Registered`.

---

## 4. Parameters file (`params.bicepparam`)

Input parameters are supplied through a **Bicep parameters file** (`.bicepparam`) — not a JSON parameters file. Create `params.bicepparam` in the repository root and replace placeholder values before use.

```bicep
using './main.bicep'

param gpar_customerAbbreviation = 'acm'
param gpar_environment           = 'dev'
param gpar_tags                  = {}

param spar_snetNameSpokeAVD      = 'AVDSubnet'

param dpar_location              = 'switzerlandnorth'
param dpar_locationAVD           = 'westeurope'

param dpar_spokeVnetPrefix       = '10.100.0.0/20'
param dpar_spokeSubnetPrefix     = [ '10.100.1.0/24' ]

param dpar_privateDNSName        = 'privatelink.file.core.windows.net'
param dpar_fsshareQuota          = 100

param dpar_vmCount               = 2
param dpar_vmSize                = 'Standard_D4as_v6'
param dpar_vmlocaladminName      = 'avdadmin'
param dpar_vmlocaladminPassword  = '<securePasswordOrKeyVaultReference>'

param dpar_rbacObjectIdFullDesktopUsers = '<objectId>'
param dpar_rbacObjectIdRBACAVDUsers     = '<objectId>'
param dpar_rbacObjectIdRBACAVDAdmin     = '<objectId>'
```
---

## 5. Validate (What‑If)

Run a What‑If validation before creating resources to preview changes:

```bash
az deployment sub create --location "switzerlandnorth" --parameters params.bicepparam --what-if
```

> **Notes:** When using a `.bicepparam` file, the template reference is declared via the `using` statement inside the parameters file — you do not pass `--template-file`. Choose a valid Azure region for the subscription-level deployment object, e.g., `switzerlandnorth`. This location is for the deployment operation and does not change resource regions supplied inside the template modules.

---

## 6. Execute deployment

After successful validation, deploy the templates:

```bash
az deployment sub create --location "switzerlandnorth" --parameters params.bicepparam
```

Monitor the deployment progress in the CLI output or in the Azure Portal: **Subscriptions → Deployments**.

---

## 7. Post‑deployment checks

- Confirm resource groups created:
  - `<customer>-rg-avd-*`
  - `<customer>-rg-storage-*`
  - `<customer>-rg-network-*`
- Verify the virtual network and AVD subnet exist and that the subnet contains the private endpoint NIC (if private endpoint was created).
- Check the storage account and file share (`fslogix`) exist and RBAC assignments were applied.
- Validate AVD Host Pool, Application Group, Workspace and session hosts are present and session hosts are registered.

---

## Troubleshooting — common issues

- **Missing/invalid parameters:** ensure `dpar_spokeVnetPrefix` and `dpar_spokeSubnetPrefix` are provided and valid CIDRs.
- **VM quota or image availability:** the selected VM size may not be available in the chosen region.
- **Permission errors:** deploying identity needs **Contributor + User Access Administrator** (or **Owner**) on the subscription. Role-assignment failures (`AuthorizationFailed` on `Microsoft.Authorization/roleAssignments/write`) almost always mean User Access Administrator is missing.
- **Private endpoint or DNS failures:** check for existing private DNS zones or conflicting names.
- **Provider registration pending:** re-check registration status until `Registered`.

---

## Security considerations

- Never commit secrets to source control. Use Azure Key Vault and reference secrets where possible.
- Use least-privilege for RBAC assignments. Provide minimal privileges to users and groups.
- Review NSG rules and avoid opening unnecessary inbound ports on session hosts.
- Inspect all module code before deployment (especially any VM extensions).

---

## Support and contributions

- **Authors / Maintainers:** Michele Blum & Flavio Meyer
- For issues: open an issue in the repository or contact the repository owner/author.

---

## License

This project is licensed under the [MIT License](https://github.com/DuoInfernale/AVDaC/blob/main/LICENSE).