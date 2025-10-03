# 🔐 Environment Configuration Guide

Complete reference for all environment variables and configuration needed for ReplyCopilot.

---

## 📋 Configuration Overview

ReplyCopilot requires configuration for:
1. **iOS App** - Firebase, Azure API
2. **Backend** - Azure OpenAI, Application Insights
3. **Website** - Calendly, Analytics
4. **Development** - Local testing

---

## 📱 iOS App Configuration

### File: `ios/ReplyCopilot/Config/Config.swift`

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
                return "https://replycopilot-api-staging.azurewebsites.net"
            case .production:
                return "https://replycopilot-api.azurewebsites.net"
            }
        }
    }

    // MARK: - API Configuration
    static let baseURL = environment.baseURL
    static let apiKey = "REPLACE_WITH_YOUR_AZURE_FUNCTION_KEY"
    static let apiVersion = "1.0"
    static let timeout: TimeInterval = 30

    // MARK: - Endpoints
    struct Endpoints {
        static let generateReplies = "/api/generateReplies"
        static let health = "/api/health"
        static let feedback = "/api/feedback"
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
        static let displayName = "ReplyCopilot"
        static let version = "1.0.0"
        static let buildNumber = "1"
    }

    // MARK: - Feature Flags
    struct Features {
        static let enableAnalytics = true
        static let enableCrashReporting = true
        static let enableKeyboard = true
        static let enableShareExtension = true
        static let enableBetaFeatures = false
        static let enableDebugLogging = environment != .production
    }

    // MARK: - Subscription
    struct Subscription {
        static let freeRepliesPerDay = 20
        static let proPrice = "$9.99"
        static let proProductID = "com.replycopilot.pro.monthly"
        static let enterpriseProductID = "com.replycopilot.enterprise.monthly"

        // App Store Connect will provide these after setup
        static let sharedSecret = "REPLACE_WITH_APP_STORE_SHARED_SECRET"
    }

    // MARK: - Analytics
    struct Analytics {
        static let mixpanelToken = "REPLACE_WITH_MIXPANEL_TOKEN" // Optional
        static let amplitudeKey = "REPLACE_WITH_AMPLITUDE_KEY" // Optional
    }

    // MARK: - Rate Limiting
    struct RateLimits {
        static let maxRequestsPerMinute = 30
        static let maxImageSizeBytes = 10 * 1024 * 1024 // 10MB
        static let maxConcurrentRequests = 3
    }

    // MARK: - Cache
    struct Cache {
        static let maxHistoryItems = 100
        static let expirationDays = 30
        static let enableDiskCache = true
    }
}
```

### File: `ios/ReplyCopilot/Config/FirebaseConfig.swift`

```swift
import Foundation
import Firebase

struct FirebaseConfig {
    // These values come from GoogleService-Info.plist
    // This file is for reference only - iOS will read from plist

    // MARK: - Firebase Project Info
    static let projectID = "replycopilot"
    static let storageBucket = "replycopilot.appspot.com"
    static let apiKey = "REPLACE_WITH_FIREBASE_API_KEY"
    static let appID = "REPLACE_WITH_FIREBASE_APP_ID"
    static let messagingSenderID = "REPLACE_WITH_FIREBASE_SENDER_ID"

    // MARK: - Firebase Services
    struct Services {
        static let enableAuth = true
        static let enableFirestore = true
        static let enableAnalytics = true
        static let enableCrashlytics = true
        static let enableMessaging = false // Future feature
        static let enableStorage = false // Not needed
        static let enableFunctions = false // Not needed
    }

    // MARK: - Firestore Collections
    struct Collections {
        static let users = "users"
        static let replies = "replies"
        static let analytics = "analytics"
        static let feedback = "feedback"
    }

