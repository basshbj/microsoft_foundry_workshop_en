output "resource_group_name" {
  description = "Resource group containing the private workshop resources."
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
  description = "Microsoft Foundry account endpoint. Resolves privately from the virtual network."
  value       = azurerm_cognitive_account.foundry.endpoint
}

output "api_management_gateway_url" {
  description = "Public base URL of the API Management gateway."
  value       = azurerm_api_management.main.gateway_url
}

output "api_management_name" {
  description = "Name of the API Management service."
  value       = azurerm_api_management.main.name
}

output "gpt_api_url" {
  description = "Public GPT chat-completions route exposed through API Management."
  value       = "${azurerm_api_management.main.gateway_url}/gpt/chat/completions"
}

output "claude_api_url" {
  description = "Public Claude Messages API route exposed through API Management."
  value       = "${azurerm_api_management.main.gateway_url}/claude/v1/messages"
}

output "virtual_network_id" {
  description = "Resource ID of the workshop virtual network."
  value       = azurerm_virtual_network.main.id
}

output "api_management_subnet_id" {
  description = "Resource ID of the API Management outbound integration subnet."
  value       = azurerm_subnet.api_management.id
}

output "private_endpoint_subnet_id" {
  description = "Resource ID of the private endpoint subnet."
  value       = azurerm_subnet.private_endpoints.id
}

output "foundry_private_ip_address" {
  description = "Private IP address assigned to the Microsoft Foundry private endpoint."
  value       = azurerm_private_endpoint.foundry.private_service_connection[0].private_ip_address
}

output "content_safety_private_ip_address" {
  description = "Private IP address assigned to the Content Safety private endpoint."
  value       = azurerm_private_endpoint.content_safety.private_service_connection[0].private_ip_address
}

output "azure_monitor_private_link_scope_id" {
  description = "Resource ID of the Azure Monitor Private Link Scope."
  value       = azurerm_monitor_private_link_scope.main.id
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.main.id
}

output "application_insights_name" {
  description = "Name of the workspace-based Application Insights resource."
  value       = azurerm_application_insights.main.name
}