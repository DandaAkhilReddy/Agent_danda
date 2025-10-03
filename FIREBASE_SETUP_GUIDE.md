# 🔥 Firebase Setup Guide for ReplyCopilot

Complete step-by-step guide to set up Firebase for ReplyCopilot with database schema, authentication, and analytics.

---

## 📋 Overview

Firebase provides:
- **Authentication** - User login (Email, Google, Apple Sign-in)
- **Firestore Database** - User preferences, usage metrics, reply history
- **Analytics** - User engagement tracking
- **Cloud Messaging** - Push notifications (future)

---

## 🚀 Step 1: Create Firebase Project

### 1.1 Go to Firebase Console

1. Visit: https://console.firebase.google.com
2. Click **"Add project"** or **"Create a project"**
3. Enter project name: **ReplyCopilot**
4. Click **Continue**

### 1.2 Configure Google Analytics

1. Enable Google Analytics: **Yes** (recommended)
2. Select or create Analytics account
3. Click **Create project**
4. Wait 30-60 seconds for project creation

---

## 🔐 Step 2: Enable Authentication

### 2.1 Navigate to Authentication

1. In Firebase Console, click **Authentication** in left sidebar
2. Click **Get started**

### 2.2 Enable Sign-in Methods

**Enable Email/Password:**
1. Click **Sign-in method** tab
2. Click **Email/Password**
3. Toggle **Enable**
4. Click **Save**

**Enable Google Sign-in:**
1. Click **Google** provider
2. Toggle **Enable**
3. Enter support email
4. Click **Save**

**Enable Apple Sign-in (for iOS):**
1. Click **Apple** provider
2. Toggle **Enable**
3. You'll need to configure this later with:
   - Apple Developer account
   - Services ID
   - Team ID
   - Key ID
   - Private key (.p8 file)
4. Click **Save**

---

## 📊 Step 3: Create Firestore Database

### 3.1 Navigate to Firestore

1. Click **Firestore Database** in left sidebar
2. Click **Create database**

### 3.2 Configure Security Rules