    // MARK: - Auth Configuration
    struct Auth {
        static let enableEmailAuth = true
        static let enableGoogleAuth = true
        static let enableAppleAuth = true
        static let enableAnonymousAuth = false
        static let passwordMinLength = 8
    }
}
```

---

## ⚡ Backend Configuration

### File: `backend/local.settings.json` (for local testing)

**⚠️ NEVER commit this file to Git!**

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "",
    "FUNCTIONS_WORKER_RUNTIME": "node",
    "NODE_ENV": "development",

    "AZURE_OPENAI_KEY": "REPLACE_WITH_YOUR_AZURE_OPENAI_KEY",
    "AZURE_OPENAI_ENDPOINT": "https://replycopilot-openai.openai.azure.com/",
    "AZURE_OPENAI_DEPLOYMENT": "gpt-4o",
    "AZURE_OPENAI_API_VERSION": "2024-02-15-preview",

    "APPINSIGHTS_INSTRUMENTATIONKEY": "REPLACE_WITH_INSTRUMENTATION_KEY",
    "APPLICATIONINSIGHTS_CONNECTION_STRING": "InstrumentationKey=REPLACE_WITH_KEY;IngestionEndpoint=https://eastus-8.in.applicationinsights.azure.com/;LiveEndpoint=https://eastus.livediagnostics.monitor.azure.com/",

    "FIREBASE_PROJECT_ID": "replycopilot",
    "FIREBASE_CLIENT_EMAIL": "firebase-adminsdk@replycopilot.iam.gserviceaccount.com",
    "FIREBASE_PRIVATE_KEY": "-----BEGIN PRIVATE KEY-----\nREPLACE_WITH_FIREBASE_PRIVATE_KEY\n-----END PRIVATE KEY-----\n",

    "ALLOWED_ORIGINS": "http://localhost:3000,https://replycopilot.com",
    "RATE_LIMIT_PER_MINUTE": "30",
    "MAX_IMAGE_SIZE_MB": "10",
    "ENABLE_DEBUG_LOGGING": "true"
  },
  "Host": {
    "CORS": "*",
    "CORSCredentials": false,
    "LocalHttpPort": 7071
  }
}
```

### Azure Function App Settings (Production)

Set these in Azure Portal or via CLI:

```bash
# Required Settings
az functionapp config appsettings set \
  --name replycopilot-api \
  --resource-group replycopilot-rg \
  --settings \
    "AZURE_OPENAI_KEY=@Microsoft.KeyVault(SecretUri=https://replycopilot-kv.vault.azure.net/secrets/AZURE-OPENAI-KEY/)" \
    "AZURE_OPENAI_ENDPOINT=@Microsoft.KeyVault(SecretUri=https://replycopilot-kv.vault.azure.net/secrets/AZURE-OPENAI-ENDPOINT/)" \
    "AZURE_OPENAI_DEPLOYMENT=gpt-4o" \
    "AZURE_OPENAI_API_VERSION=2024-02-15-preview" \
    "APPINSIGHTS_INSTRUMENTATIONKEY=YOUR_INSTRUMENTATION_KEY" \
    "NODE_ENV=production" \
    "ALLOWED_ORIGINS=https://replycopilot.com,https://www.replycopilot.com" \
    "RATE_LIMIT_PER_MINUTE=30" \
    "MAX_IMAGE_SIZE_MB=10" \
    "ENABLE_DEBUG_LOGGING=false"
```

---

## 🌐 Website Configuration

### File: `website/config.js` (create this)

