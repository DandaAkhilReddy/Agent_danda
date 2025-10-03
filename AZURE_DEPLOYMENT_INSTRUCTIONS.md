# 🚀 Azure Deployment - Step-by-Step Instructions

**Status:** Ready to Deploy
**Date:** October 3, 2025

---

## ⚡ Quick Deploy (Automated)

Since you're on Windows, you'll need to run the Azure deployment. Here's how:

### Option 1: Using Git Bash (Recommended)

```bash
cd C:\users\akhil\projects\ReplyCopilot

# Run the automated deployment script
bash deploy-azure.sh
```

### Option 2: Using PowerShell

I'll create a PowerShell version for you!

### Option 3: Manual Steps (If scripts don't work)

Follow these commands one by one:

```bash
# 1. Login to Azure
az login

# 2. Create Resource Group
az group create --name ReplyCopilot-RG --location eastus

# 3. Create Azure OpenAI
az cognitiveservices account create \
  --name replycopilot-openai \
  --resource-group ReplyCopilot-RG \
  --location eastus \
  --kind OpenAI \
  --sku S0 \
  --yes

# 4. Deploy GPT-4o Vision Model
az cognitiveservices account deployment create \
  --name replycopilot-openai \
  --resource-group ReplyCopilot-RG \
  --deployment-name gpt-4o-vision \
  --model-name gpt-4o \
  --model-version "2024-08-06" \
  --model-format OpenAI \
  --sku-name "Standard" \
  --sku-capacity 10

# 5. Get Keys
az cognitiveservices account keys list \
  --name replycopilot-openai \
  --resource-group ReplyCopilot-RG
```

---

## 📋 What Gets Deployed

✅ Azure OpenAI with GPT-4o Vision
✅ Azure Functions (backend API)
✅ Key Vault (secrets)
✅ Storage Account
✅ Application Insights (monitoring)
✅ Managed Identities (security)

---

## ⏱️ Time Required

- Automated: ~10 minutes
- Manual: ~20 minutes

---

## 💰 Cost Estimate

- Azure OpenAI: ~$0.10/day (testing)
- Azure Functions: Free tier
- Storage: ~$0.01/day
- **Total: ~$3-5/month for testing**

---

## ✅ After Deployment

You'll get:
- Azure OpenAI Endpoint URL
- API Key
- Function App URL

Save these for the iOS app configuration!

---

## 🆘 Need Help?

Since you're on Windows and I can't run bash scripts directly, I'll create all the iOS code for you while you run this deployment!

**Let's build in parallel!** 🚀