1. Select **Start in production mode** (we'll add custom rules)
2. Click **Next**

### 3.3 Choose Location

1. Select location: **us-central** (or closest to your users)
   - Note: This cannot be changed later
2. Click **Enable**
3. Wait 1-2 minutes for database creation

### 3.4 Create Database Schema

**Create these collections manually:**

#### Collection 1: `users`
- Document ID: `{userId}` (auto-generated)
- Fields:
```
email: string
displayName: string
photoURL: string
createdAt: timestamp
lastLoginAt: timestamp
preferences: map {
  defaultTone: string ("professional" | "friendly" | "funny" | "flirty")
  defaultPlatform: string ("whatsapp" | "imessage" | "instagram" etc.)
  keyboardEnabled: boolean
  notificationsEnabled: boolean
  theme: string ("light" | "dark" | "auto")
}
subscription: map {
  tier: string ("free" | "pro" | "enterprise")
  status: string ("active" | "canceled" | "expired")
  currentPeriodStart: timestamp
  currentPeriodEnd: timestamp
  cancelAtPeriodEnd: boolean
}
usage: map {
  totalRepliesGenerated: number
  repliesThisMonth: number
  lastReplyAt: timestamp
  favoriteCount: number
  averageRating: number
}
```

**To create:**
1. Click **Start collection**
2. Collection ID: `users`
3. Click **Next**
4. Add first document with your test user data
5. Click **Save**

#### Collection 2: `replies`
- Document ID: auto-generated
- Fields:
```
userId: string
platform: string
tone: string
suggestions: array [
  {
    text: string
    confidence: number
    ranking: number
  }
]
selectedSuggestion: string (or null)
rating: number (1-5, or null)
isFavorite: boolean
createdAt: timestamp
processingTime: number (milliseconds)
metadata: map {
  platform: string
  tone: string
  imageHash: string (optional, for deduplication)
}
```

**To create:**
1. Click **Start collection**
2. Collection ID: `replies`
3. Click **Next**
4. Add sample document (or skip - will be auto-created by app)
5. Click **Save**

#### Collection 3: `analytics`
- Document ID: `{date}` (YYYY-MM-DD format)
- Fields:
```
date: timestamp
totalUsers: number
activeUsers: number
totalReplies: number
repliesByPlatform: map {
  whatsapp: number
  imessage: number
  instagram: number
  outlook: number
  slack: number
  teams: number
}
repliesByTone: map {
  professional: number
  friendly: number
  funny: number
  flirty: number
}
averageProcessingTime: number
errorCount: number
conversionRate: number (free to paid)
```

### 3.5 Configure Security Rules

1. Click **Rules** tab
2. Replace with these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }

    // Helper function to check if user owns the document
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Users collection - users can only read/write their own data
    match /users/{userId} {
      allow read: if isOwner(userId);
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isOwner(userId);
      allow delete: if false; // Prevent deletion
    }

    // Replies collection - users can only access their own replies
    match /replies/{replyId} {
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
    }

    // Analytics collection - read-only for authenticated users
    match /analytics/{document=**} {
      allow read: if isAuthenticated();
      allow write: if false; // Only backend can write
    }
  }
}
```

3. Click **Publish**

---

## 📱 Step 4: Add iOS App to Firebase

### 4.1 Register iOS App

1. In Firebase Console, click **Project Overview** (gear icon)
2. Click **Project settings**
3. Scroll to **Your apps** section
4. Click iOS icon
5. Enter iOS bundle ID: `com.replycopilot.app`
   - Must match Xcode bundle identifier exactly
6. Enter app nickname: **ReplyCopilot iOS**
7. Enter App Store ID: (leave blank for now, add after App Store submission)
8. Click **Register app**

### 4.2 Download Configuration File

1. Click **Download GoogleService-Info.plist**
2. Save file to your computer
3. **IMPORTANT**: You'll add this to Xcode project later
4. Click **Next**

### 4.3 Add Firebase SDK (Skip for now)

1. Click **Next** (we'll do this in Xcode later)
2. Click **Continue to console**

---

## 📊 Step 5: Enable Analytics

### 5.1 Configure Analytics

1. Click **Analytics** in left sidebar
2. Click **Dashboard**
3. Analytics is auto-enabled

### 5.2 Create Custom Events

Go to **Analytics > Events** and mark these as conversion events:

- `user_signup` - New user registration
- `reply_generated` - Reply suggestion generated
- `reply_selected` - User selected a suggestion
- `upgrade_to_pro` - User upgraded to Pro
- `demo_booked` - User booked a demo

---

## 🔑 Step 6: Get Configuration Values

### 6.1 Get API Keys

1. Go to **Project Settings** (gear icon)
2. Scroll to **Your apps** section
3. Click iOS app
4. Note these values (you'll need them):

```
API Key: [Your API key]
Project ID: [Your project ID]
Storage Bucket: [Your storage bucket]
Messaging Sender ID: [Your sender ID]
App ID: [Your app ID]
```

### 6.2 Create Environment Config File

Create `ios/ReplyCopilot/Config/FirebaseConfig.swift`:

```swift
import Foundation

struct FirebaseConfig {
    static let apiKey = "YOUR_API_KEY"
    static let projectID = "YOUR_PROJECT_ID"
    static let storageBucket = "YOUR_STORAGE_BUCKET"
    static let messagingSenderID = "YOUR_MESSAGING_SENDER_ID"
    static let appID = "YOUR_APP_ID"

