# 🏗️ ReplyCopilot Architecture

## System Overview

ReplyCopilot uses a **privacy-first, cloud-native architecture** where:
1. Screenshots are processed in-memory only (never saved)
2. Azure OpenAI Vision reads the image directly (no OCR)
3. AI generates contextual replies based on platform + tone
4. iOS keyboard extension enables one-tap insertion

---

## Component Architecture

### 1. iOS Client Layer

#### Main App
- **Purpose**: User settings, authentication, onboarding
- **Tech**: Swift, SwiftUI
- **Features**:
  - Tone preference management (Professional/Friendly/Funny/Flirty)
  - Platform detection settings
  - Firebase authentication
  - Usage analytics (anonymous)

#### Share Extension
- **Purpose**: Receives screenshots via iOS Share Sheet
- **Tech**: Swift, UIKit/SwiftUI
- **Flow**:
  1. User shares screenshot to app
  2. Image loaded into memory (UIImage)
  3. Sent to Azure backend via HTTPS
  4. Displays 3-5 reply suggestions
  5. User taps to copy
  6. Image deleted from memory

#### Keyboard Extension
- **Purpose**: Shows suggestions in any app for one-tap insert
- **Tech**: Swift, Custom Keyboard SDK
- **Features**:
  - Reads suggestions from App Group shared storage
  - Displays recent replies
  - Inserts text on tap
  - Works across all messaging apps

#### Shared Framework
- **Purpose**: Common code between extensions and main app
- **Includes**:
  - Network client (Azure API calls)
  - Authentication (Azure AD tokens)
  - Data models
  - Security utilities (encryption, keychain)

---

### 2. Azure Backend Layer

#### API Gateway (Azure Functions / App Service)
```
Endpoint: https://api.replycopilot.com

POST /api/v1/generate-replies
Headers:
  Authorization: Bearer <azure-ad-token>
  Content-Type: application/json
Body:
  {
    "image": "<base64-encoded-screenshot>",
    "platform": "whatsapp" | "imessage" | "instagram" | "outlook",
    "tone": "professional" | "friendly" | "funny" | "flirty",
    "userId": "<firebase-uid>",
    "metadata": {
      "timestamp": 1696300000,
      "language": "en"
    }
  }
Response:
  {
    "suggestions": [
      "Thanks! I'll check that out 😊",
      "Appreciate it! Let me know if you need anything",
      "Got it, thanks for sharing!"
    ],
    "platform": "whatsapp",
    "tone": "friendly",
    "processingTime": 850
  }
```

#### Processing Pipeline
```
┌──────────────────────────────────────────────────────┐
│ 1. Request Validation                                │
│    • Verify Azure AD token                          │
│    • Rate limiting check                            │
│    • Validate payload schema                        │
└──────────────────────────────────────────────────────┘
                      ↓
┌──────────────────────────────────────────────────────┐
│ 2. Image Processing                                  │
│    • Decode base64 image                            │
│    • Validate image format/size                     │
│    • Keep in memory buffer only                     │
└──────────────────────────────────────────────────────┘
                      ↓
┌──────────────────────────────────────────────────────┐
│ 3. Azure OpenAI Vision Call                         │
│    • Build prompt with platform + tone              │
│    • Send image to GPT-4o Vision API                │
│    • Receive reply suggestions                      │
└──────────────────────────────────────────────────────┘
                      ↓
┌──────────────────────────────────────────────────────┐
│ 4. Post-Processing                                   │
│    • Filter inappropriate content                    │
│    • Rank suggestions by relevance                  │
│    • Format for platform (emoji, length, etc.)      │
└──────────────────────────────────────────────────────┘
                      ↓
┌──────────────────────────────────────────────────────┐
│ 5. Response & Cleanup                               │
│    • Return JSON with suggestions                    │
│    • Zero memory buffers                            │
│    • Log metadata only (no content)                 │
└──────────────────────────────────────────────────────┘
```

#### Azure OpenAI Integration
```javascript
// Pseudo-code for vision call
const response = await azureOpenAI.chat.completions.create({
  model: "gpt-4o-vision",
  messages: [
    {
      role: "system",
      content: `You are ReplyCopilot. Generate ${tone} replies for ${platform}.
                Rules:
                - Read the chat from the screenshot
                - Generate 3-5 reply options
                - Match platform style (emojis for WhatsApp, formal for Outlook)
                - Never store or repeat screenshot content
                - Max 2 sentences per reply`
    },
    {
      role: "user",
      content: [
        { type: "text", text: "Generate reply suggestions:" },
        { type: "image_url", image_url: { url: imageDataUrl } }
      ]
    }
  ],
  max_tokens: 200,
  temperature: 0.7
});
```

