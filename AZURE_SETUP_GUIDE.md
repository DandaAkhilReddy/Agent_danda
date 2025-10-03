# ☁️ Azure Backend Setup Guide for ReplyCopilot

Complete step-by-step guide to deploy the ReplyCopilot backend to Azure with OpenAI GPT-4o Vision integration.

---

## 📋 Overview

Azure services we'll use:
- **Azure Functions** - Serverless API backend
- **Azure OpenAI** - GPT-4o Vision model for reply generation
- **Azure Key Vault** - Secure secrets management
- **Application Insights** - Monitoring and analytics
- **Azure Storage** - Function app storage

**Estimated cost**: $50-200/month depending on usage

---

## 🚀 Step 1: Prerequisites

### 1.1 Install Required Tools

**Azure CLI:**
```bash
# Windows (PowerShell)
# Download from: https://aka.ms/installazurecliwindows

# macOS
brew install azure-cli

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**Azure Functions Core Tools:**
```bash
# Windows
npm install -g azure-functions-core-tools@4

# macOS
brew tap azure/functions
brew install azure-functions-core-tools@4

# Linux
npm install -g azure-functions-core-tools@4
```

**Node.js 18+ (if not installed):**
```bash
# Download from: https://nodejs.org
# Or use nvm:
nvm install 18
nvm use 18
```

### 1.2 Verify Installation

```bash
az --version
# Should show: azure-cli 2.50.0 or higher

func --version
# Should show: 4.x.x

node --version
# Should show: v18.x.x or higher
```

---

## 🔐 Step 2: Azure Account Setup

### 2.1 Login to Azure

```bash
az login
```

This will:
1. Open browser for authentication
2. Select your Azure account
3. Confirm login in terminal

### 2.2 Select Subscription

List subscriptions:
```bash
az account list --output table
```

Set active subscription:
```bash
az account set --subscription "YOUR_SUBSCRIPTION_NAME_OR_ID"
```

Verify:
```bash
az account show
```

---

## 📦 Step 3: Create Resource Group

### 3.1 Choose Azure Region

Pick closest region to your users:
- `eastus` - East US (Virginia)
- `westus2` - West US (Washington)
- `centralus` - Central US (Iowa)
- `northeurope` - North Europe (Ireland)
- `westeurope` - West Europe (Netherlands)
- `southeastasia` - Southeast Asia (Singapore)

### 3.2 Create Resource Group

```bash
az group create \
  --name replycopilot-rg \
  --location eastus
```

Expected output:
```json
{
  "id": "/subscriptions/.../resourceGroups/replycopilot-rg",
  "location": "eastus",
  "name": "replycopilot-rg",
  "properties": {
    "provisioningState": "Succeeded"
  }
}
```

---

## 🧠 Step 4: Create Azure OpenAI Resource

### 4.1 Request Access (if first time)

1. Go to: https://aka.ms/oai/access
2. Fill out request form
3. Wait for approval (usually 1-2 business days)
4. You'll receive email confirmation

### 4.2 Create Azure OpenAI Service

```bash
az cognitiveservices account create \
  --name replycopilot-openai \
  --resource-group replycopilot-rg \
  --location eastus \
  --kind OpenAI \
  --sku S0 \
  --yes
```

**Note**: Not all regions support Azure OpenAI. If you get an error, try:
- `eastus`
- `southcentralus`
- `westeurope`

### 4.3 Deploy GPT-4o Vision Model

```bash
az cognitiveservices account deployment create \
  --name replycopilot-openai \
  --resource-group replycopilot-rg \
  --deployment-name gpt-4o \
  --model-name gpt-4o \
  --model-version "2024-05-13" \
  --model-format OpenAI \
  --sku-capacity 10 \
  --sku-name "Standard"
