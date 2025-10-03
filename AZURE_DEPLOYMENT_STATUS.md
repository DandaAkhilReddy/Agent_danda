# ☁️ Azure Deployment Status - ReplyCopilot

**Date**: October 3, 2025
**Status**: In Progress ⏳

---

## ✅ Resources Created

### 1. Resource Group
- **Name**: `replycopilot-rg`
- **Location**: East US
- **Status**: ✅ Created
- **Resource ID**: `/subscriptions/5801224b-ab00-4482-ac95-4ad2ce6bc61e/resourceGroups/replycopilot-rg`

### 2. Azure OpenAI Service
- **Name**: `replycopilot-openai`
- **Location**: East US
- **SKU**: S0 (Standard)
- **Status**: ✅ Created
- **Endpoint**: `https://eastus.api.cognitive.microsoft.com/`
- **API Keys**:
  - Key 1: `bc08aca8a5604b7e9fa698504b9c11cb`
  - Key 2: `b680c5c79dbc4bb2a63c4ef86a804e32`

### 3. GPT-4o Model Deployment
- **Deployment Name**: `gpt-4o`
- **Model**: GPT-4o
- **Version**: 2024-05-13
- **Format**: OpenAI
- **SKU**: Standard
- **Capacity**: 10 (10K tokens/minute)
- **Status**: ✅ Deployed
- **Capabilities**:
  - Chat Completion: ✅
  - JSON Object Response: ✅
  - Assistants API: ✅
  - Max Context: 128,000 tokens
  - Max Output: 4,096 tokens
- **Rate Limits**:
  - Requests: 10 per 10 seconds
  - Tokens: 10,000 per minute

### 4. Storage Account
- **Name**: `rcstorageakhil2025`
- **Location**: East US
- **SKU**: Standard_LRS (Locally Redundant Storage)
- **Kind**: StorageV2
- **Status**: ✅ Created
- **Access Tier**: Hot
- **HTTPS Only**: ✅ Enabled
- **Endpoints**:
  - Blob: `https://rcstorageakhil2025.blob.core.windows.net/`
  - File: `https://rcstorageakhil2025.file.core.windows.net/`
  - Queue: `https://rcstorageakhil2025.queue.core.windows.net/`
  - Table: `https://rcstorageakhil2025.table.core.windows.net/`
  - Web: `https://rcstorageakhil2025.z13.web.core.windows.net/`

### 5. Function App
- **Name**: `replycopilot-api-2025`
- **Location**: East US
- **Runtime**: Node.js 22
- **Functions Version**: 4
- **OS**: Linux
- **Plan**: Consumption (Pay-per-execution)
- **Status**: ✅ Created (awaiting code deployment)
- **URL**: `https://replycopilot-api-2025.azurewebsites.net`
- **Application Insights**: `replycopilot-api-2025`

---

## ⏳ Pending Tasks

### 1. Configure Function App Settings
Due to network issues, need to configure via Azure Portal:

**App Settings to Add:**
```
AZURE_OPENAI_KEY = bc08aca8a5604b7e9fa698504b9c11cb
AZURE_OPENAI_ENDPOINT = https://eastus.api.cognitive.microsoft.com/
AZURE_OPENAI_DEPLOYMENT = gpt-4o
AZURE_OPENAI_API_VERSION = 2024-02-15-preview
NODE_ENV = production
FUNCTIONS_WORKER_RUNTIME = node
```

**How to Add (via Azure Portal):**
1. Go to: https://portal.azure.com
2. Navigate to: Resource Groups → replycopilot-rg → replycopilot-api-2025
3. Click: **Configuration** (under Settings)
4. Click: **+ New application setting**
5. Add each setting above
6. Click: **Save**

### 2. Deploy Backend Code
```bash
# Navigate to backend folder
cd /c/users/akhil/projects/ReplyCopilot/backend

# Install dependencies (in progress)
npm install

# Deploy to Azure
func azure functionapp publish replycopilot-api-2025
```

### 3. Enable CORS
```bash
az functionapp cors add \
  --name replycopilot-api-2025 \
  --resource-group replycopilot-rg \
  --allowed-origins "https://replycopilot.com" "http://localhost:3000"
```

### 4. Get Function Key
After deployment:
```bash
az functionapp function keys list \
  --name replycopilot-api-2025 \
  --resource-group replycopilot-rg \
  --function-name generateReplies \
  --query "default" \
  --output tsv
```

---

## 📊 Configuration Summary

### For iOS App (`Config.swift`)

```swift
static let baseURL = "https://replycopilot-api-2025.azurewebsites.net"
static let apiKey = "GET_AFTER_DEPLOYMENT" // From Step 4 above
```

### For Backend (`local.settings.json`)

```json
{
  "Values": {
    "AZURE_OPENAI_KEY": "bc08aca8a5604b7e9fa698504b9c11cb",
    "AZURE_OPENAI_ENDPOINT": "https://eastus.api.cognitive.microsoft.com/",
    "AZURE_OPENAI_DEPLOYMENT": "gpt-4o",
    "AZURE_OPENAI_API_VERSION": "2024-02-15-preview"
  }
}
```

