# Deployment Guide

## Prerequisites

- Terraform 1.9 or later
- Azure CLI 2.84 or later
- An Azure subscription eligible for Microsoft Foundry and Anthropic Claude
- Contributor permission on the target subscription or resource group
- Permission to create role assignments when attendee RBAC is enabled
- Access to paid Azure Marketplace partner offers

The deployment uses public Azure endpoints to keep the workshop simple.

## 1. Sign In

```powershell
az login
az account set --subscription "<subscription-id>"
az account show --output table
```

Register the required providers if they are not already registered:

```powershell
az provider register --namespace Microsoft.CognitiveServices
az provider register --namespace Microsoft.ApiManagement
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.OperationalInsights
```

## 2. Configure Variables

From the repository root:

```powershell
Copy-Item infra/terraform.tfvars.example infra/terraform.tfvars
```

Edit `infra/terraform.tfvars` and set at least:

- `publisher_email`
- `claude_organization_name` to the legal entity using Claude
- `claude_country_code` and `claude_industry`
- GPT and Claude model versions, SKUs, and capacities from the live catalog
- `attendee_principal_id` only when attendee role assignments are wanted

Capacity is expressed in thousands of tokens per minute for the example
Global Standard deployments. Do not commit `terraform.tfvars`.

## 3. Validate and Deploy

```powershell
Set-Location infra
terraform init
terraform fmt -recursive -check
terraform validate
terraform plan -out main.tfplan
terraform apply main.tfplan
```

API Management Basic v2 can take several minutes to provision. Fresh role
assignments can also take a few minutes to become effective.

## 4. Test Claude
Install `Anthropic SDK`

```powershell
pip install anthropic
```

Run the verify script to generate a simple message and do web search.
```powershell
cd ./test
python claude_verify.py
```

## 5. Test GPT
Install `OpenAI SDK`

```powershell
pip install openai
```

Run the verify script to generate a simple message and do web search.
```powershell
cd ./test
python gpt_verify.py
```

## 6. Verify Monitoring

Allow approximately 15 minutes for an existing Log Analytics workspace, or up
to two hours for a new workspace, to receive resource logs.

Run these queries in the workspace:

```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(1h)
| order by TimeGenerated desc
```

```kusto
ApiManagementGatewayLlmLog
| where TimeGenerated > ago(1h)
| order by TimeGenerated desc
```

Application Insights request telemetry is stored in the same workspace. Full
request and response bodies are disabled in the Application Insights logger.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Claude deployment is unavailable | Confirm region, Marketplace eligibility, and live catalog entry. |
| APIM returns 401 or 403 from a model | Wait for RBAC propagation and verify APIM has Foundry User. |
| Content Safety returns 403 unexpectedly | Review the configured threshold; lower values are more restrictive. |
| APIM returns 404 | Verify the output URL and that the request body uses the Claude deployment name `claude`. |
| APIM returns 429 | The per-subscription token policy has reached its tokens-per-minute limit. |
| LLM log table is empty | Send model traffic, wait for ingestion, and verify `GatewayLlmLogs` is supported in the selected region. |

## Cleanup

```powershell
terraform destroy
```

Review the destroy plan before confirming. This removes the resource group and
all workshop resources, including monitoring data.