```

**Capacity notes:**
- 10 = 10K tokens/minute (good for testing)
- 30 = 30K tokens/minute (good for production with <1K users)
- 100 = 100K tokens/minute (good for 10K+ users)

### 4.4 Get OpenAI Keys

```bash
az cognitiveservices account keys list \
  --name replycopilot-openai \
  --resource-group replycopilot-rg
```

Save these values:
```
KEY1: [Your primary key]
KEY2: [Your secondary key]
```

Get endpoint:
```bash
az cognitiveservices account show \
  --name replycopilot-openai \
  --resource-group replycopilot-rg \
  --query "properties.endpoint" \
  --output tsv
```

Save this value:
```
ENDPOINT: https://replycopilot-openai.openai.azure.com/
```

---

## 🔑 Step 5: Create Azure Key Vault

### 5.1 Create Key Vault

```bash
az keyvault create \
  --name replycopilot-kv \
  --resource-group replycopilot-rg \
  --location eastus \
  --enable-soft-delete true \
  --enable-purge-protection false
```

**Note**: Key Vault name must be globally unique. If taken, try:
- `replycopilot-kv-123`
- `replycopilot-vault`
- `rc-keyvault-xyz`

### 5.2 Store Secrets

Store OpenAI key:
```bash
az keyvault secret set \
  --vault-name replycopilot-kv \
  --name "AZURE-OPENAI-KEY" \
  --value "YOUR_OPENAI_KEY_FROM_STEP_4"
```

Store OpenAI endpoint:
```bash
az keyvault secret set \
  --vault-name replycopilot-kv \
  --name "AZURE-OPENAI-ENDPOINT" \
  --value "YOUR_OPENAI_ENDPOINT_FROM_STEP_4"
```

Store deployment name:
```bash
az keyvault secret set \
  --vault-name replycopilot-kv \
  --name "AZURE-OPENAI-DEPLOYMENT" \
  --value "gpt-4o"
```

---

## 📊 Step 6: Create Application Insights

### 6.1 Create App Insights

```bash
az monitor app-insights component create \
  --app replycopilot-insights \
  --location eastus \
  --resource-group replycopilot-rg \
  --application-type web
```

### 6.2 Get Instrumentation Key

```bash
az monitor app-insights component show \
  --app replycopilot-insights \
  --resource-group replycopilot-rg \
  --query "instrumentationKey" \
  --output tsv
```

Save this value:
```
INSTRUMENTATION_KEY: [Your instrumentation key]
```

Get Connection String:
```bash
az monitor app-insights component show \
  --app replycopilot-insights \
  --resource-group replycopilot-rg \
  --query "connectionString" \
  --output tsv
```

Save this value:
```
CONNECTION_STRING: [Your connection string]
```

---

## 💾 Step 7: Create Storage Account

### 7.1 Create Storage Account

```bash
az storage account create \
  --name replycopilotstorage \
  --resource-group replycopilot-rg \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2
```

**Note**: Storage account name must be:
- 3-24 characters
- Lowercase letters and numbers only
- Globally unique

If taken, try: `rcstorageXYZ` where XYZ is random

### 7.2 Get Connection String

```bash
az storage account show-connection-string \
  --name replycopilotstorage \
  --resource-group replycopilot-rg \
  --output tsv
```

Save this value:
```
STORAGE_CONNECTION_STRING: [Your storage connection string]
```

---

## ⚡ Step 8: Create Function App

### 8.1 Create Function App

```bash
az functionapp create \
  --name replycopilot-api \
  --resource-group replycopilot-rg \
  --storage-account replycopilotstorage \
  --consumption-plan-location eastus \
  --runtime node \
  --runtime-version 18 \
  --functions-version 4 \
  --os-type Linux \
  --disable-app-insights false \
  --app-insights replycopilot-insights
```

**Note**: Function app name must be globally unique DNS name. If taken, try:
- `replycopilot-api-xyz`
- `rc-api-123`

### 8.2 Configure Function App Settings

Add Application Insights:
```bash
az functionapp config appsettings set \
  --name replycopilot-api \
  --resource-group replycopilot-rg \
  --settings "APPINSIGHTS_INSTRUMENTATIONKEY=YOUR_INSTRUMENTATION_KEY"
