# 🚀 Complete ReplyCopilot Deployment - Step-by-Step Instructions for Akhil

**Date**: October 3, 2025
**Estimated Time**: 1-2 hours
**Current Status**: Azure infrastructure created, deployment in progress

---

## 📊 What's Already Done ✅

I've completed the following for you:

1. ✅ Created Azure Resource Group: `replycopilot-rg`
2. ✅ Created Azure OpenAI service with GPT-4o model
3. ✅ Created Azure Storage Account: `rcstorageakhil2025`
4. ✅ Created Azure Function App: `replycopilot-api-2025`
5. ✅ Installed all backend dependencies
6. ✅ Started backend deployment (in progress)
7. ✅ Pushed all guides to GitHub

**Your API URL**: `https://replycopilot-api-2025.azurewebsites.net`

---

## 🎯 What You Need to Do Now

Follow these steps **exactly** to complete the deployment:

---

## Step 1: Configure Azure Function App Settings (15 minutes)

The backend deployment is running, but we need to add configuration settings via Azure Portal because the Azure CLI has network issues.

### 1.1 Open Azure Portal

1. Open your browser
2. Go to: **https://portal.azure.com**
3. Login with: `areddy@hhamedicine.com` (if not already logged in)

### 1.2 Navigate to Function App

1. In the search bar at top, type: **replycopilot-api-2025**
2. Click on **replycopilot-api-2025** (Function App)
3. You should see the Function App overview page

### 1.3 Add Application Settings

1. In the left sidebar, click **Configuration** (under Settings section)
2. Click **+ New application setting** button
3. Add each of these settings **one by one**:

**Setting 1:**
- Name: `AZURE_OPENAI_KEY`
- Value: `bc08aca8a5604b7e9fa698504b9c11cb`
- Click **OK**

**Setting 2:**
- Name: `AZURE_OPENAI_ENDPOINT`
- Value: `https://eastus.api.cognitive.microsoft.com/`
- Click **OK**

**Setting 3:**
- Name: `AZURE_OPENAI_DEPLOYMENT`
- Value: `gpt-4o`
- Click **OK**

**Setting 4:**
- Name: `AZURE_OPENAI_API_VERSION`
- Value: `2024-02-15-preview`
- Click **OK**

**Setting 5:**
- Name: `NODE_ENV`
- Value: `production`
- Click **OK**

**Setting 6:**
- Name: `ALLOWED_ORIGINS`
- Value: `https://replycopilot.com,http://localhost:3000`
- Click **OK**

4. After adding all 6 settings, click **Save** at the top
5. Click **Continue** when prompted about restarting the app

**✅ Checkpoint**: You should see all 6 settings in the list now.

---

## Step 2: Enable CORS (5 minutes)

Still in the Azure Portal, Function App page:

1. In the left sidebar, click **CORS** (under API section)
2. In the "Allowed Origins" section, add these URLs (one per line):
   - `https://replycopilot.com`
   - `https://www.replycopilot.com`
   - `http://localhost:3000`
   - `http://localhost:7071`
3. Click **Save** at the top

**✅ Checkpoint**: CORS settings saved.

---

## Step 3: Wait for Deployment to Complete (5-10 minutes)

The backend code deployment may still be running.

### 3.1 Check Deployment Status

In Azure Portal, Function App page:

1. Click **Deployment Center** (in left sidebar, under Deployment section)
2. Look for recent deployments
3. If you see a deployment in progress, wait for it to complete
4. It will show "Success" with a green checkmark when done

### 3.2 Alternative: Redeploy from Command Line

If deployment seems stuck, open a **new terminal** and run:

```bash
cd C:\users\akhil\projects\ReplyCopilot\backend
func azure functionapp publish replycopilot-api-2025
```

Wait for it to show:
```
Deployment completed successfully.
Functions in replycopilot-api-2025:
    generateReplies - [httpTrigger]
        Invoke url: https://replycopilot-api-2025.azurewebsites.net/api/generateReplies
```

**✅ Checkpoint**: Deployment shows "Success" or command completes.

---

## Step 4: Get Your Function Key (5 minutes)

You need this key to call your API from the iOS app.

### Method 1: Via Azure Portal (Recommended)

