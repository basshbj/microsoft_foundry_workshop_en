locals {
  private_dns_zones = {
    cognitive_services = "privatelink.cognitiveservices.azure.com"
    openai             = "privatelink.openai.azure.com"
    ai_services        = "privatelink.services.ai.azure.com"
    monitor            = "privatelink.monitor.azure.com"
    monitor_oms        = "privatelink.oms.opinsights.azure.com"
    monitor_ods        = "privatelink.ods.opinsights.azure.com"
    monitor_automation = "privatelink.agentsvc.azure-automation.net"
    monitor_blob       = "privatelink.blob.core.windows.net"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = local.names.virtual_network
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.virtual_network_address_space
  tags                = local.tags
}

resource "azurerm_network_security_group" "api_management" {
  name                = "nsg-${local.names.apim_subnet}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  security_rule {
    name                       = "AllowStorageDependency"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Storage"
  }

  security_rule {
    name                       = "AllowKeyVaultDependency"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureKeyVault"
  }
}

resource "azurerm_subnet" "api_management" {
  name                 = local.names.apim_subnet
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.api_management_subnet_address_prefixes

  delegation {
    name = "api-management-outbound-integration"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "api_management" {
  subnet_id                 = azurerm_subnet.api_management.id
  network_security_group_id = azurerm_network_security_group.api_management.id
}

resource "azurerm_subnet" "private_endpoints" {
  name                              = local.names.private_endpoint_subnet
  resource_group_name               = azurerm_resource_group.main.name
  virtual_network_name              = azurerm_virtual_network.main.name
  address_prefixes                  = var.private_endpoint_subnet_address_prefixes
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_private_dns_zone" "ai" {
  for_each = local.private_dns_zones

  name                = each.value
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "ai" {
  for_each = local.private_dns_zones

  name                  = "link-${each.key}-${local.suffix}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.ai[each.key].name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_endpoint" "foundry" {
  name                = "pe-${local.names.foundry_account}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-${local.names.foundry_account}"
    private_connection_resource_id = azurerm_cognitive_account.foundry.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "ai-services"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai["cognitive_services"].id,
      azurerm_private_dns_zone.ai["openai"].id,
      azurerm_private_dns_zone.ai["ai_services"].id
    ]
  }

  depends_on = [azapi_resource.claude]
  #depends_on = [azurerm_cognitive_deployment.gpt]
}

resource "azurerm_private_endpoint" "content_safety" {
  name                = "pe-${local.names.content_safety}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-${local.names.content_safety}"
    private_connection_resource_id = azurerm_cognitive_account.content_safety.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "cognitive-services"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai["cognitive_services"].id
    ]
  }
}

resource "azurerm_monitor_private_link_scope" "main" {
  name                  = local.names.monitor_private_link
  resource_group_name   = azurerm_resource_group.main.name
  ingestion_access_mode = "PrivateOnly"
  query_access_mode     = "PrivateOnly"
  tags                  = local.tags
}

resource "azurerm_monitor_private_link_scoped_service" "log_analytics" {
  name                = "ampls-log-analytics"
  resource_group_name = azurerm_resource_group.main.name
  scope_name          = azurerm_monitor_private_link_scope.main.name
  linked_resource_id  = azurerm_log_analytics_workspace.main.id
}

resource "azurerm_monitor_private_link_scoped_service" "application_insights" {
  name                = "ampls-application-insights"
  resource_group_name = azurerm_resource_group.main.name
  scope_name          = azurerm_monitor_private_link_scope.main.name
  linked_resource_id  = azurerm_application_insights.main.id
}

resource "azurerm_private_endpoint" "azure_monitor" {
  name                = "pe-${local.names.monitor_private_link}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-${local.names.monitor_private_link}"
    private_connection_resource_id = azurerm_monitor_private_link_scope.main.id
    subresource_names              = ["azuremonitor"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "azure-monitor"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai["monitor"].id,
      azurerm_private_dns_zone.ai["monitor_oms"].id,
      azurerm_private_dns_zone.ai["monitor_ods"].id,
      azurerm_private_dns_zone.ai["monitor_automation"].id,
      azurerm_private_dns_zone.ai["monitor_blob"].id
    ]
  }

  depends_on = [
    azurerm_monitor_private_link_scoped_service.log_analytics,
    azurerm_monitor_private_link_scoped_service.application_insights
  ]
}