```

Add Azure OpenAI settings:
```bash
az functionapp config appsettings set \
  --name replycopilot-api \
  --resource-group replycopilot-rg \
  --settings \
    "AZURE_OPENAI_KEY=YOUR_OPENAI_KEY" \
    "AZURE_OPENAI_ENDPOINT=YOUR_OPENAI_ENDPOINT" \
    "AZURE_OPENAI_DEPLOYMENT=gpt-4o" \
    "AZURE_OPENAI_API_VERSION=2024-02-15-preview"
```

Enable CORS (for web access):
```bash
az functionapp cors add \
  --name replycopilot-api \
  --resource-group replycopilot-rg \
  --allowed-origins "https://replycopilot.com" "http://localhost:3000"
```

---

## 📝 Step 9: Prepare Backend Code

### 9.1 Navigate to Backend Folder

```bash
cd C:\users\akhil\projects\ReplyCopilot\backend
```

### 9.2 Install Dependencies

```bash
npm install
```

### 9.3 Create local.settings.json

Create `backend/local.settings.json` for local testing:

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "",
    "FUNCTIONS_WORKER_RUNTIME": "node",
    "AZURE_OPENAI_KEY": "YOUR_OPENAI_KEY_HERE",
    "AZURE_OPENAI_ENDPOINT": "YOUR_OPENAI_ENDPOINT_HERE",
    "AZURE_OPENAI_DEPLOYMENT": "gpt-4o",
    "AZURE_OPENAI_API_VERSION": "2024-02-15-preview",
    "APPINSIGHTS_INSTRUMENTATIONKEY": "YOUR_INSTRUMENTATION_KEY"
  },
  "Host": {
    "CORS": "*",
    "CORSCredentials": false
  }
}
```

**IMPORTANT**: Add to `.gitignore`:
```
local.settings.json
```

---

## 🚀 Step 10: Deploy Backend to Azure

### 10.1 Test Locally First

```bash
cd C:\users\akhil\projects\ReplyCopilot\backend
func start
```

Expected output:
```
Functions:
  generateReplies: [POST] http://localhost:7071/api/generateReplies

For detailed output, run func with --verbose flag.
```

Test with curl or Postman:
```bash
curl -X POST http://localhost:7071/api/generateReplies \
  -H "Content-Type: application/json" \
  -d '{
    "image": "base64_encoded_image_here",
    "platform": "whatsapp",
    "tone": "professional",
    "userId": "test-user"
  }'
```

Press `Ctrl+C` to stop local server.

### 10.2 Deploy to Azure

```bash
func azure functionapp publish replycopilot-api
```

**IMPORTANT**: Replace `replycopilot-api` with YOUR function app name from Step 8.1.

Expected output:
```
Getting site publishing info...
Creating archive for current directory...
Uploading 2.45 MB [###############################################]
Upload completed successfully.
Deployment completed successfully.
Syncing triggers...
Functions in replycopilot-api:
    generateReplies - [httpTrigger]
        Invoke url: https://replycopilot-api.azurewebsites.net/api/generateReplies
```

**Save the Invoke URL** - you'll need this for iOS app configuration.

### 10.3 Get Function Key

```bash
az functionapp function keys list \
  --name replycopilot-api \
  --resource-group replycopilot-rg \
  --function-name generateReplies \
  --query "default" \
  --output tsv
```

Save this value:
```
FUNCTION_KEY: [Your function key]
```

---

## 🧪 Step 11: Test Deployed API

### 11.1 Test with curl

```bash
curl -X POST "https://replycopilot-api.azurewebsites.net/api/generateReplies?code=YOUR_FUNCTION_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "image": "base64_encoded_image",
    "platform": "whatsapp",
    "tone": "professional",
    "userId": "test-user-123"
  }'
```

