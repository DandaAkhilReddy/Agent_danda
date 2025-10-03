#!/bin/bash

################################################################################
# ReplyCopilot - Azure Infrastructure Deployment Script
# Professional deployment automation for production-ready infrastructure
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="ReplyCopilot-RG"
LOCATION="eastus"
OPENAI_NAME="replycopilot-openai"
FUNCTION_APP_NAME="replycopilot-api"
KEYVAULT_NAME="replycopilot-kv"
STORAGE_ACCOUNT="replycopilotstorage"
APPINSIGHTS_NAME="replycopilot-insights"
VNET_NAME="replycopilot-vnet"
SUBNET_NAME="function-subnet"

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ReplyCopilot - Azure Deployment Script          ║${NC}"
echo -e "${BLUE}║  Professional Infrastructure Automation           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

################################################################################
# Step 1: Login and Subscription Check
################################################################################

echo -e "${YELLOW}[1/10] Checking Azure CLI...${NC}"
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI not found. Please install: https://aka.ms/installazurecli${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Azure CLI installed${NC}"

echo ""
echo -e "${YELLOW}[2/10] Logging in to Azure...${NC}"
if ! az account show &> /dev/null; then
    echo "Please login to Azure:"
    az login
else
    echo -e "${GREEN}✅ Already logged in${NC}"
    az account show --query "{Name:name, SubscriptionId:id}" -o table
fi

################################################################################
# Step 2: Create Resource Group
################################################################################

echo ""
echo -e "${YELLOW}[3/10] Creating resource group...${NC}"
if az group exists --name $RESOURCE_GROUP | grep -q "true"; then
    echo -e "${GREEN}✅ Resource group already exists${NC}"
else
    az group create --name $RESOURCE_GROUP --location $LOCATION
    echo -e "${GREEN}✅ Resource group created: $RESOURCE_GROUP${NC}"
fi

################################################################################
# Step 3: Create Azure OpenAI
################################################################################

echo ""
echo -e "${YELLOW}[4/10] Creating Azure OpenAI resource...${NC}"
if az cognitiveservices account show --name $OPENAI_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo -e "${GREEN}✅ OpenAI resource already exists${NC}"
else
    echo "Creating Azure OpenAI resource (this may take 2-3 minutes)..."
    az cognitiveservices account create \
        --name $OPENAI_NAME \
        --resource-group $RESOURCE_GROUP \
        --location $LOCATION \
        --kind OpenAI \
        --sku S0 \
        --custom-domain $OPENAI_NAME \
        --yes
    echo -e "${GREEN}✅ Azure OpenAI resource created${NC}"
fi

# Deploy GPT-4o Vision model
echo "Deploying GPT-4o Vision model..."
if az cognitiveservices account deployment show \
    --name $OPENAI_NAME \
    --resource-group $RESOURCE_GROUP \
    --deployment-name gpt-4o-vision &> /dev/null; then
    echo -e "${GREEN}✅ GPT-4o Vision already deployed${NC}"
else
    az cognitiveservices account deployment create \
        --name $OPENAI_NAME \
        --resource-group $RESOURCE_GROUP \
        --deployment-name gpt-4o-vision \
        --model-name gpt-4o \
        --model-version "2024-08-06" \
        --model-format OpenAI \
        --sku-name "Standard" \
        --sku-capacity 10
    echo -e "${GREEN}✅ GPT-4o Vision model deployed${NC}"
fi

# Get OpenAI endpoint and key
OPENAI_ENDPOINT=$(az cognitiveservices account show \
    --name $OPENAI_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "properties.endpoint" -o tsv)

OPENAI_KEY=$(az cognitiveservices account keys list \
    --name $OPENAI_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "key1" -o tsv)

echo -e "${GREEN}✅ OpenAI Endpoint: $OPENAI_ENDPOINT${NC}"

################################################################################
# Step 4: Create Key Vault
################################################################################

echo ""
echo -e "${YELLOW}[5/10] Creating Azure Key Vault...${NC}"
if az keyvault show --name $KEYVAULT_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo -e "${GREEN}✅ Key Vault already exists${NC}"
else
    az keyvault create \
        --name $KEYVAULT_NAME \
        --resource-group $RESOURCE_GROUP \
        --location $LOCATION \
        --enable-rbac-authorization false
    echo -e "${GREEN}✅ Key Vault created${NC}"
fi

# Store secrets in Key Vault
echo "Storing secrets in Key Vault..."
az keyvault secret set \
    --vault-name $KEYVAULT_NAME \
    --name "OPENAI-API-KEY" \
    --value "$OPENAI_KEY" > /dev/null

az keyvault secret set \
    --vault-name $KEYVAULT_NAME \
    --name "OPENAI-ENDPOINT" \
    --value "$OPENAI_ENDPOINT" > /dev/null

echo -e "${GREEN}✅ Secrets stored in Key Vault${NC}"

################################################################################
# Step 5: Create Storage Account
################################################################################

echo ""
echo -e "${YELLOW}[6/10] Creating Storage Account...${NC}"
if az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo -e "${GREEN}✅ Storage account already exists${NC}"
else
    az storage account create \
        --name $STORAGE_ACCOUNT \
        --resource-group $RESOURCE_GROUP \
        --location $LOCATION \
        --sku Standard_LRS
    echo -e "${GREEN}✅ Storage account created${NC}"
fi

################################################################################
# Step 6: Create Application Insights
################################################################################

echo ""
echo -e "${YELLOW}[7/10] Creating Application Insights...${NC}"
if az monitor app-insights component show \
    --app $APPINSIGHTS_NAME \
    --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo -e "${GREEN}✅ Application Insights already exists${NC}"
