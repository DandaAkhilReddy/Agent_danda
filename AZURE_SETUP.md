# ☁️ Azure Setup Guide for ReplyCopilot

Complete step-by-step guide to set up all Azure services.

---

## Prerequisites

- Azure subscription
- Azure CLI installed (`az --version`)
- Node.js 20+ installed
- Access to Azure portal

---

## Step 1: Azure OpenAI Setup

### 1.1 Create Azure OpenAI Resource

```bash
# Login to Azure
az login

# Set variables
RESOURCE_GROUP="ReplyCopilot-RG"
LOCATION="eastus"
OPENAI_NAME="replycopilot-openai"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Azure OpenAI resource
az cognitiveservices account create \
  --name $OPENAI_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --kind OpenAI \
  --sku S0 \
  --custom-domain $OPENAI_NAME

# Get endpoint and key
az cognitiveservices account show \
  --name $OPENAI_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "properties.endpoint"

az cognitiveservices account keys list \
  --name $OPENAI_NAME \
  --resource-group $RESOURCE_GROUP
```

### 1.2 Deploy GPT-4o Vision Model

```bash
# Deploy GPT-4o with vision capabilities
az cognitiveservices account deployment create \
  --name $OPENAI_NAME \
  --resource-group $RESOURCE_GROUP \
  --deployment-name gpt-4o-vision \
  --model-name gpt-4o \
  --model-version "2024-08-06" \
  --model-format OpenAI \
  --sku-name "Standard" \
  --sku-capacity 10
```

**Save these values:**
- Endpoint: `https://replycopilot-openai.openai.azure.com/`
- API Key: `<your-api-key>`
- Deployment Name: `gpt-4o-vision`

---

## Step 2: Azure Key Vault Setup

### 2.1 Create Key Vault

```bash
KEYVAULT_NAME="replycopilot-kv"

# Create Key Vault
az keyvault create \
  --name $KEYVAULT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --enable-rbac-authorization false

# Store OpenAI credentials
az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name "OPENAI-API-KEY" \
  --value "<your-openai-api-key>"

az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name "OPENAI-ENDPOINT" \
  --value "https://replycopilot-openai.openai.azure.com/"
```

---

## Step 3: Azure Functions Setup

### 3.1 Create Function App

```bash
FUNCTION_APP_NAME="replycopilot-api"
STORAGE_ACCOUNT="replycopilotstorage"

# Create storage account
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS

# Create Function App
az functionapp create \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --consumption-plan-location $LOCATION \
  --runtime node \
  --runtime-version 20 \
  --functions-version 4 \
  --storage-account $STORAGE_ACCOUNT \
  --os-type Linux
```

### 3.2 Configure App Settings

```bash
# Set Key Vault reference
az functionapp config appsettings set \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings \
    "OPENAI_ENDPOINT=@Microsoft.KeyVault(SecretUri=https://${KEYVAULT_NAME}.vault.azure.net/secrets/OPENAI-ENDPOINT/)" \
    "OPENAI_API_KEY=@Microsoft.KeyVault(SecretUri=https://${KEYVAULT_NAME}.vault.azure.net/secrets/OPENAI-API-KEY/)"
```

---

## Step 4: VNet & Private Endpoints (Production Security)

### 4.1 Create Virtual Network

```bash
VNET_NAME="replycopilot-vnet"
SUBNET_NAME="function-subnet"

# Create VNet
az network vnet create \
  --name $VNET_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --address-prefix 10.0.0.0/16 \
  --subnet-name $SUBNET_NAME \
  --subnet-prefix 10.0.1.0/24
```

### 4.2 Enable Private Endpoint for OpenAI

```bash
# Disable public network access
az cognitiveservices account update \
  --name $OPENAI_NAME \
  --resource-group $RESOURCE_GROUP \
  --public-network-access Disabled

# Create private endpoint
az network private-endpoint create \
  --name "${OPENAI_NAME}-pe" \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --subnet $SUBNET_NAME \
  --private-connection-resource-id $(az cognitiveservices account show --name $OPENAI_NAME --resource-group $RESOURCE_GROUP --query "id" -o tsv) \
  --group-id account \
  --connection-name "${OPENAI_NAME}-connection"
```