---

### 3. Azure Infrastructure

#### Network Architecture
```
┌─────────────────────────────────────────────────────────┐
│                  Internet (User)                        │
└─────────────────────────────────────────────────────────┘
                      ↓ TLS 1.3
┌─────────────────────────────────────────────────────────┐
│           Azure Front Door (WAF + DDoS)                 │
└─────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│              Azure API Management                       │
│  • Rate limiting                                        │
│  • API key/token validation                            │
│  • Request logging (metadata only)                     │
└─────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│           Azure VNet (Private Network)                  │
│  ┌───────────────────────────────────────────────┐     │
│  │   Azure Functions / App Service                │     │
│  │   • Private endpoint                          │     │
│  │   • Managed identity                          │     │
│  └───────────────────────────────────────────────┘     │
│                      ↓                                  │
│  ┌───────────────────────────────────────────────┐     │
│  │   Azure OpenAI Service                        │     │
│  │   • Private endpoint                          │     │
│  │   • VNet integration                          │     │
│  └───────────────────────────────────────────────┘     │
│                      ↓                                  │
│  ┌───────────────────────────────────────────────┐     │
│  │   Azure Key Vault                             │     │
│  │   • API keys, secrets                         │     │
│  │   • Managed identity access                   │     │
│  └───────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────┘
```

#### Security Layers

1. **Edge Security**
   - Azure Front Door with WAF
   - DDoS protection
   - Geo-filtering
   - Rate limiting

2. **Network Security**
   - VNet isolation
   - Private endpoints (no public internet)
   - NSG rules (IP allowlists)
   - Service endpoints

3. **Identity & Access**
   - Azure AD authentication
   - Managed identities
   - RBAC policies
   - Conditional access

4. **Data Security**
   - TLS 1.3 in transit
   - No data at rest (ephemeral only)
   - Key Vault for secrets
   - Certificate pinning (client)

5. **Monitoring & Compliance**
   - Azure Monitor / App Insights
   - Security Center alerts
   - Compliance policies
   - Audit logs (metadata only)

---

### 4. Firebase Layer

#### Firestore Collections

```javascript
// users collection
users/{userId} = {
  email: "user@example.com",
  createdAt: timestamp,
  preferences: {
    defaultTone: "friendly",
    platforms: {
      whatsapp: { tone: "friendly" },
      outlook: { tone: "professional" },
      instagram: { tone: "funny" }
    },
    language: "en"
  },
  usage: {
    totalReplies: 1523,
    lastUsed: timestamp,
    subscriptionTier: "pro"
  }
}

// analytics collection (anonymous)
analytics/{date} = {
  totalRequests: 15234,
  platforms: {
    whatsapp: 5234,
    imessage: 4523,
    instagram: 3234,
    outlook: 2243
  },
  tones: {
    friendly: 6234,
    professional: 4523,
    funny: 2345,
    flirty: 2132
  },
  avgResponseTime: 850
}
```

**Important**: Firebase stores NO screenshots, NO message content, NO conversation text. Only user preferences and anonymous usage counters.

---

### 5. Data Flow (End-to-End)

```
┌─────────────────────────────────────────────────────────────┐
│                    1. User Action                           │
│  • Takes screenshot of chat                                 │
│  • Taps "Share" → "ReplyCopilot"                          │
└─────────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────┐
│              2. Share Extension (iOS)                       │
│  • Loads image into memory (UIImage)                       │
│  • Fetches user's tone preference from App Group           │
│  • Shows loading UI                                         │
└─────────────────────────────────────────────────────────────┘
                      ↓ HTTPS POST (TLS 1.3)
┌─────────────────────────────────────────────────────────────┐
│              3. Azure API Gateway                           │
│  • Validates Azure AD token                                 │
│  • Checks rate limit                                        │
│  • Forwards to Function                                     │
└─────────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────┐
│              4. Azure Function                              │
│  • Decodes base64 image (memory only)                      │
│  • Builds prompt with tone + platform                       │
│  • Calls Azure OpenAI Vision API                           │
└─────────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────┐
│         5. Azure OpenAI (GPT-4o Vision)                    │
│  • Reads screenshot (understands context)                   │
│  • Generates 3-5 reply suggestions                          │
│  • Returns JSON response                                    │
│  • NO STORAGE of image or text                             │
└─────────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────┐
│              6. Azure Function (cleanup)                    │
│  • Receives suggestions from OpenAI                         │
│  • Filters/ranks replies                                    │
│  • Zeros memory buffer (deletes image)                     │
│  • Logs metadata only (no content)                         │
└─────────────────────────────────────────────────────────────┘
                      ↓ HTTPS Response
┌─────────────────────────────────────────────────────────────┐
│              7. Share Extension (iOS)                       │
│  • Receives JSON with suggestions                           │
│  • Writes to App Group storage (for keyboard)              │
│  • Shows suggestions UI                                     │
│  • Deletes screenshot from memory                           │
└─────────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────┐
│              8. User Selection                              │
│  • User taps preferred reply                                │
│  • Text copied to clipboard                                 │
│  • OR: Opens keyboard extension for insert                  │
└─────────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────┐
│              9. Keyboard Extension (iOS)                    │
│  • User switches to ReplyCopilot keyboard                   │
│  • Shows suggestions from App Group storage                 │
│  • One-tap inserts text into any app                        │
└─────────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────┐
│              10. Analytics (Firebase)                       │
│  • Log: user used reply, platform, tone                     │
│  • NO message content, NO screenshot data                   │
│  • Anonymous usage counters only                            │
└─────────────────────────────────────────────────────────────┘
```

