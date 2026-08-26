# --- Application Insights Logger for API Management ---
resource "azurerm_api_management_logger" "application_insights" {
  name                = "application-insights"
  resource_group_name = azurerm_resource_group.main.name
  api_management_name = azurerm_api_management.main.name
  resource_id         = azurerm_application_insights.main.id
  buffered            = false

  application_insights {
    connection_string = azurerm_application_insights.main.connection_string
  }
}

# --- API Management Diagnostic Settings for Application Insights ---
resource "azurerm_api_management_diagnostic" "application_insights" {
  identifier               = "applicationinsights"
  resource_group_name      = azurerm_resource_group.main.name
  api_management_name      = azurerm_api_management.main.name
  api_management_logger_id = azurerm_api_management_logger.application_insights.id

  always_log_errors         = true
  http_correlation_protocol = "W3C"
  log_client_ip             = false
  sampling_percentage       = 100
  verbosity                 = "information"

  frontend_request {
    body_bytes     = 0
    headers_to_log = ["content-type", "user-agent"]
  }

  backend_request {
    body_bytes     = 0
    headers_to_log = ["content-type"]
  }

  frontend_response {
    body_bytes     = 0
    headers_to_log = ["content-type", "request-id"]
  }

  backend_response {
    body_bytes     = 0
    headers_to_log = ["content-type", "request-id"]
  }
}

# --- API Management Azure Monitor Diagnostic for LLM Logs ---
resource "azapi_resource" "azure_monitor_diagnostic" {
  type      = "Microsoft.ApiManagement/service/diagnostics@2025-09-01-preview"
  name      = "azuremonitor"
  parent_id = azurerm_api_management.main.id

  body = {
    properties = {
      loggerId                = "/loggers/azuremonitor"
      alwaysLog               = "allErrors"
      httpCorrelationProtocol = "None"
      logClientIp             = false
      verbosity               = "information"
      sampling = {
        samplingType = "fixed"
        percentage   = 100
      }
      largeLanguageModel = {
        logs = "enabled"
      }
    }
  }
}

# --- API Management Diagnostic Settings to Log Analytics ---
resource "azurerm_monitor_diagnostic_setting" "api_management" {
  name                           = "apim-to-log-analytics"
  target_resource_id             = azurerm_api_management.main.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.main.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category = "GatewayLogs"
  }

  enabled_log {
    category = "GatewayLlmLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}