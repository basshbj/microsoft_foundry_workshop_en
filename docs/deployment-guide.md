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

## 2. Check Model Availability and Quota

The example uses `eastus2`, `gpt-4o-mini`, and `claude-sonnet-4-6`.
Availability changes, so check the live catalog before deployment:

```powershell
az cognitiveservices model list --location eastus2 --output table
az cognitiveservices usage list --location eastus2 --output table
```

Claude also requires:

- An eligible subscription and billing account
- A supported country or region
- Anthropic Marketplace access
- Accurate legal organization attestation values

Review the Anthropic commercial terms, usage policy, supported-region policy,
and the matching live Azure Marketplace offer before continuing. Terraform
sends the organization name, country, and industry from your variable file to
accept that offer during deployment.

## 3. Configure Variables

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

## 4. Validate and Deploy

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

## 5. Create an APIM Subscription

Both APIs are attached to the published `ai-gateway` product. Create a
subscription and retrieve its key:

```powershell
$apimName = terraform output -raw api_management_name
$resourceGroup = terraform output -raw resource_group_name

az apim subscription create `
  --resource-group $resourceGroup `
  --service-name $apimName `
  --subscription-id workshop-app `
  --display-name "Workshop application" `
  --scope "/products/ai-gateway"

$subscriptionKey = az apim subscription keys list `
  --resource-group $resourceGroup `
  --service-name $apimName `
  --subscription-id workshop-app `
  --query primaryKey --output tsv
```

Treat the subscription key as a secret. It is intentionally not a Terraform
output.

## 6. Test GPT

```powershell
$gptUrl = terraform output -raw gpt_api_url
$headers = @{
  "Ocp-Apim-Subscription-Key" = $subscriptionKey
  "Content-Type"              = "application/json"
}
$body = @{
  messages   = @(@{ role = "user"; content = "Give one Azure workshop tip." })
  max_tokens = 100
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Method Post -Uri $gptUrl -Headers $headers -Body $body
```

## 7. Test Claude

The request body uses the deployment name `claude`, not the catalog model ID.

```powershell
$claudeUrl = terraform output -raw claude_api_url
$body = @{
  model      = "claude"
  max_tokens = 100
  messages   = @(@{ role = "user"; content = "Give one Azure workshop tip." })
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Method Post -Uri $claudeUrl -Headers $headers -Body $body
```

## 8. Verify Monitoring

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
| Quota or opaque `715-123420` error | Reduce capacity, check quota, and check soft-deleted cognitive accounts that may hold quota. |
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