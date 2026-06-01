# Azure Virtual Desktop (AVD) — OpenTofu Deployment

This document describes required permissions, Azure prerequisites, input files, and deployment/destroy execution for the OpenTofu stack in this folder. The OpenTofu code provisions AVD platform resources in Azure using customer-specific pipeline inputs.

The deployment provisions:

- Resource groups (management, host pool, shared image gallery)
- Log Analytics workspace and diagnostic settings
- Key Vault and session host password secrets
- AVD workspace, host pools, application groups, and applications
- Session host VMs, NICs, VM extensions, and host registration
- FSLogix storage account and file shares
- Shared Image Gallery resources and image definitions

> **IMPORTANT:** Replace all placeholders (subscription ID, object IDs, names, and environment-specific values) before deployment.

---

## 1. Authentication and subscription selection

```bash
az login
az account set --subscription "00000000-0000-0000-0000-000000000000"
```

---

## 2. Required permissions (least-privilege guidance)

Recommended minimum permissions for the deployment identity or service connection:

- **Contributor** on the target subscription/resource groups
- **User Access Administrator** when role assignments are created by the stack
- Equivalent custom role permissions for:
  - `Microsoft.Resources/*`
  - `Microsoft.Network/*`
  - `Microsoft.Storage/*`
  - `Microsoft.Compute/*`
  - `Microsoft.DesktopVirtualization/*`
  - `Microsoft.KeyVault/*`
  - `Microsoft.Insights/*`
  - `Microsoft.Authorization/*` (for role assignments)

If custom log export is used, ensure the deployment identity also has access to the target Log Analytics workspace.

---

## 3. Required resource providers

Check registration status:

```bash
az provider show --namespace Microsoft.Compute --query "registrationState" -o tsv
az provider show --namespace Microsoft.Network --query "registrationState" -o tsv
az provider show --namespace Microsoft.Storage --query "registrationState" -o tsv
az provider show --namespace Microsoft.DesktopVirtualization --query "registrationState" -o tsv
az provider show --namespace Microsoft.KeyVault --query "registrationState" -o tsv
az provider show --namespace Microsoft.Insights --query "registrationState" -o tsv
az provider show --namespace Microsoft.Authorization --query "registrationState" -o tsv
az provider show --namespace Microsoft.ManagedIdentity --query "registrationState" -o tsv
```

Register if needed:

```bash
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.DesktopVirtualization
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.Authorization
az provider register --namespace Microsoft.ManagedIdentity
```

> Provider registration can take several minutes. Re-run checks until status is `Registered`.

---

## 4. Required customer files

Per customer, provide:

- `Customers/<Customer>/terraform.tfvars`
- `Customers/<Customer>/providers.tf`
- `Customers/<Customer>/<customer>-prod-customerpipeline-avdac-tofu-001.yml`

Starter templates are available in:

- `_Tofu/_Pipelines/_Templates/Customer Pipeline/`

`terraform.tfvars` contains environment inputs for `variables.tf` (for example host pools, app groups, session hosts, tags, locations, and networking references).

---

## 5. Pipeline deployment flow (recommended)

Reusable template:

- `/_Tofu/_Pipelines/_Templates/AVD/tmpl-prod-customerpipeline-avdac-tofu-001.yml`

Main pipeline parameters used by the template:

- `serviceConnection`
- `tofuWorkingDir` (default `_Tofu`)
- `tfvarsFile`
- `providersFile`
- `operation` (`deploy` or `destroy`)
- `approvalNotifyUsers` (optional)

Execution paths:

- `operation=deploy`: `Validate -> Plan -> ApproveApply -> Apply`
- `operation=destroy`: `DestroyPlan -> ApproveDestroy -> Destroy`

The pipeline authenticates to Azure through the configured service connection and runs OpenTofu with the selected customer files.

---

## 6. Local OpenTofu usage (optional)

If running manually:

```bash
cd _Tofu
tofu init
tofu validate
tofu plan -var-file="/absolute/path/to/Customers/<Customer>/terraform.tfvars"
tofu apply -var-file="/absolute/path/to/Customers/<Customer>/terraform.tfvars"
```

Destroy:

```bash
tofu destroy -var-file="/absolute/path/to/Customers/<Customer>/terraform.tfvars"
```

If required, align backend/provider settings with the pipeline approach by using the customer `providers.tf` as `backend.tf` in `_Tofu`.

---

## 7. Post-deployment checks

- Confirm AVD resource groups were created.
- Confirm AVD workspace, host pools, and application groups exist.
- Confirm session hosts are created and registered in host pools.
- Confirm Log Analytics diagnostics are attached.
- Confirm FSLogix storage and shares exist (if configured).
- Confirm Shared Image Gallery resources are present (if configured).

---

## Troubleshooting — common issues

- **Authorization failures:** missing RBAC permissions (especially role assignment rights).
- **Input validation errors:** malformed objects/lists in `terraform.tfvars`.
- **Host registration issues:** validate host pool registration token and VM extension state.
- **Networking failures:** validate VNet/subnet names and RG references.
- **Image deployment issues:** check source image reference or shared image definition values.
- **Provider errors:** ensure providers are registered and service connection targets the intended subscription.

---

## Security considerations

- Do not commit secrets in `terraform.tfvars`.
- Use least-privilege RBAC for deployment identities.
- Review network exposure and NSG behavior for session hosts.
- Validate all external dependencies before production rollout.

---

## Support and contributions

- **Authors / Maintainers:** Michele Blum & Flavio Meyer
- For issues: open an issue in the repository or contact the repository owner/author.

---

## License

This project is licensed under the [MIT License](https://github.com/DuoInfernale/AVDaC/blob/main/LICENSE).