---

### 6. Privacy & Security Guarantees

| Layer | Security Measure | Implementation |
|-------|------------------|----------------|
| **Device** | No screenshot persistence | In-memory UIImage only; delete after response |
| **Device** | Secure token storage | iOS Keychain with Secure Enclave |
| **Device** | Memory zeroing | Explicitly zero buffers after use |
| **Transit** | TLS 1.3 encryption | All HTTPS with certificate pinning |
| **Transit** | Token auth | Azure AD OAuth 2.0 bearer tokens |
| **Cloud** | Private network | VNet + private endpoints (no public internet) |
| **Cloud** | No image storage | Ephemeral processing only, immediate deletion |
| **Cloud** | No text logs | Logs contain request ID, timing, model name only |
| **Cloud** | Secret management | Azure Key Vault with managed identities |
| **AI** | No training data | Azure OpenAI policy: your data not used for training |
| **Monitoring** | Metadata only | App Insights logs duration, status, no content |

---

### 7. Scalability

#### Performance Targets
- **Response time**: < 1 second (p50), < 2 seconds (p95)
- **Throughput**: 10,000 requests/minute per region
- **Availability**: 99.9% uptime SLA

#### Scaling Strategy
```
Phase 1 (0-10K users):
  • Single Azure region (US East)
  • Azure Functions consumption plan
  • Firebase free tier

Phase 2 (10K-100K users):
  • Add CDN for assets
  • Azure Functions premium plan
  • Firebase Blaze plan
  • Redis cache for user preferences

Phase 3 (100K-1M users):
  • Multi-region deployment (US, EU, Asia)
  • Azure OpenAI provisioned throughput
  • Cosmos DB for global user data
  • Auto-scaling groups

Phase 4 (1M+ users):
  • Global traffic manager
  • Dedicated OpenAI deployments per region
  • Edge compute for lightweight processing
  • On-device ML fallback (Phi-3-Vision CoreML)
```

---

### 8. Tech Stack Summary

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **iOS App** | Swift 5.9, SwiftUI | Native app UI |
| **Share Extension** | Swift, UIKit | Screenshot capture |
| **Keyboard Extension** | Swift, Custom Keyboard SDK | Reply insertion |
| **Backend API** | Azure Functions (Node.js 20) | API orchestration |
| **AI Model** | Azure OpenAI GPT-4o Vision | Screenshot → Reply |
| **Authentication** | Azure AD + Firebase Auth | User identity |
| **Database** | Firebase Firestore | User preferences |
| **Secrets** | Azure Key Vault | API keys, certificates |
| **Networking** | Azure VNet, Private Link | Isolation |
| **Monitoring** | Azure App Insights | Observability |
| **CI/CD** | GitHub Actions + Xcode Cloud | Deployment |

---

### 9. Development Environment

```bash
# Required tools
- Xcode 15+ (iOS development)
- Azure CLI (cloud deployment)
- Firebase CLI (database setup)
- Node.js 20+ (backend functions)
- Swift 5.9+ (iOS app)

# Project structure
ReplyCopilot/
├── ios/                    # iOS app (Xcode project)
├── backend/                # Azure Functions
├── shared/                 # Shared models/types
├── docs/                   # Documentation
└── scripts/                # Deployment automation
```

---

## Next Steps

1. ✅ Architecture design complete
2. ⏭️ Set up Azure OpenAI Vision endpoint
3. ⏭️ Create iOS Xcode project with extensions
4. ⏭️ Build backend Azure Functions
5. ⏭️ Implement security (TLS, tokens, encryption)
6. ⏭️ Test end-to-end flow
7. ⏭️ Deploy to TestFlight

**Ready to start building!** 🚀