```javascript
// Website Configuration
const CONFIG = {
  // Calendly
  calendly: {
    url: 'https://calendly.com/your-username/demo',
    prefill: {
      name: '',
      email: '',
      customAnswers: {
        a1: 'ReplyCopilot Demo'
      }
    },
    utm: {
      utmCampaign: 'website',
      utmSource: 'replycopilot.com',
      utmMedium: 'demo-booking'
    }
  },

  // App Store
  appStore: {
    url: 'https://apps.apple.com/app/replycopilot/idXXXXXXXXXX', // Replace after App Store approval
    fallbackUrl: 'https://replycopilot.com/download'
  },

  // Analytics
  analytics: {
    // Google Analytics
    googleAnalyticsId: 'G-XXXXXXXXXX', // Replace with your GA4 measurement ID

    // Mixpanel (optional)
    mixpanelToken: 'REPLACE_WITH_MIXPANEL_TOKEN',

    // Facebook Pixel (optional)
    facebookPixelId: 'REPLACE_WITH_FB_PIXEL_ID',

    // Enable tracking
    enableTracking: true
  },

  // API (for contact forms, waitlist, etc.)
  api: {
    baseUrl: 'https://replycopilot-api.azurewebsites.net',
    endpoints: {
      waitlist: '/api/waitlist',
      contact: '/api/contact',
      feedback: '/api/feedback'
    }
  },

  // Feature flags
  features: {
    showPricing: true,
    showTestimonials: true,
    enableBooking: true,
    showBanner: false, // Launch announcement banner
    maintenanceMode: false
  },

  // Content
  content: {
    companyName: 'ReplyCopilot',
    supportEmail: 'support@replycopilot.com',
    salesEmail: 'sales@replycopilot.com',
    socialMedia: {
      twitter: 'https://twitter.com/replycopilot',
      linkedin: 'https://linkedin.com/company/replycopilot',
      facebook: 'https://facebook.com/replycopilot',
      instagram: 'https://instagram.com/replycopilot'
    }
  }
};

// Export for use in scripts
if (typeof module !== 'undefined' && module.exports) {
  module.exports = CONFIG;
}
```

### Add Google Analytics to website

In `index-merged.html`, add before `</head>`:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>

<!-- Calendly Config -->
<script>
  window.calendlyConfig = {
    url: 'https://calendly.com/your-username/demo'
  };
</script>
```

---

## 🧪 Development Configuration

### Environment Variables for Development

Create `.env.development` in project root:

```bash
# ===================================
# ReplyCopilot Development Config
# ===================================

# Environment
NODE_ENV=development
DEBUG=true

# Azure Function (Local)
AZURE_FUNCTION_URL=http://localhost:7071
AZURE_FUNCTION_KEY=local-dev-key

# Azure OpenAI
AZURE_OPENAI_KEY=your-dev-openai-key
AZURE_OPENAI_ENDPOINT=https://replycopilot-openai.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT=gpt-4o
AZURE_OPENAI_API_VERSION=2024-02-15-preview

# Firebase (Development)
FIREBASE_PROJECT_ID=replycopilot-dev
FIREBASE_API_KEY=your-dev-firebase-key
FIREBASE_APP_ID=your-dev-app-id

# Testing
ENABLE_MOCK_DATA=true
MOCK_API_DELAY_MS=500
SKIP_AUTH=false

# Logging
LOG_LEVEL=debug
LOG_TO_FILE=true
LOG_FILE_PATH=./logs/dev.log
```

### Environment Variables for Production

Create `.env.production` in project root:

```bash
# ===================================
# ReplyCopilot Production Config
# ===================================

# Environment
NODE_ENV=production
DEBUG=false

# Azure Function (Production)
AZURE_FUNCTION_URL=https://replycopilot-api.azurewebsites.net
AZURE_FUNCTION_KEY=your-production-function-key

# Azure OpenAI (Use Key Vault references)
AZURE_OPENAI_KEY=@Microsoft.KeyVault(SecretUri=...)
AZURE_OPENAI_ENDPOINT=https://replycopilot-openai.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT=gpt-4o
AZURE_OPENAI_API_VERSION=2024-02-15-preview

# Firebase (Production)
FIREBASE_PROJECT_ID=replycopilot
FIREBASE_API_KEY=your-prod-firebase-key
FIREBASE_APP_ID=your-prod-app-id

# Testing
ENABLE_MOCK_DATA=false
MOCK_API_DELAY_MS=0
SKIP_AUTH=false

