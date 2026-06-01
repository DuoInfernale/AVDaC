# AVDaC

AVDaC is an infrastructure-as-code repository to deploy and manage Azure Virtual Desktop (AVD) customer environments in a consistent and repeatable way.

## What this repository is for

This repository provides deployment templates, pipelines, and customer-specific configuration patterns for AVD landing zones. It supports both Bicep and OpenTofu workflows so teams can choose the implementation path that best fits their operational model.

## Bicep (short description)

The `_Bicep` area contains subscription-scoped Bicep templates and pipeline assets for deploying AVD cloud-only landing zone components (networking, storage, AVD core resources, and session hosts) using Azure-native template deployments.

## OpenTofu (short description)

The `_Tofu` area contains OpenTofu code and Azure DevOps pipeline templates for deploying and destroying AVD platform resources through a customer-driven `tfvars`/`providers` model with controlled approval stages.

## Repository owner

- **Owner:** [Duo Infernale](https://github.com/duoinfernale)
- **Maintainers / Authors:** [Michele Blum](https://github.com/quattro99) & [Flavio Meyer](https://github.com/flaviomeyer)

## Support and contributions

If you encounter any issues or have questions about the project, please contact the project maintainers. Feel free to submit pull requests to improve the project.

## License

This project is licensed under the [MIT License](LICENSE).