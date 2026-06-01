# Usage

## Bicep

1. **Create a customer subfolder under `Customers` if it does not exist**:
   - Ensure there is a subfolder with the customer name under `Customers` in this repository. If it does not exist, create it.

2. **Create a customer pipeline and `main.bicepparam` from templates**:
   - Create a customer pipeline from `_Bicep/_Pipelines/_Templates/Customer Pipeline/tmpl-prod-customerpipeline-avdac-001.yml` under the customer folder.
   - Create a customer parameter file from `_Bicep/_Bicep_Templates/main.bicepparam` under the customer folder.

3. **Define the variables in the customer pipeline**:
   - Define the required variables in the customer pipeline configuration to pass parameters to the template.
   - Use naming like `customerabbreviation-environment-customerpipeline-usage-xxx`, for example: `duo-prod-customerpipeline-avdac-001`.

4. **Copy files from `Customers/_Templates` (if available)**:
   - Copy required files from `Customers/_Templates` to the customer folder.

5. **Reference the template pipeline in the customer pipeline**:
   - Ensure the template pipeline is correctly referenced in the customer pipeline YAML.

6. **Create a service connection**:
   - Set up an Azure DevOps service connection for ARM federated workload identity.

7. **Create the Azure Pipeline for the customer**:
   - Create the pipeline in Azure DevOps using the customer pipeline YAML.
   - Validate first before running.

8. **Rename the Azure Pipeline**:
   - Rename the Azure Pipeline to match the customer pipeline file/pipeline naming.

9. **Run the Azure Pipeline**:
   - Execute the Azure Pipeline to deploy the configuration.

10. **Rerun the pipeline**:
    - Rerun the pipeline to confirm idempotent deployment and verify results.

## OpenTofu

1. **Create a customer subfolder under `Customers` if it does not exist**:
   - Ensure there is a subfolder with the customer name under `Customers`.

2. **Create customer OpenTofu files**:
   - Add `providers.tf` in the customer folder.
   - Add `terraform.tfvars` in the customer folder.
   - Add a customer pipeline YAML in the customer folder (example: `Customers/ACME/acm-prod-customerpipeline-avdac-tofu-001.yml`).

3. **Create the customer pipeline from template**:
   - Reference `/_Tofu/_Pipelines/_Templates/AVD/tmpl-prod-customerpipeline-avdac-tofu-001.yml` in the customer pipeline YAML.

4. **Define required pipeline variables**:
   - `serviceConnection`
   - `tofuWorkingDir`
   - `tfvarsFile`
   - `providersFile`
   - `approvalNotifyUsers` (optional)

5. **Define required pipeline parameter**:
   - `operation` with allowed values `deploy` or `destroy`.
   - Select this choice when starting a pipeline run.

6. **Create a service connection**:
   - Set up an Azure DevOps service connection for ARM federated workload identity.

7. **Create and validate the Azure Pipeline**:
   - Create the pipeline in Azure DevOps with the customer OpenTofu YAML.
   - Validate before first execution.

8. **Run the pipeline**:
   - For deployment: choose `operation=deploy` to run `Validate`, `Plan`, `ApproveApply`, and `Apply`.
   - For teardown: choose `operation=destroy` to run `DestroyPlan`, `ApproveDestroy`, and `Destroy`.

### Minimal customer folder contents (Tofu)

- `providers.tf`
- `terraform.tfvars`
- `<customer>-prod-customerpipeline-avdac-tofu-001.yml`

### Destroy behavior (Tofu)

- Destroy is selected at pipeline run time via the `operation` parameter.
- Use `operation=destroy` to execute the destroy flow.
- The destroy flow includes a manual approval stage (`ApproveDestroy`) before `Destroy`.

## Notes

- Ensure you have the necessary permissions (at least Contributor) to create and manage pipelines in Azure DevOps.
- Verify all required variables and parameters are correctly defined in each customer pipeline configuration.
- Follow naming conventions and folder structure to keep customer onboarding consistent.