# Logging
LOG_LEVEL=info
LOG_TO_FILE=true
LOG_FILE_PATH=/var/log/replycopilot/prod.log

# Rate Limiting
RATE_LIMIT_PER_MINUTE=30
MAX_CONCURRENT_REQUESTS=100

# Security
ENABLE_HTTPS_ONLY=true
ALLOWED_ORIGINS=https://replycopilot.com
```

---

## 🔒 Secrets Management

### What to NEVER commit to Git:

```gitignore
# Environment files
.env
.env.local
.env.development
.env.production
.env.*.local

# Firebase
GoogleService-Info.plist
google-services.json
firebase-adminsdk-*.json
FirebaseConfig.swift

# Azure
local.settings.json
*.publishsettings
publish-profile-*.xml

# API Keys
**/config/secrets.json
**/config/keys.json
api-keys.txt

# Certificates
*.p12
*.cer
*.certSigningRequest
*.mobileprovision
```

### Secure Storage Options:

1. **Azure Key Vault** - For backend secrets
2. **iOS Keychain** - For app secrets
3. **Environment Variables** - For CI/CD (GitHub Secrets)
4. **1Password/LastPass** - For team sharing

---

## ✅ Configuration Checklist

### iOS App Setup
- [ ] Update `Config.swift` with Azure Function URL and key
- [ ] Add `GoogleService-Info.plist` to Xcode project
- [ ] Configure bundle identifier: `com.replycopilot.app`
- [ ] Set up App Groups: `group.com.replycopilot.shared`
- [ ] Configure Keychain Groups: `com.replycopilot.keychain`
- [ ] Enable required capabilities in Xcode

### Backend Setup
- [ ] Create `local.settings.json` for local testing
- [ ] Deploy to Azure Function App
- [ ] Set environment variables in Azure Portal
- [ ] Configure Key Vault references
- [ ] Enable Application Insights
- [ ] Set up CORS for allowed origins

### Website Setup
- [ ] Create `config.js` with Calendly URL
- [ ] Add Google Analytics tracking code
- [ ] Update App Store download link
- [ ] Configure social media links
- [ ] Test booking flow end-to-end

### Firebase Setup
- [ ] Create Firebase project
- [ ] Enable Authentication (Email, Google, Apple)
- [ ] Create Firestore database
- [ ] Configure security rules
- [ ] Download `GoogleService-Info.plist`
- [ ] Set up Firebase Admin SDK for backend

### Security
- [ ] All secrets stored in Key Vault or Keychain
- [ ] No secrets committed to Git
- [ ] HTTPS enabled everywhere
- [ ] CORS configured correctly
- [ ] Rate limiting enabled
- [ ] Input validation on all endpoints

---

## 🚀 Quick Start Commands

### Local Development

```bash
# Start backend locally
cd backend
npm install
func start

# Test API locally
curl -X POST http://localhost:7071/api/generateReplies \
  -H "Content-Type: application/json" \
  -d '{"image":"base64_data","platform":"whatsapp","tone":"professional"}'

# Build iOS app in Xcode
open ios/ReplyCopilot.xcodeproj
# Press Cmd+B to build
# Press Cmd+R to run
```

### Deploy to Production

```bash
# Deploy backend
cd backend
func azure functionapp publish replycopilot-api

# Deploy website
cd website
vercel --prod

# Or Netlify
netlify deploy --prod --dir=.
```

---

## 📚 Resources

- **Azure Key Vault**: https://azure.microsoft.com/services/key-vault/
- **Firebase Console**: https://console.firebase.google.com
- **Environment Variables Best Practices**: https://12factor.net/config
- **iOS Keychain Services**: https://developer.apple.com/documentation/security/keychain_services

---

**All configuration templates ready! Update with your actual values before deployment.** 🔐

Built with [Claude Code](https://claude.com/claude-code)

Last updated: October 3, 2025