Expected response:
```json
{
  "suggestions": [
    {
      "text": "Thanks for reaching out! I'll get back to you shortly.",
      "confidence": 0.95,
      "ranking": 1
    },
    {
      "text": "I appreciate your message. Let me review and respond soon.",
      "confidence": 0.88,
      "ranking": 2
    }
  ],
  "processingTime": 1250,
  "requestId": "abc-123-def-456"
}
```

### 11.2 Test with Postman

1. Create new POST request
2. URL: `https://replycopilot-api.azurewebsites.net/api/generateReplies?code=YOUR_FUNCTION_KEY`
3. Headers: `Content-Type: application/json`
4. Body: JSON from above
5. Send request
6. Verify 200 OK response

---

## 📊 Step 12: Monitor and Optimize

### 12.1 View Logs in Portal

1. Go to: https://portal.azure.com
2. Navigate to your Function App
3. Click **Functions** > **generateReplies**
4. Click **Monitor**
5. View invocations, errors, performance

### 12.2 View Application Insights

1. Go to **Application Insights** > **replycopilot-insights**
2. Click **Live Metrics** to see real-time data
3. Click **Failures** to see errors
4. Click **Performance** to see slow requests

### 12.3 Set Up Alerts

Create alert for errors:
```bash
az monitor metrics alert create \
  --name "High Error Rate" \
  --resource-group replycopilot-rg \
  --scopes "/subscriptions/.../resourceGroups/replycopilot-rg/providers/Microsoft.Insights/components/replycopilot-insights" \
  --condition "count exceptions/count > 10" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --description "Alert when error count exceeds 10 in 5 minutes"
```

Create alert for high latency:
```bash
az monitor metrics alert create \
  --name "Slow Response Time" \
  --resource-group replycopilot-rg \
  --scopes "/subscriptions/.../resourceGroups/replycopilot-rg/providers/Microsoft.Web/sites/replycopilot-api" \
  --condition "avg responseTime > 5000" \
  --window-size 5m \
  --description "Alert when average response time exceeds 5 seconds"
```

---

## 💰 Step 13: Cost Management

### 13.1 Set Budget

```bash
az consumption budget create \
  --budget-name replycopilot-budget \
  --amount 100 \
  --category cost \
  --time-grain monthly \
  --start-date 2025-10-01 \
  --end-date 2026-09-30 \
  --resource-group replycopilot-rg
```

### 13.2 View Current Costs

```bash
az consumption usage list \
  --start-date 2025-10-01 \
  --end-date 2025-10-31
```

### 13.3 Cost Breakdown (Estimated)

**Development/Testing:**
- Function App (Consumption): $0-5/month (1M executions free)
- Azure OpenAI: $10-30/month (depends on usage)
- Key Vault: $0.03/month (10K operations free)
- Storage: $1-3/month
- Application Insights: $0-5/month (5GB free)
- **Total**: $10-45/month

**Production (1,000 users, 30 replies/user/month):**
- Function App: $10-20/month
- Azure OpenAI (30K requests): $50-100/month
- Key Vault: $0.10/month
- Storage: $5-10/month
- Application Insights: $10-20/month
- **Total**: $75-150/month

**Production (10,000 users):**
- Function App: $50-100/month
- Azure OpenAI (300K requests): $500-800/month
- Key Vault: $1/month
- Storage: $20-40/month
- Application Insights: $50-100/month
- **Total**: $620-1,040/month

---

## 🔧 Step 14: Update iOS App Configuration

### 14.1 Update Config.swift

Edit `ios/ReplyCopilot/Config/Config.swift`:

