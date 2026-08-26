# Microsoft Foundry AI Gateway Workshop

## Agenda
| Section | Description |
| --- | --- |
| Intro | Workshop Introduction |
| Azure Services Introduction | Foundry, APIM... |
| Architecture Description | Current vs To Be |
| Deploy Azure resources | Deploy terraform code & test |

## Workshop Content
This repository deploys a small AI Gateway architecture:

```text
Application -> Azure API Management -> GPT or Claude in Microsoft Foundry
```

API Management applies a per-subscription token limit and Azure AI Content
Safety checks to each model route. Gateway logs are sent to Log Analytics and
request telemetry is sent to workspace-based Application Insights.

## Terraform Versions

Choose the Terraform directory based on the environment:

| Directory | Use case | Connectivity |
| --- | --- | --- |
| `workshop_infra` | Workshop and learning environment | Basic v2 APIM and public Azure service endpoints. This version is intentionally smaller and easier to deploy during the workshop. |
| `prod_infra` | Production-oriented environment | Standard v2 APIM remains public, while Foundry, Content Safety, Log Analytics, and Application Insights use private endpoints, private DNS, and disabled public network access. |

The private version adds a virtual network with separate APIM integration and
private endpoint subnets. APIM accepts public client traffic and reaches the
isolated backends through outbound VNet integration. Azure Monitor Private Link
Scope isolates monitoring ingestion and queries. It does not deploy Azure Front
Door or Application Gateway.

The two directories use independent Terraform state. Private resource names
include `-private-`, allowing both versions to coexist when the configured
address ranges do not overlap with connected networks.

## What Is Included

- Microsoft Foundry account and project
- GPT and Anthropic Claude model deployments
- API Management Basic v2 in `workshop_infra` or Standard v2 in `prod_infra`, with
	`/gpt` and `/claude` routes
- Managed identity authentication from API Management to the model backends
- Azure AI Content Safety for prompt and completion checks
- Log Analytics with 30-day retention
- Workspace-based Application Insights
- Optional production-oriented VNet, private endpoints, private DNS, and Azure
	Monitor Private Link Scope in `prod_infra`
- Optional attendee RBAC assignments

## Start Here

1. Read the [deployment guide](docs/deployment-guide.md) and choose `workshop_infra` or
	`prod_infra`.
2. In the selected directory, copy `terraform.tfvars.example` to
	`terraform.tfvars` and set your publisher email and legal Anthropic
	organization details. For `prod_infra`, also confirm that the default
	virtual network address ranges do not overlap with connected networks.
3. From the selected directory, run:

	```powershell
	terraform init
	terraform validate
	terraform plan -out main.tfplan
	terraform apply main.tfplan
	```

For resource and policy details, see the
[template explanation](docs/template-explanation.md). The source architecture
is described in [architecture.md](docs/architecture.md).

> Claude availability, Marketplace eligibility, and model quota depend on the
> Azure subscription and region. Complete the preflight steps in the deployment
> guide before applying the template.