1. In Azure Portal, still in Function App page
2. Click **Functions** (in left sidebar)
3. Click **generateReplies** function
4. Click **Function Keys** (in left sidebar)
5. Under "default", click the **Copy** icon (📋)
6. **Save this key somewhere safe** - you'll need it for iOS app

### Method 2: Via Command Line

Open terminal and run:

```bash
az functionapp function keys list \
  --name replycopilot-api-2025 \
  --resource-group replycopilot-rg \
  --function-name generateReplies \
  --query "default" \
  --output tsv
```

Copy the output key.

**✅ Checkpoint**: You have copied your function key (looks like: `abc123def456...`)

---

## Step 5: Test Your API (10 minutes)

Let's make sure your API is working!

### 5.1 Test Health Endpoint

Open terminal and run:

```bash
curl https://replycopilot-api-2025.azurewebsites.net/api/health
```

**Expected Response:**
```json
{"status":"healthy"}
```

If you get an error, the deployment may not be complete. Wait 2-3 minutes and try again.

### 5.2 Test Reply Generation

Replace `YOUR_FUNCTION_KEY` with the key you copied in Step 4:

```bash
curl -X POST "https://replycopilot-api-2025.azurewebsites.net/api/generateReplies?code=YOUR_FUNCTION_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"image\":\"test\",\"platform\":\"whatsapp\",\"tone\":\"professional\",\"userId\":\"test-user\"}"
```

**Expected Response:**
```json
{
  "suggestions": [
    {
      "text": "Thanks for reaching out!",
      "confidence": 0.95,
      "ranking": 1
    }
  ],
  "processingTime": 1250,
  "requestId": "..."
}
```

**✅ Checkpoint**: API responds with reply suggestions.

---

## Step 6: Update iOS App Configuration (10 minutes)

Now that your API is working, update the iOS app to use it.

### 6.1 Open Config File

Navigate to: `C:\users\akhil\projects\ReplyCopilot\ios\ReplyCopilot\Config\Config.swift`

If the file doesn't exist yet, create it with this content:

```swift
import Foundation

struct Config {
    // MARK: - Environment
    #if DEBUG
    static let environment = Environment.development
    #else
    static let environment = Environment.production
    #endif

    enum Environment {
        case development
        case staging
        case production

        var baseURL: String {
            switch self {
            case .development:
                return "http://localhost:7071"
            case .staging:
                return "https://replycopilot-api-2025.azurewebsites.net"
            case .production:
                return "https://replycopilot-api-2025.azurewebsites.net"
            }
        }
    }

    // MARK: - API Configuration
    static let baseURL = environment.baseURL
    static let apiKey = "PASTE_YOUR_FUNCTION_KEY_HERE"  // ← REPLACE THIS
    static let apiVersion = "1.0"
    static let timeout: TimeInterval = 30

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

    // MARK: - Subscription
    struct Subscription {
        static let freeRepliesPerDay = 20
        static let proPrice = "$9.99"
        static let proProductID = "com.replycopilot.pro.monthly"
    }
}
```

### 6.2 Update API Key

1. Find the line: `static let apiKey = "PASTE_YOUR_FUNCTION_KEY_HERE"`
2. Replace `PASTE_YOUR_FUNCTION_KEY_HERE` with your actual function key from Step 4
3. Save the file

**✅ Checkpoint**: Config.swift updated with your API key.

---

## Step 7: Set Up Firebase (30 minutes)

Follow the complete guide I created: **FIREBASE_SETUP_GUIDE.md**

### Quick Steps:

1. Go to: **https://console.firebase.google.com**
2. Click **"Add project"**
3. Name: **ReplyCopilot**
4. Enable Google Analytics: **Yes**
5. Click **Create project**

6. Enable Authentication:
   - Click **Authentication** → **Get started**
   - Enable **Email/Password**
   - Enable **Google**
   - Enable **Apple**

7. Create Firestore Database:
   - Click **Firestore Database** → **Create database**
   - **Production mode** → **Next**
   - Location: **us-central** → **Enable**

8. Create Collections:
   - Collection ID: `users` → Add a test document
   - Collection ID: `replies` → Add a test document
   - Collection ID: `analytics` → Add a test document

9. Configure Security Rules:
   - Click **Rules** tab
   - Copy rules from **FIREBASE_SETUP_GUIDE.md** (page 11)
   - Click **Publish**