```swift
import Foundation

struct Config {
    // MARK: - API Configuration
    static let baseURL = "https://replycopilot-api.azurewebsites.net"
    static let apiKey = "YOUR_FUNCTION_KEY_FROM_STEP_10"
    static let apiVersion = "1.0"

    // MARK: - Endpoints
    struct Endpoints {
        static let generateReplies = "/api/generateReplies"
    }

    // MARK: - Azure OpenAI
    struct AzureOpenAI {
        static let deployment = "gpt-4o"
        static let apiVersion = "2024-02-15-preview"
        static let maxTokens = 500
        static let temperature = 0.7
    }

    // MARK: - App Settings
    struct App {
        static let bundleIdentifier = "com.replycopilot.app"
        static let appGroupIdentifier = "group.com.replycopilot.shared"
        static let keychainGroup = "com.replycopilot.keychain"
    }

    // MARK: - Feature Flags
    struct Features {
        static let enableAnalytics = true
        static let enableCrashReporting = true
        static let enableKeyboard = true
        static let enableShareExtension = true
    }

    // MARK: - Subscription
    struct Subscription {
        static let freeRepliesPerDay = 20
        static let proPrice = "$9.99"
        static let proProductID = "com.replycopilot.pro.monthly"
    }
}
```

### 14.2 Update APIClient.swift

Ensure `APIClient.swift` uses the config:

```swift
private let baseURL = Config.baseURL
private let apiKey = Config.apiKey

func generateReplies(...) async throws -> GenerateRepliesResponse {
    let endpoint = "\(baseURL)\(Config.Endpoints.generateReplies)?code=\(apiKey)"
    // ... rest of implementation
}
```

---

## 🔒 Step 15: Security Hardening

### 15.1 Enable Managed Identity

```bash
az functionapp identity assign \
  --name replycopilot-api \
  --resource-group replycopilot-rg
```

Get the identity ID:
```bash
az functionapp identity show \
  --name replycopilot-api \
  --resource-group replycopilot-rg \
  --query principalId \
  --output tsv
```

### 15.2 Grant Key Vault Access

```bash
az keyvault set-policy \
  --name replycopilot-kv \
  --object-id YOUR_IDENTITY_ID_FROM_ABOVE \
  --secret-permissions get list
```

### 15.3 Update Function to Use Key Vault References

Instead of storing secrets directly, reference Key Vault:

```bash
az functionapp config appsettings set \
  --name replycopilot-api \
  --resource-group replycopilot-rg \
  --settings \
    "AZURE_OPENAI_KEY=@Microsoft.KeyVault(SecretUri=https://replycopilot-kv.vault.azure.net/secrets/AZURE-OPENAI-KEY/)" \
    "AZURE_OPENAI_ENDPOINT=@Microsoft.KeyVault(SecretUri=https://replycopilot-kv.vault.azure.net/secrets/AZURE-OPENAI-ENDPOINT/)"
```

### 15.4 Enable HTTPS Only

```bash
az functionapp update \
  --name replycopilot-api \
  --resource-group replycopilot-rg \
  --set httpsOnly=true
```

### 15.5 Configure Authentication

Enable Azure AD authentication:
```bash
az functionapp auth update \
  --name replycopilot-api \
  --resource-group replycopilot-rg \
  --enabled true \
  --action LoginWithAzureActiveDirectory \
  --aad-allowed-token-audiences "api://replycopilot"
```

---

## 📊 Step 16: Performance Optimization

### 16.1 Enable Always On (Premium Plan Only)

If you upgrade to Premium plan:
```bash
az functionapp config set \
  --name replycopilot-api \
  --resource-group replycopilot-rg \
  --always-on true
```

### 16.2 Configure Concurrency

Edit `host.json` in backend folder:

```json
{
  "version": "2.0",
  "functionTimeout": "00:05:00",
  "extensions": {
    "http": {
      "routePrefix": "api",
      "maxConcurrentRequests": 100,
      "maxOutstandingRequests": 200
    }
  },
  "logging": {
    "applicationInsights": {
      "samplingSettings": {
        "isEnabled": true,
        "maxTelemetryItemsPerSecond": 20
      }
    }
  }
}
```

Redeploy:
```bash
func azure functionapp publish replycopilot-api
```

### 16.3 Enable HTTP Compression

