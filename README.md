# AVD Automation with Bicep and Azure DevOps

## Project Overview

The AVD Automation with Microsoft Bicep and Azure DevOps, developed by [Michele Blum](https://github.com/quattro99) and [Flavio Meyer](https://github.com/flaviomeyer), aims to streamline and automate the management of Azure Virtual Desktop (AVD) configurations and deployments using Azure DevOps pipelines. This project leverages the power of DevOps practices to ensure consistent, repeatable, and efficient deployment and management of AVD resources.

## Objectives

- **Automate AVD configuration**: Automate the deployment and management of AVD configurations, policies, and applications.
- **Consistency and compliance**: Ensure consistent application of policies and configurations across all managed AVD environments.
- **Version control**: Maintain version control of AVD configurations and policies using Azure Repos.
- **Continuous integration and continuous deployment (CI/CD)**: Implement CI/CD pipelines to automate the testing, validation, and deployment of AVD configurations.
- **Scalability**: Enable scalable management of AVD resources across multiple environments and organizational units.

## Key Features

- **Automated policy deployment**: Use Azure DevOps pipelines to automate the deployment of AVD policies and configurations.
- **Configuration as code**: Store AVD configurations and policies as code in Azure Repos, enabling version control and collaboration.
- **CI/CD pipelines**: Implement CI/CD pipelines to automate the testing, validation, and deployment of AVD configurations.
- **Environment management**: Manage multiple environments (e.g., development, testing, production) with environment-specific configurations.
- **Reporting and monitoring**: Integrate reporting and monitoring tools to track the status and compliance of AVD deployments.

## Project Structure

The project is structured into the following key components:

1. **Repository**: An Azure Repo to store AVD configurations, policies, and pipeline definitions.
2. **Pipelines**: Azure DevOps pipelines to automate the deployment and management of AVD resources.
3. **Templates**: Reusable pipeline templates to standardize the deployment process.
4. **Scripts**: PowerShell or other scripting languages to interact with the Azure API for AVD management.
5. **Documentation**: Comprehensive documentation to guide users on setting up and using the automation framework.

## Getting Started

To get started with the AVD Automation via Azure DevOps project, follow these steps:

1. **Clone the repository**: Clone the Azure Repo to your local machine.
2. **Set Up Azure DevOps**: Configure the necessary service connections and permissions.
3. **Define configurations**: Define your AVD configurations and policies as code in the repository.
4. **Create pipelines**: Create and configure Azure DevOps pipelines using the provided templates.
5. **Deploy and manage**: Use the pipelines to deploy and manage AVD configurations across your environments.

## Prerequisites

- **Azure Subscription**: An active Azure subscription with Azure Virtual Desktop.
- **Azure DevOps account**: An Azure DevOps account to create and manage pipelines.
- **Permissions**: Appropriate permissions to manage AVD resources and configure Azure DevOps pipelines.
- **Tools**: PowerShell or other scripting tools to interact with the Azure API.

## Bicep Parameters

The following Bicep parameters are required during the manual interaction in the Azure DevOps pipeline:

- **customerAbbreviation**: Customer Abbreviation (3 characters max, no special characters and no capital letters).
- **environment**: Environment for Resource Deployment (e.g., Production, Test, Development) with default value `prod`.
- **location**: Deployment Location for Resources (e.g., Switzerland North, West Europe, etc.) with default value `switzerlandnorth`.
- **locationAVD**: Location for Azure Virtual Desktop Metadata Deployment (e.g., West Europe, North Europe etc.) with default value `westeurope`.
- **vdwsName**: Virtual Desktop Workspace Name (e.g., DuoInfernaleVDWS or DuoInfernaleVDWS-Prod; NO SPACES ALLOWED).
- **networkId**: Network ID in CIDR format (should be `/20`) with default value `10.100.0.0/20`.
- **privateDNSName**: Private DNS Zone Name (e.g., int.duo-infernale.ch).
- **fsshareQuota**: File Share Storage Quota (in GB, minimum 100 GB, Suggestion: User x 30 GB = Total) with default value `300`.
- **vmCount**: Number of Virtual Machines to Deploy with default value `2`.
- **vmSize**: Size of Virtual Machines (e.g., Standard D2s v6) with default value `Standard_D2s_v6`.
- **tags**: Resource Tags (Key:Value pairs for organization, e.g., 'Owner: John Doe <ENTER> Department: IT').
- **localadminName**: Local Administrator Username for Virtual Machines.
- **localadminPassword**: Local Administrator Password for Virtual Machines.
- **rbacObjectIdFullDesktopUsers**: Object ID for Full Desktop Users RBAC Group.
- **rbacObjectIdRBACAVDAdmin**: Object ID for AVD Admins RBAC Group.
- **rbacObjectIdRBACAVDUsers**: Object ID for AVD Users RBAC Group.

## Support and contributions

If you encounter any issues or have questions about the project, please contact the project maintainers. Feel free to submit pull requests to improve the project.

## License

This project is licensed under the [MIT License](https://github.com/DuoInfernale/AVDaC/blob/main/LICENSE).