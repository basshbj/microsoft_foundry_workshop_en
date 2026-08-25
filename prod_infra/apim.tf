resource "azurerm_api_management" "main" {
  name                          = local.names.api_management
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  publisher_name                = var.publisher_name
  publisher_email               = var.publisher_email
  sku_name                      = "StandardV2_1"
  public_network_access_enabled = true
  virtual_network_type          = "External"

  virtual_network_configuration {
    subnet_id = azurerm_subnet.api_management.id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags

  depends_on = [azurerm_subnet_network_security_group_association.api_management]
}

# --- GPT ---
resource "azurerm_api_management_backend" "gpt" {
  name                = "gpt-backend"
  resource_group_name = azurerm_resource_group.main.name
  api_management_name = azurerm_api_management.main.name
  protocol            = "http"
  url                 = "https://${azurerm_cognitive_account.foundry.name}.openai.azure.com/openai/deployments/${azurerm_cognitive_deployment.gpt.name}"
}

resource "azurerm_api_management_api" "gpt" {
  name                  = "gpt-api"
  resource_group_name   = azurerm_resource_group.main.name
  api_management_name   = azurerm_api_management.main.name
  revision              = "1"
  display_name          = "GPT Chat Completions"
  path                  = "gpt"
  protocols             = ["https"]
  subscription_required = true
}

resource "azurerm_api_management_api_operation" "gpt_chat" {
  operation_id        = "gpt-chat-completions"
  api_name            = azurerm_api_management_api.gpt.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Create chat completion"
  method              = "POST"
  url_template        = "/chat/completions"

  request {
    description = "OpenAI-compatible chat completion request."

    representation {
      content_type = "application/json"
    }
  }

  response {
    status_code = 200
    description = "Chat completion response."
  }
}

resource "azurerm_api_management_api_policy" "gpt" {
  api_name            = azurerm_api_management_api.gpt.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name

  xml_content = templatefile("${path.module}/policies/gpt-policy.xml.tftpl", {
    backend_id                = azurerm_api_management_backend.gpt.name
    content_safety_backend_id = azurerm_api_management_backend.content_safety.name
    tokens_per_minute         = var.gpt_tokens_per_minute
    content_safety_threshold  = var.content_safety_threshold
  })
}

# --- Claude ---
resource "azurerm_api_management_backend" "claude" {
  name                = "claude-backend"
  resource_group_name = azurerm_resource_group.main.name
  api_management_name = azurerm_api_management.main.name
  protocol            = "http"
  url                 = "https://${azurerm_cognitive_account.foundry.name}.services.ai.azure.com/anthropic"
}

resource "azurerm_api_management_api" "claude" {
  name                  = "claude-api"
  resource_group_name   = azurerm_resource_group.main.name
  api_management_name   = azurerm_api_management.main.name
  revision              = "1"
  display_name          = "Claude Messages"
  path                  = "claude"
  protocols             = ["https"]
  subscription_required = true
}

resource "azurerm_api_management_api_operation" "claude_messages" {
  operation_id        = "claude-messages"
  api_name            = azurerm_api_management_api.claude.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Create Claude message"
  method              = "POST"
  url_template        = "/v1/messages"

  request {
    description = "Anthropic Messages API request with model set to the Claude deployment name."

    representation {
      content_type = "application/json"
    }
  }

  response {
    status_code = 200
    description = "Claude Messages API response."
  }
}

resource "azurerm_api_management_api_policy" "claude" {
  api_name            = azurerm_api_management_api.claude.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name

  xml_content = templatefile("${path.module}/policies/claude-policy.xml.tftpl", {
    backend_id                = azurerm_api_management_backend.claude.name
    content_safety_backend_id = azurerm_api_management_backend.content_safety.name
    tokens_per_minute         = var.claude_tokens_per_minute
    content_safety_threshold  = var.content_safety_threshold
  })
}

# --- Content Safety ---
resource "azurerm_api_management_backend" "content_safety" {
  name                = "content-safety-backend"
  resource_group_name = azurerm_resource_group.main.name
  api_management_name = azurerm_api_management.main.name
  protocol            = "http"
  url                 = azurerm_cognitive_account.content_safety.endpoint

  credentials {
    authorization {
      scheme    = "ManagedIdentity"
      parameter = "https://cognitiveservices.azure.com"
    }
  }
}