    // Optional: Analytics
    static let measurementID = "YOUR_MEASUREMENT_ID"
}
```

---

## 🔧 Step 7: Firebase Extensions (Optional)

### 7.1 Install Useful Extensions

**Resize Images** (if storing user avatars):
1. Go to **Extensions**
2. Search for "Resize Images"
3. Click **Install**

**Delete User Data** (for GDPR compliance):
1. Search for "Delete User Data"
2. Click **Install**

**Trigger Email** (for notifications):
1. Search for "Trigger Email"
2. Click **Install**

---

## 💰 Step 8: Set Up Billing (for Production)

### 8.1 Upgrade to Blaze Plan

**Free tier limits:**
- 50K reads/day
- 20K writes/day
- 20K deletes/day
- 1GB stored
- 10GB/month bandwidth

**When to upgrade:**
- When you exceed free tier
- To use Cloud Functions
- To use Firebase Extensions

**To upgrade:**
1. Go to **Project Settings** > **Usage and billing**
2. Click **Modify plan**
3. Select **Blaze (Pay as you go)**
4. Add payment method
5. Set budget alerts

### 8.2 Set Budget Alerts

1. Go to **Usage and billing**
2. Click **Details & settings**
3. Set budget: $10/month (to start)
4. Enter alert email
5. Click **Save**

---

## 🧪 Step 9: Test Firebase Connection

### 9.1 Using Firebase Console

1. Go to **Firestore Database**
2. Click **Start collection**
3. Add test document
4. Try to read it from your app

### 9.2 Using Firebase CLI (Optional)

Install Firebase CLI:
```bash
npm install -g firebase-tools
```

Login:
```bash
firebase login
```

Test connection:
```bash
firebase projects:list
```

Deploy security rules:
```bash
cd /path/to/ReplyCopilot
firebase deploy --only firestore:rules
```

---

## 📊 Step 10: Database Indexes

### 10.1 Create Composite Indexes

For efficient queries, create these indexes:

**Index 1: User Replies Query**
- Collection: `replies`
- Fields:
  1. `userId` (Ascending)
  2. `createdAt` (Descending)

**Index 2: Platform Analytics**
- Collection: `replies`
- Fields:
  1. `platform` (Ascending)
  2. `createdAt` (Descending)

**Index 3: User Favorites**
- Collection: `replies`
- Fields:
  1. `userId` (Ascending)
  2. `isFavorite` (Ascending)
  3. `createdAt` (Descending)

**To create:**
1. Go to **Firestore Database** > **Indexes** tab
2. Click **Create Index**
3. Select collection
4. Add fields with sort order
5. Click **Create**

Or wait for app to trigger index creation automatically (Firebase will show error with link to create index).

---

## 🔒 Step 11: Security Best Practices

### 11.1 Environment Variables

Never commit these to Git:
- `GoogleService-Info.plist`
- API keys
- Service account keys

Add to `.gitignore`:
```
# Firebase
GoogleService-Info.plist
FirebaseConfig.swift
firebase-debug.log
.firebase/
```

### 11.2 Use App Check (Recommended)

Prevent abuse:
1. Go to **App Check** in Firebase Console
2. Click **Get started**
3. Register iOS app
4. Choose provider: **DeviceCheck** (for iOS)
5. Enable enforcement for:
   - Firestore
   - Authentication
   - Analytics

---

## 📊 Step 12: Monitoring & Logs

### 12.1 Enable Crashlytics

1. Go to **Crashlytics** in Firebase Console
2. Click **Get started**
3. Follow iOS setup instructions
4. Add Crashlytics SDK to Xcode

### 12.2 View Logs

1. Go to **Firestore** > **Usage** tab
2. Monitor:
   - Read/write operations
   - Storage usage
   - Bandwidth usage
3. Set up alerts for unusual activity

---

## ✅ Verification Checklist

After setup, verify:

- [ ] Firebase project created
- [ ] Authentication enabled (Email, Google, Apple)
- [ ] Firestore database created
- [ ] Collections created: `users`, `replies`, `analytics`
- [ ] Security rules configured
- [ ] iOS app registered
- [ ] `GoogleService-Info.plist` downloaded
- [ ] Analytics enabled
- [ ] Custom events configured
- [ ] Indexes created
- [ ] Budget alerts set (if on Blaze plan)
- [ ] App Check enabled (optional but recommended)

---

## 🚀 Next Steps

1. **Add GoogleService-Info.plist to Xcode**
   - Drag file into Xcode project root
   - Ensure "Copy items if needed" is checked
   - Add to all targets (main app + extensions)

2. **Install Firebase SDK in Xcode**
   - Add via Swift Package Manager
   - Or add via CocoaPods

3. **Initialize Firebase in app**
   - Add to `ReplyCopilotApp.swift`

4. **Test authentication flow**
   - Sign up new user
   - Verify user document created in Firestore

5. **Test database operations**
   - Create reply document
   - Read user preferences
   - Update usage metrics

---

## 📚 Useful Resources

- **Firebase Console**: https://console.firebase.google.com
- **Firebase iOS Documentation**: https://firebase.google.com/docs/ios/setup
- **Firestore Documentation**: https://firebase.google.com/docs/firestore
- **Security Rules Guide**: https://firebase.google.com/docs/firestore/security/get-started
- **Firebase Extensions**: https://firebase.google.com/products/extensions

---

## 💡 Cost Estimation

**Free Tier (Spark Plan):**
- Good for: Development, testing, MVP launch
- Limits: 50K reads/day, 20K writes/day
- Cost: $0/month

**Blaze Plan (Pay as you go):**
- Expected cost for 1,000 users: $5-20/month
- Expected cost for 10,000 users: $50-150/month
- Expected cost for 100,000 users: $500-1,500/month

**Cost breakdown:**
- Firestore: $0.06 per 100K reads, $0.18 per 100K writes
- Storage: $0.18/GB/month
- Bandwidth: $0.12/GB
- Authentication: Free (unlimited)
- Analytics: Free (unlimited)

---

## 🎯 Sample Data for Testing

### Test User Document

```json
{
  "email": "test@replycopilot.com",
  "displayName": "Test User",
  "photoURL": "",
  "createdAt": "2025-10-03T12:00:00Z",
  "lastLoginAt": "2025-10-03T14:30:00Z",
  "preferences": {
    "defaultTone": "professional",
    "defaultPlatform": "whatsapp",
    "keyboardEnabled": true,
    "notificationsEnabled": true,
    "theme": "auto"
  },
  "subscription": {
    "tier": "free",
    "status": "active",
    "currentPeriodStart": "2025-10-03T12:00:00Z",
    "currentPeriodEnd": "2025-11-03T12:00:00Z",
    "cancelAtPeriodEnd": false
  },
  "usage": {
    "totalRepliesGenerated": 47,
    "repliesThisMonth": 12,
    "lastReplyAt": "2025-10-03T14:25:00Z",
    "favoriteCount": 5,
    "averageRating": 4.8
  }
}
```

### Test Reply Document

```json
{
  "userId": "test-user-id-123",
  "platform": "whatsapp",
  "tone": "professional",
  "suggestions": [
    {
      "text": "Thanks for reaching out! I'll get back to you shortly.",
      "confidence": 0.95,
      "ranking": 1
    },
    {
      "text": "I appreciate your message. Let me review this and respond soon.",
      "confidence": 0.88,
      "ranking": 2
    },
    {
      "text": "Thank you. I'll provide a detailed response by end of day.",
      "confidence": 0.82,
      "ranking": 3
    }
  ],
  "selectedSuggestion": "Thanks for reaching out! I'll get back to you shortly.",
  "rating": 5,
  "isFavorite": true,
  "createdAt": "2025-10-03T14:25:30Z",
  "processingTime": 1250,
  "metadata": {
    "platform": "whatsapp",
    "tone": "professional",
    "imageHash": "abc123def456"
  }
}
```

---

**Firebase setup complete! Your database is ready for ReplyCopilot.** 🔥

Built with [Claude Code](https://claude.com/claude-code)

Last updated: October 3, 2025
