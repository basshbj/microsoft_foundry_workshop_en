# Private network Terraform variant

This directory deploys the same workshop services as `../infra` with private backend connectivity:

- API Management uses the Standard v2 tier and keeps its gateway, management plane, and developer portal public.
- API Management uses outbound virtual network integration through a dedicated delegated subnet.
- Microsoft Foundry and Content Safety disable public network access.
- Private endpoints and Azure Private DNS provide access to the Foundry, Azure OpenAI, and Cognitive Services host names.
- An Azure Monitor Private Link Scope isolates Log Analytics and Application Insights ingestion and queries.
- A separate subnet hosts private endpoints.

The private deployment uses `-private-` in resource names so it can coexist with the public workshop deployment.

## Deploy

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform plan -out main.tfplan
terraform apply main.tfplan
```

Clients call the public API Management gateway. Direct calls to the Microsoft Foundry and Content Safety endpoints, and direct queries of the monitoring resources, require connectivity to the virtual network and its private DNS zones.