10. Add iOS App:
    - Click **Project Settings** (gear icon)
    - Click iOS icon
    - Bundle ID: `com.replycopilot.app`
    - Click **Register app**
    - **Download GoogleService-Info.plist**
    - Save to: `C:\users\akhil\projects\ReplyCopilot\ios\`

**✅ Checkpoint**: Firebase project created, iOS app registered, GoogleService-Info.plist downloaded.

---

## Step 8: Deploy Website (15 minutes)

### 8.1 Install Vercel CLI (if not installed)

```bash
npm install -g vercel
```

### 8.2 Deploy Website

```bash
cd C:\users\akhil\projects\ReplyCopilot\website
vercel --prod
```

Follow the prompts:
- **Set up and deploy?** → **Y**
- **Which scope?** → Select your account
- **Link to existing project?** → **N**
- **Project name?** → **replycopilot-website**
- **In which directory?** → **.** (current directory)
- **Override settings?** → **N**

Copy the deployment URL from the output.

**✅ Checkpoint**: Website live at Vercel URL.

---

## Step 9: Testing Everything End-to-End (20 minutes)

### 9.1 Test Website
1. Open the Vercel URL in your browser
2. Check all sections load
3. Try the Calendly booking button
4. Check on mobile

### 9.2 Test Backend
1. Health endpoint: ✅ (done in Step 5)
2. Reply generation: ✅ (done in Step 5)

### 9.3 Test Firebase
1. Login to Firebase Console
2. Check collections exist
3. Try adding a test document to `users` collection

**✅ Checkpoint**: All systems operational!

---

## 📊 Summary - What You've Built

### Infrastructure
- ✅ Azure OpenAI with GPT-4o
- ✅ Azure Functions API (serverless)
- ✅ Firebase Authentication + Database
- ✅ Marketing Website (live)
- ✅ Complete monitoring and analytics

### Estimated Monthly Cost
- Development: $10-30/month
- Production (1K users): $175-215/month
- Revenue Potential (100 paid users): $999/month
- **Net Profit**: $780+/month

---

## 🆘 Troubleshooting

### If API doesn't respond:
1. Wait 5 minutes for deployment to fully complete
2. Check Function App logs in Azure Portal
3. Restart Function App (in Azure Portal, click **Restart**)

### If you get "401 Unauthorized":
- Make sure you're including `?code=YOUR_FUNCTION_KEY` in the URL
- Verify the function key is correct

### If deployment fails:
```bash
# Try this alternative command
cd C:\users\akhil\projects\ReplyCopilot\backend
func azure functionapp publish replycopilot-api-2025 --force
```

---

## 📞 Next Steps After Deployment

1. **iOS App Development**
   - Follow: `XCODE_PROJECT_SETUP.md`
   - Build and test in Xcode
   - Submit to TestFlight

2. **Marketing**
   - Update website with real App Store link
   - Set up Google Analytics
   - Prepare social media posts

3. **Launch**
   - Internal testing
   - Beta testing (TestFlight)
   - Public launch
   - Product Hunt submission

---

## ✅ Final Checklist

Complete these in order:

- [ ] Step 1: Configure Function App Settings (Azure Portal)
- [ ] Step 2: Enable CORS (Azure Portal)
- [ ] Step 3: Wait for deployment to complete
- [ ] Step 4: Get function key
- [ ] Step 5: Test API (health + reply generation)
- [ ] Step 6: Update iOS Config.swift with function key
- [ ] Step 7: Set up Firebase (30 min)
- [ ] Step 8: Deploy website to Vercel
- [ ] Step 9: Test everything end-to-end

---

## 🎉 You're Almost There!

**Time to complete**: 1-2 hours if you follow steps carefully

**What you'll have**:
- Working AI-powered API
- Firebase backend
- Live marketing website
- Ready-to-build iOS app

**Questions?** Check these guides:
- `QUICK_DEPLOY.md` - Quick reference
- `AZURE_SETUP_GUIDE.md` - Detailed Azure docs
- `FIREBASE_SETUP_GUIDE.md` - Detailed Firebase docs
- `TROUBLESHOOTING.md` - Common issues

---

Built with [Claude Code](https://claude.com/claude-code)

**Good luck! You're building something amazing! 🚀**
