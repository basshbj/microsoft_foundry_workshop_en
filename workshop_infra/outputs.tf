output "resource_group_name" {
  description = "Resource group containing the workshop resources."
  value       = azurerm_resource_group.main.name
}

output "foundry_account_id" {
  description = "Resource ID of the Microsoft Foundry account."
  value       = azurerm_cognitive_account.foundry.id
}

output "foundry_project_id" {
  description = "Resource ID of the Microsoft Foundry project."
  value       = azurerm_cognitive_account_project.main.id
}

output "foundry_endpoint" {
  description = "Microsoft Foundry account endpoint."
  value       = azurerm_cognitive_account.foundry.endpoint
}

output "api_management_gateway_url" {
  description = "Base URL of the API Management gateway."
  value       = azurerm_api_management.main.gateway_url
}

output "api_management_name" {
  description = "Name of the API Management service."
  value       = azurerm_api_management.main.name
}

output "gpt_api_url" {
  description = "GPT chat-completions route exposed through API Management."
  value       = "${azurerm_api_management.main.gateway_url}/gpt/chat/completions"
}

output "claude_api_url" {
  description = "Claude Messages API route exposed through API Management."
  value       = "${azurerm_api_management.main.gateway_url}/claude/v1/messages"
}


output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.main.id
}

output "application_insights_name" {
  description = "Name of the workspace-based Application Insights resource."
  value       = azurerm_application_insights.main.name
}