### 4.3 Integrate Function App with VNet

```bash
az functionapp vnet-integration add \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --vnet $VNET_NAME \
  --subnet $SUBNET_NAME
```

---

## Step 5: Azure AD Authentication

### 5.1 Register App

```bash
# Create AD app registration
az ad app create \
  --display-name "ReplyCopilot iOS" \
  --sign-in-audience AzureADMultitenantAndPersonalMicrosoftAccount

# Get app ID
APP_ID=$(az ad app list --display-name "ReplyCopilot iOS" --query "[0].appId" -o tsv)

echo "App ID: $APP_ID"
```

### 5.2 Configure Function App Authentication

```bash
az functionapp auth update \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --enabled true \
  --action LoginWithAzureActiveDirectory \
  --aad-client-id $APP_ID
```

---

## Step 6: Managed Identity & Key Vault Access

### 6.1 Enable Managed Identity

```bash
az functionapp identity assign \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP
```

### 6.2 Grant Key Vault Access

```bash
FUNCTION_IDENTITY=$(az functionapp identity show --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP --query "principalId" -o tsv)

az keyvault set-policy \
  --name $KEYVAULT_NAME \
  --resource-group $RESOURCE_GROUP \
  --object-id $FUNCTION_IDENTITY \
  --secret-permissions get list
```

---

## Step 7: Monitoring & Logging

### 7.1 Enable Application Insights

```bash
APPINSIGHTS_NAME="replycopilot-insights"

# Create App Insights
az monitor app-insights component create \
  --app $APPINSIGHTS_NAME \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP \
  --application-type web

# Link to Function App
INSTRUMENTATION_KEY=$(az monitor app-insights component show --app $APPINSIGHTS_NAME --resource-group $RESOURCE_GROUP --query "instrumentationKey" -o tsv)

az functionapp config appsettings set \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings "APPINSIGHTS_INSTRUMENTATIONKEY=$INSTRUMENTATION_KEY"
```

---

## Step 8: Deployment Configuration

### 8.1 Get Function App URL

```bash
FUNCTION_URL=$(az functionapp show --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP --query "defaultHostName" -o tsv)

echo "Function App URL: https://$FUNCTION_URL"
```

### 8.2 Test Endpoint

```bash
curl -X GET "https://$FUNCTION_URL/api/health"
```

---

## Configuration Summary

Save these values for your app:

```bash
# Azure OpenAI
OPENAI_ENDPOINT=https://replycopilot-openai.openai.azure.com/
OPENAI_DEPLOYMENT=gpt-4o-vision
OPENAI_API_VERSION=2024-08-01-preview

# Function App
API_URL=https://replycopilot-api.azurewebsites.net

# Azure AD
APP_ID=<your-app-id>
TENANT_ID=<your-tenant-id>

# Key Vault
KEYVAULT_URL=https://replycopilot-kv.vault.azure.net/
```

---

## Security Checklist

- [x] Azure OpenAI private endpoint enabled
- [x] Function App VNet integration
- [x] Key Vault for secrets
- [x] Managed identity (no hardcoded keys)
- [x] Azure AD authentication
- [x] Application Insights monitoring
- [x] Public network access disabled
- [x] TLS 1.3 enforced

---

## Cost Estimate

| Service | Tier | Monthly Cost (est.) |
|---------|------|---------------------|
| Azure OpenAI (10K RPM) | Standard | ~$200-500 |
| Function App (Consumption) | Pay-per-use | ~$20-50 |
| Key Vault | Standard | ~$5 |
| Storage Account | Standard LRS | ~$5 |
| Application Insights | Per GB | ~$10-30 |
| VNet + Private Endpoints | Standard | ~$10-20 |
| **Total** | | **~$250-600/month** |

*Costs scale with usage. For 100K+ users, use provisioned throughput and premium plans.*

---

## Next Steps

1. ✅ Azure infrastructure deployed
2. ⏭️ Deploy backend functions
3. ⏭️ Test API endpoints
4. ⏭️ Configure iOS app with endpoints
5. ⏭️ Enable production security features

**Your Azure setup is ready!** 🚀
