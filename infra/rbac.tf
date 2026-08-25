# --- Role Assignments: APIM - Foundry User ---
resource "azurerm_role_assignment" "apim_foundry_user" {
  scope                = azurerm_cognitive_account.foundry.id
  role_definition_name = "Foundry User"
  principal_id         = azurerm_api_management.main.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# --- Role Assignments: APIM - Content Safety User ---
resource "azurerm_role_assignment" "apim_content_safety_user" {
  scope                = azurerm_cognitive_account.content_safety.id
  role_definition_name = "Cognitive Services User"
  principal_id         = azurerm_api_management.main.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# --- Role Assignments: APIM - Log Analytics Reader ---
resource "azurerm_role_assignment" "attendee_contributor" {
  count = var.attendee_principal_id == null ? 0 : 1

  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = var.attendee_principal_id
}

# --- Role Assignments: User - Role Based Access Control Administrator ---
resource "azurerm_role_assignment" "attendee_rbac_admin" {
  count = var.attendee_principal_id == null ? 0 : 1

  scope                = azurerm_resource_group.main.id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = var.attendee_principal_id
}

# --- Role Assignments: User - Foundry User ---
resource "azurerm_role_assignment" "attendee_foundry_user" {
  count = var.attendee_principal_id == null ? 0 : 1

  scope                = azurerm_cognitive_account.foundry.id
  role_definition_name = "Foundry User"
  principal_id         = var.attendee_principal_id
}
# --- Role Assignments: User - Content Safety User ---
resource "azurerm_role_assignment" "attendee_content_safety_user" {
  count = var.attendee_principal_id == null ? 0 : 1

  scope                = azurerm_cognitive_account.content_safety.id
  role_definition_name = "Cognitive Services User"
  principal_id         = var.attendee_principal_id
}

# --- Role Assignments: User - Log Analytics Reader ---
resource "azurerm_role_assignment" "attendee_log_analytics_reader" {
  count = var.attendee_principal_id == null ? 0 : 1

  scope                = azurerm_log_analytics_workspace.main.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = var.attendee_principal_id
}