else
    az monitor app-insights component create \
        --app $APPINSIGHTS_NAME \
        --location $LOCATION \
        --resource-group $RESOURCE_GROUP \
        --application-type web
    echo -e "${GREEN}✅ Application Insights created${NC}"
fi

INSTRUMENTATION_KEY=$(az monitor app-insights component show \
    --app $APPINSIGHTS_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "instrumentationKey" -o tsv)

################################################################################
# Step 7: Create Function App
################################################################################

echo ""
echo -e "${YELLOW}[8/10] Creating Azure Function App...${NC}"
if az functionapp show --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo -e "${GREEN}✅ Function App already exists${NC}"
else
    echo "Creating Function App (this may take 1-2 minutes)..."
    az functionapp create \
        --name $FUNCTION_APP_NAME \
        --resource-group $RESOURCE_GROUP \
        --consumption-plan-location $LOCATION \
        --runtime node \
        --runtime-version 20 \
        --functions-version 4 \
        --storage-account $STORAGE_ACCOUNT \
        --os-type Linux
    echo -e "${GREEN}✅ Function App created${NC}"
fi

################################################################################
# Step 8: Configure Function App Settings
################################################################################

echo ""
echo -e "${YELLOW}[9/10] Configuring Function App settings...${NC}"

# Enable managed identity
az functionapp identity assign \
    --name $FUNCTION_APP_NAME \
    --resource-group $RESOURCE_GROUP > /dev/null

FUNCTION_IDENTITY=$(az functionapp identity show \
    --name $FUNCTION_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "principalId" -o tsv)

# Grant Key Vault access to Function App
az keyvault set-policy \
    --name $KEYVAULT_NAME \
    --resource-group $RESOURCE_GROUP \
    --object-id $FUNCTION_IDENTITY \
    --secret-permissions get list > /dev/null

# Configure app settings with Key Vault references
az functionapp config appsettings set \
    --name $FUNCTION_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --settings \
        "OPENAI_ENDPOINT=@Microsoft.KeyVault(SecretUri=https://${KEYVAULT_NAME}.vault.azure.net/secrets/OPENAI-ENDPOINT/)" \
        "OPENAI_API_KEY=@Microsoft.KeyVault(SecretUri=https://${KEYVAULT_NAME}.vault.azure.net/secrets/OPENAI-API-KEY/)" \
        "OPENAI_DEPLOYMENT=gpt-4o-vision" \
        "OPENAI_API_VERSION=2024-08-01-preview" \
        "APPINSIGHTS_INSTRUMENTATIONKEY=$INSTRUMENTATION_KEY" \
        "FIREBASE_PROJECT_ID=reddyfit-dcf41" > /dev/null

echo -e "${GREEN}✅ Function App configured${NC}"

################################################################################
# Step 9: Get Function App URL
################################################################################

echo ""
echo -e "${YELLOW}[10/10] Getting deployment information...${NC}"

FUNCTION_URL=$(az functionapp show \
    --name $FUNCTION_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "defaultHostName" -o tsv)

################################################################################
# Deployment Summary
################################################################################

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  🎉 Deployment Complete!                          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📋 Deployment Summary:${NC}"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${YELLOW}Resource Group:${NC}    $RESOURCE_GROUP"
echo -e "${YELLOW}Location:${NC}          $LOCATION"
echo ""
echo -e "${BLUE}🤖 Azure OpenAI:${NC}"
echo -e "  Name:            $OPENAI_NAME"
echo -e "  Endpoint:        $OPENAI_ENDPOINT"
echo -e "  Deployment:      gpt-4o-vision"
echo ""
echo -e "${BLUE}⚡ Function App:${NC}"
echo -e "  Name:            $FUNCTION_APP_NAME"
echo -e "  URL:             https://$FUNCTION_URL"
echo ""
echo -e "${BLUE}🔐 Key Vault:${NC}"
echo -e "  Name:            $KEYVAULT_NAME"
echo -e "  URL:             https://${KEYVAULT_NAME}.vault.azure.net/"
echo ""
echo -e "${BLUE}📊 App Insights:${NC}"
echo -e "  Name:            $APPINSIGHTS_NAME"
echo ""
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✅ Next Steps:${NC}"
echo -e "  1. Deploy backend code:"
echo -e "     ${BLUE}cd backend && npm install && func azure functionapp publish $FUNCTION_APP_NAME${NC}"
echo ""
echo -e "  2. Update iOS app Config.swift with:"
echo -e "     ${BLUE}apiURL = \"https://$FUNCTION_URL\"${NC}"
echo ""
echo -e "  3. Test the API:"
echo -e "     ${BLUE}curl https://$FUNCTION_URL/api/health${NC}"
echo ""
echo -e "${GREEN}🎊 Your Azure infrastructure is ready!${NC}"
echo ""

# Save configuration to file
cat > backend/.env << EOF
# Azure OpenAI Configuration
OPENAI_ENDPOINT=$OPENAI_ENDPOINT
OPENAI_API_KEY=$OPENAI_KEY
OPENAI_DEPLOYMENT=gpt-4o-vision
OPENAI_API_VERSION=2024-08-01-preview

# Azure Function Configuration
FUNCTION_URL=https://$FUNCTION_URL

# Azure Key Vault
KEYVAULT_URL=https://${KEYVAULT_NAME}.vault.azure.net/

# Firebase
FIREBASE_PROJECT_ID=reddyfit-dcf41

# Application Insights
APPINSIGHTS_INSTRUMENTATIONKEY=$INSTRUMENTATION_KEY

# Environment
NODE_ENV=production
EOF

echo -e "${GREEN}✅ Configuration saved to backend/.env${NC}"
echo ""
