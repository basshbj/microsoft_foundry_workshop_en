variable "prefix" {
  description = "Short prefix used in resource names."
  type        = string
  default     = "foundry"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,12}$", var.prefix))
    error_message = "prefix must contain 2-12 lowercase letters, numbers, or hyphens."
  }
}

variable "attendee" {
  description = "Workshop attendee identifier used in resource names."
  type        = string
  default     = "demo"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,16}$", var.attendee))
    error_message = "attendee must contain 2-16 lowercase letters, numbers, or hyphens."
  }
}

variable "location" {
  description = "Azure region that offers the selected models and the AI Gateway preview tier."
  type        = string
  default     = "eastus2"

  validation {
    condition     = contains(["eastus2", "swedencentral"], lower(var.location))
    error_message = "location must be eastus2 or swedencentral while the AI Gateway tier is in preview."
  }
}

variable "publisher_name" {
  description = "API publisher name displayed by API Management."
  type        = string
  default     = "Foundry Workshop"
}

variable "publisher_email" {
  description = "API publisher email required by API Management."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.publisher_email))
    error_message = "publisher_email must be a valid email address."
  }
}

variable "attendee_principal_id" {
  description = "Optional Microsoft Entra object ID that receives workshop RBAC assignments."
  type        = string
  default     = null
  nullable    = true
}

variable "gpt_model" {
  description = "GPT model deployment settings. Verify availability and quota in the target region."
  type = object({
    name     = string
    version  = string
    sku_name = string
    capacity = number
  })
  default = {
    name     = "gpt-4o-mini"
    version  = "2024-07-18"
    sku_name = "GlobalStandard"
    capacity = 10
  }

  validation {
    condition     = var.gpt_model.capacity > 0
    error_message = "gpt_model.capacity must be greater than zero."
  }
}

variable "claude_model" {
  description = "Claude model deployment settings. Verify Marketplace eligibility, availability, and quota first."
  type = object({
    name     = string
    version  = string
    sku_name = string
    capacity = number
  })
  default = {
    name     = "claude-sonnet-4-6"
    version  = "1" # 1 - Anthropic Hosted ; 2 - Azure Hosted
    sku_name = "GlobalStandard"
    capacity = 10
  }

  validation {
    condition     = var.claude_model.capacity > 0
    error_message = "claude_model.capacity must be greater than zero."
  }
}

variable "claude_organization_name" {
  description = "Legal organization name submitted to accept the Anthropic Marketplace offer."
  type        = string

  validation {
    condition     = length(trimspace(var.claude_organization_name)) > 1
    error_message = "claude_organization_name must be the legal name of the organization using Claude."
  }
}

variable "claude_country_code" {
  description = "Two-letter country code submitted for the Anthropic Marketplace attestation."
  type        = string
  default     = "US"

  validation {
    condition     = can(regex("^[A-Z]{2}$", var.claude_country_code))
    error_message = "claude_country_code must be a two-letter uppercase country code."
  }
}

variable "claude_industry" {
  description = "Industry submitted for the Anthropic Marketplace attestation."
  type        = string
  default     = "technology"

  validation {
    condition = contains([
      "technology", "finance", "healthcare", "education", "retail",
      "manufacturing", "government", "media", "other"
    ], var.claude_industry)
    error_message = "claude_industry must be one of the supported Anthropic attestation values."
  }
}

variable "gpt_tokens_per_minute" {
  description = "Per-subscription GPT token limit enforced by API Management."
  type        = number
  default     = 10000
}

variable "claude_tokens_per_minute" {
  description = "Per-subscription Claude token limit enforced by API Management."
  type        = number
  default     = 10000
}

variable "content_safety_threshold" {
  description = "Content Safety severity threshold for Hate, SelfHarm, Sexual, and Violence categories."
  type        = number
  default     = 4

  validation {
    condition     = var.content_safety_threshold >= 0 && var.content_safety_threshold <= 7
    error_message = "content_safety_threshold must be between 0 and 7."
  }
}

variable "tags" {
  description = "Additional tags applied to resources."
  type        = map(string)
  default     = {}
}