# Template Explanation

## Request Flow

1. An application calls API Management with an APIM subscription key.
2. APIM applies the model route's token limit and Content Safety policy.
3. APIM obtains a Microsoft Entra token with its system-assigned identity.
4. APIM forwards the request to GPT or Claude in Microsoft Foundry.
5. APIM sends gateway and LLM telemetry to Log Analytics and request telemetry
   to workspace-based Application Insights.

## Resources

| Resource | Configuration and purpose |
| --- | --- |
| Resource group | Contains all attendee workshop resources. |
| User-assigned identity | Assigned to the Foundry project and granted Foundry User. |
| Foundry account | `AIServices`, S0, project management enabled, local keys disabled. |
| Foundry project | Uses the user-assigned identity. |
| GPT deployment | AzureRM deployment named `gpt`; model/version/SKU/capacity are inputs. |
| Claude deployment | AzAPI child named `claude`; includes required Anthropic Marketplace attestation. |
| Content Safety | S0 resource used by both APIM policies; local keys disabled. |
| API Management | Basic v2 with a system-assigned identity and subscription-protected APIs. |
| Log Analytics | PerGB2018 workspace with 30-day retention. |
| Application Insights | Workspace-based request and dependency telemetry. |

Claude uses one `azapi_resource` because the AzureRM deployment schema does
not expose Anthropic's required `modelProviderData` block. Schema validation is
disabled only for that resource; the payload uses the documented
`Microsoft.CognitiveServices/accounts/deployments@2026-05-01` contract.

## APIs and Policies

### GPT

- Public route: `POST /gpt/chat/completions`
- Backend: Foundry account's Azure OpenAI endpoint and deployment `gpt`
- Authentication audience: `https://cognitiveservices.azure.com`
- Token policy: `azure-openai-token-limit`

### Claude

- Public route: `POST /claude/v1/messages`
- Backend: Foundry account's Anthropic endpoint
- Authentication audience: `https://ai.azure.com`
- Required header: `anthropic-version: 2023-06-01`
- Token policy: `llm-token-limit`, which supports the Anthropic Messages API on
  APIM v2 tiers

Both policies use the APIM subscription ID as the counter key, so each
application subscription gets an independent token bucket. Both policies also
run `llm-content-safety` on prompts and completions for Hate, SelfHarm, Sexual,
and Violence. The default severity threshold is 4 and is configurable.

## Identity and RBAC

APIM has:

- Foundry User on the Foundry account
- Cognitive Services User on Content Safety

The project identity has Foundry User on the Foundry account. When
`attendee_principal_id` is set, the attendee receives Contributor and Role
Based Access Control Administrator on the resource group, Foundry User on the
Foundry account, and Log Analytics Reader on the workspace.

The RBAC administrator role is needed only for workshop participants who must
manage role assignments. Omit the attendee object ID when those permissions
are not required.

## Monitoring

The APIM Azure Monitor diagnostic setting enables:

- `GatewayLogs` in `ApiManagementGatewayLogs`
- `GatewayLlmLogs` in `ApiManagementGatewayLlmLog`
- `AllMetrics`

The APIM Application Insights logger uses W3C correlation and 100 percent
sampling for the workshop. It logs selected non-secret headers and zero body
bytes, preventing prompts, completions, authorization headers, and APIM
subscription keys from being copied into Application Insights by default.

## Inputs and Outputs

Naming, region, publisher information, model catalog values, capacities, token
limits, Content Safety threshold, tags, and optional attendee identity are
inputs. Claude's legal organization attestation is also required.

Outputs contain resource IDs and gateway URLs only. Keys, connection strings,
and other credentials are deliberately excluded.

## Intentionally Excluded

To keep the workshop focused, the template does not deploy application code,
private endpoints, VNets, semantic caching, Redis, load balancing, multi-region
failover, custom domains, alerts, dashboards, remote Terraform state, or CI/CD.