# Usage

1. **Create a Customer subfolder under `Customer` if not exists**:
   - Ensure that there is a subfolder with the name of the Customer under `Customer` in this repository. If it does not exist, create it.

2. **Create a customer-pipeline from the template**:
   - Create a customer-pipeline with the template from `_Pipelines\_Templates\Customer Pipelines\tmpl-prod-customerpipeline-avdac-001.yml` under the Customer's folder.

3. **Define the variables in the customer-pipeline**:
   - Define the necessary variables in the customer's pipeline configuration to pass the required parameters to the template. Name the main-pipeline like: `customerabbrevation-environment-customerpipeline-usage-00x` example: `duo-prd-customerpipeline-avdac-001`.

4. **Copy files from the Customers/_Templates folder**:
   - Copy the necessary files from the `Customers/_Templates` folder to the Customer's folder. (if exists)

5. **Define the template pipeline in the customer-pipeline**:
   - Ensure that the template pipeline is correctly referenced in the customer-pipeline configuration.

6. **Create a service connection**:
   - Set up a service connection in Azure DevOps to allow the pipeline to authenticate and interact with the necessary resources. (ARM federated workload identity)

7. **Create Azure Pipeline for the customer**:
   - Create an Azure Pipeline for the customer using the customer-pipeline configuration. Do not run the pipeline yet; just validate it.

8. **Rename the Azure Pipeline**:
   - Rename the Azure Pipeline to match the name of the customer-pipeline name.

9. **Run the Azure Pipeline**:
   - Execute the Azure Pipeline to deploy the configurations.

10. **Rerun the Pipeline**:
    - Rerun the pipeline to ensure that everything is deployed accordingly and verify the deployment results.

## Notes

- Ensure you have the necessary permissions (at least the Contributor role) to create and manage pipelines in Azure DevOps.
- Verify that all required variables and parameters are correctly defined in the customer-pipeline configuration.
- Follow the naming conventions and folder structure as specified to maintain consistency and organization.