---

## 🧪 Testing Endpoints

### Health Check (after deployment)
```bash
curl https://replycopilot-api-2025.azurewebsites.net/api/health
```

Expected: `{"status":"healthy"}`

### Generate Replies (after deployment)
```bash
curl -X POST "https://replycopilot-api-2025.azurewebsites.net/api/generateReplies?code=YOUR_FUNCTION_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "image": "base64_encoded_image",
    "platform": "whatsapp",
    "tone": "professional",
    "userId": "test-user"
  }'
```

---

## 💰 Cost Estimate

### Current Resources

**Monthly Costs (Estimated):**

| Resource | SKU | Monthly Cost |
|----------|-----|--------------|
| Azure OpenAI | S0 Standard | $0 base + usage |
| - GPT-4o Input | 10K capacity | ~$5-15 per 1M tokens |
| - GPT-4o Output | 10K capacity | ~$15-45 per 1M tokens |
| Storage Account | Standard_LRS | ~$1-3 |
| Function App | Consumption | $0 (1M executions free) |
| Application Insights | Basic | $0 (5GB free) |
| **Total** | | **$10-50/month** |

### Usage-Based Costs

**Assumptions:**
- 1,000 users
- 30 replies per user per month = 30,000 total API calls
- Average 500 tokens input + 200 tokens output per call

**GPT-4o Costs:**
- Input: 30,000 × 500 tokens = 15M tokens = ~$75
- Output: 30,000 × 200 tokens = 6M tokens = ~$90
- **Total AI Costs**: ~$165/month

**Total Monthly Cost for 1K Users**: ~$175-215/month

**Revenue Potential:**
- 1,000 users × 10% conversion = 100 paid users
- 100 × $9.99 = $999/month
- **Profit**: $780-820/month

---

## 🔒 Security Considerations

### ✅ Implemented
- HTTPS Only on Storage Account
- Azure OpenAI in secure region
- Standard SKU with appropriate rate limits

### 🔜 To Implement
- [ ] Key Vault for secrets management
- [ ] Managed Identity for Function App
- [ ] IP restrictions (if needed)
- [ ] Custom domain with SSL
- [ ] DDoS protection (if scaling up)

---

## 📈 Next Steps

### Immediate (Next 30 minutes)
1. ✅ Wait for npm install to complete
2. Configure Function App settings via Azure Portal
3. Deploy backend code: `func azure functionapp publish replycopilot-api-2025`
4. Test health endpoint
5. Get function key
6. Test reply generation endpoint

### Today (Next 2-3 hours)
1. Set up Firebase (follow FIREBASE_SETUP_GUIDE.md)
2. Update iOS app configuration
3. Build and test iOS app in Xcode
4. Deploy website to Vercel
5. End-to-end testing

### This Week
1. TestFlight beta submission
2. Internal testing
3. Bug fixes
4. Performance optimization

---

## 🆘 Troubleshooting

### Azure CLI Connection Issues
If you encounter "Connection reset" errors:

**Option 1: Use Azure Portal**
- Go to https://portal.azure.com
- Manually configure settings via web interface

**Option 2: Retry Command**
- Wait 1-2 minutes
- Run command again

**Option 3: PowerShell**
```powershell
# Use PowerShell instead of Bash
Connect-AzAccount
Set-AzContext -SubscriptionId "5801224b-ab00-4482-ac95-4ad2ce6bc61e"
```

### NPM Install Issues
If npm install times out:

```bash
# Increase timeout
npm install --timeout=300000

# Or install dependencies one by one
npm install @azure/functions
npm install @azure/openai
npm install @azure/identity
npm install @azure/keyvault-secrets
npm install axios
npm install firebase-admin
```

---

## 📚 Resources

- **Azure Portal**: https://portal.azure.com
- **Resource Group**: https://portal.azure.com/#resource/subscriptions/5801224b-ab00-4482-ac95-4ad2ce6bc61e/resourceGroups/replycopilot-rg/overview
- **Function App**: https://portal.azure.com/#resource/subscriptions/5801224b-ab00-4482-ac95-4ad2ce6bc61e/resourceGroups/replycopilot-rg/providers/Microsoft.Web/sites/replycopilot-api-2025/appServices
- **Azure OpenAI Studio**: https://oai.azure.com

---

## ✅ Deployment Checklist

- [x] Resource group created
- [x] Azure OpenAI service created
- [x] GPT-4o model deployed
- [x] Storage account created
- [x] Function app created
- [ ] Function app settings configured
- [ ] Backend code deployed
- [ ] CORS enabled
- [ ] Function key obtained
- [ ] Health endpoint tested
- [ ] Reply generation tested
- [ ] iOS app updated with API URL
- [ ] Firebase configured
- [ ] Website deployed
- [ ] End-to-end testing complete

---

**Status**: Azure infrastructure ready! Complete remaining configuration steps to go live. 🚀

Built with [Claude Code](https://claude.com/claude-code)

Last updated: October 3, 2025