```bash
az functionapp config set \
  --name replycopilot-api \
  --resource-group replycopilot-rg \
  --use-32bit-worker-process false \
  --http20-enabled true
```

---

## ✅ Verification Checklist

After setup, verify:

- [ ] Azure CLI installed and logged in
- [ ] Resource group created: `replycopilot-rg`
- [ ] Azure OpenAI service created with GPT-4o deployment
- [ ] OpenAI keys and endpoint obtained
- [ ] Key Vault created and secrets stored
- [ ] Application Insights created
- [ ] Storage account created
- [ ] Function app created and configured
- [ ] Backend deployed successfully
- [ ] API endpoint is accessible
- [ ] Test API call returns valid response
- [ ] Monitoring and alerts configured
- [ ] Budget alerts set
- [ ] iOS app config updated with API URL and key
- [ ] Security hardening complete (HTTPS, managed identity)

---

## 🚀 Next Steps

1. **Update iOS App**
   - Update `Config.swift` with Azure Function URL and key
   - Test API integration from iOS app
   - Verify reply generation works end-to-end

2. **Set Up Custom Domain (Optional)**
   - Register domain (e.g., api.replycopilot.com)
   - Add custom domain to Function App
   - Configure SSL certificate
   - Update DNS records

3. **Enable CI/CD**
   - Set up GitHub Actions for auto-deployment
   - Configure staging and production environments
   - Add automated tests before deployment

4. **Monitor Performance**
   - Review Application Insights daily
   - Track API response times
   - Monitor error rates
   - Optimize slow queries

5. **Scale as Needed**
   - Start with Consumption plan (pay per execution)
   - Upgrade to Premium plan when:
     - Need faster cold starts
     - Need VNet integration
     - Need Always On feature
     - Reaching Consumption limits

---

## 📚 Useful Resources

- **Azure Functions Documentation**: https://docs.microsoft.com/azure/azure-functions/
- **Azure OpenAI Documentation**: https://docs.microsoft.com/azure/cognitive-services/openai/
- **Azure Key Vault**: https://docs.microsoft.com/azure/key-vault/
- **Application Insights**: https://docs.microsoft.com/azure/azure-monitor/app/app-insights-overview
- **Azure CLI Reference**: https://docs.microsoft.com/cli/azure/
- **Azure Pricing Calculator**: https://azure.microsoft.com/pricing/calculator/

---

## 🆘 Troubleshooting

### Function deployment fails

**Check:**
1. Node.js version matches (18+)
2. `package.json` has correct dependencies
3. Function app name is correct
4. Azure CLI is logged in

**Fix:**
```bash
# Re-login
az login

# Verify function app exists
az functionapp list --output table

# Redeploy with verbose logging
func azure functionapp publish replycopilot-api --verbose
```

### API returns 401 Unauthorized

**Check:**
1. Function key is included in URL: `?code=YOUR_KEY`
2. CORS is configured correctly
3. Request headers are correct

**Fix:**
```bash
# Get new function key
az functionapp function keys list \
  --name replycopilot-api \
  --resource-group replycopilot-rg \
  --function-name generateReplies
```

### OpenAI API errors

**Check:**
1. Azure OpenAI key is correct
2. Deployment name matches ("gpt-4o")
3. API version is correct
4. You have quota available

**Fix:**
```bash
# Verify deployment exists
az cognitiveservices account deployment list \
  --name replycopilot-openai \
  --resource-group replycopilot-rg
```

### Slow performance

**Check:**
1. Using Consumption plan (cold starts common)
2. Image size (compress before sending)
3. Network latency
4. OpenAI quota/throttling

**Fix:**
- Compress images to <1MB
- Upgrade to Premium plan
- Add caching layer
- Implement retry logic with exponential backoff

---

**Azure backend setup complete! Your API is ready for production.** ☁️

Built with [Claude Code](https://claude.com/claude-code)

Last updated: October 3, 2025
