locals {
  suffix = "${var.prefix}-private-${var.attendee}"

  names = {
    resource_group          = "rg-${local.suffix}"
    foundry_account         = "ai-${local.suffix}"
    foundry_project         = "project-${var.attendee}"
    content_safety          = "cs-${local.suffix}"
    api_management          = "apim-${local.suffix}"
    virtual_network         = "vnet-${local.suffix}"
    apim_subnet             = "snet-apim-${local.suffix}"
    private_endpoint_subnet = "snet-pe-${local.suffix}"
    monitor_private_link    = "ampls-${local.suffix}"
    log_analytics           = "log-${local.suffix}"
    application_insights    = "appi-${local.suffix}"
  }

  tags = merge(
    {
      type = "workshop"
    },
    var.tags
  )
}

# --- Resource Group ---
resource "azurerm_resource_group" "main" {
  name     = local.names.resource_group
  location = var.location
  tags     = local.tags
}

# --- Foundry Account ---
resource "azurerm_cognitive_account" "foundry" {
  name                          = local.names.foundry_account
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  kind                          = "AIServices"
  sku_name                      = "S0"
  custom_subdomain_name         = local.names.foundry_account
  project_management_enabled    = true
  local_auth_enabled            = false
  public_network_access_enabled = false

  identity {
    type = "SystemAssigned"
  }

  network_acls {
    default_action = "Deny"
  }

  tags = local.tags
}

# --- Foundry Project ---
resource "azurerm_cognitive_account_project" "main" {
  name                 = local.names.foundry_project
  cognitive_account_id = azurerm_cognitive_account.foundry.id
  location             = azurerm_resource_group.main.location
  display_name         = "Foundry workshop project for ${var.attendee}"

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

# --- Foundry User Role Assignment for Foundry Project ---
resource "azurerm_role_assignment" "project_identity_foundry_user" {
  scope                = azurerm_cognitive_account.foundry.id
  role_definition_name = "Foundry User"
  principal_id         = azurerm_cognitive_account_project.main.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# --- Foundry GPT Deployment ---
resource "azurerm_cognitive_deployment" "gpt" {
  name                   = "gpt"
  cognitive_account_id   = azurerm_cognitive_account.foundry.id
  version_upgrade_option = "OnceCurrentVersionExpired"

  model {
    format  = "OpenAI"
    name    = var.gpt_model.name
    version = var.gpt_model.version
  }

  sku {
    name     = var.gpt_model.sku_name
    capacity = var.gpt_model.capacity
  }

  depends_on = [azurerm_cognitive_account_project.main]
}

# --- Foundry Claude Deployment ---
resource "azapi_resource" "claude" {
  type                      = "Microsoft.CognitiveServices/accounts/deployments@2026-05-01"
  name                      = "claude"
  parent_id                 = azurerm_cognitive_account.foundry.id
  schema_validation_enabled = false

  body = {
    properties = {
      model = {
        format  = "Anthropic"
        name    = var.claude_model.name
        version = var.claude_model.version
      }
      modelProviderData = {
        organizationName = var.claude_organization_name
        countryCode      = var.claude_country_code
        industry         = var.claude_industry
      }
      versionUpgradeOption = "OnceCurrentVersionExpired"
      raiPolicyName        = "Microsoft.DefaultV2"
    }
    sku = {
      name     = var.claude_model.sku_name
      capacity = var.claude_model.capacity
    }
  }

  depends_on = [azurerm_cognitive_deployment.gpt]
}

# --- Content Safety Account ---
resource "azurerm_cognitive_account" "content_safety" {
  name                          = local.names.content_safety
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  kind                          = "ContentSafety"
  sku_name                      = "S0"
  custom_subdomain_name         = local.names.content_safety
  local_auth_enabled            = false
  public_network_access_enabled = false

  network_acls {
    default_action = "Deny"
  }

  tags = local.tags
}

# --- Log Analytics Workspace ---
resource "azurerm_log_analytics_workspace" "main" {
  name                       = local.names.log_analytics
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  sku                        = "PerGB2018"
  retention_in_days          = 30
  internet_ingestion_enabled = false
  internet_query_enabled     = false
  tags                       = local.tags
}

# --- Application Insights ---
resource "azurerm_application_insights" "main" {
  name                       = local.names.application_insights
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  workspace_id               = azurerm_log_analytics_workspace.main.id
  application_type           = "web"
  retention_in_days          = 30
  internet_ingestion_enabled = false
  internet_query_enabled     = false
  tags                       = local.tags
}