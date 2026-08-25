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

## What Is Included

- Microsoft Foundry account and project
- GPT and Anthropic Claude model deployments
- API Management Basic v2 with `/gpt` and `/claude` routes
- Managed identity authentication from API Management to the model backends
- Azure AI Content Safety for prompt and completion checks
- Log Analytics with 30-day retention
- Workspace-based Application Insights
- Optional attendee RBAC assignments

## Start Here

1. Read the [deployment guide](docs/deployment-guide.md).
2. Copy `infra/terraform.tfvars.example` to `infra/terraform.tfvars` and set
	your publisher email and legal Anthropic organization details.
3. From the `infra` directory, run:

	```powershell
	terraform init
	terraform validate
	terraform plan -out main.tfplan
	terraform apply main.tfplan
	```

For resource and policy details, see the
[template explanation](docs/template-explanation.md). The source architecture
is in [workshop-architecture.mmd](workshop-architecture.mmd).

> Claude availability, Marketplace eligibility, and model quota depend on the
> Azure subscription and region. Complete the preflight steps in the deployment
> guide before applying the template.