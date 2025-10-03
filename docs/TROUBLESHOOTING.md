# 🔧 ReplyCopilot - Troubleshooting Guide

Common issues and solutions for deploying and running ReplyCopilot.

---

## 📱 iOS App Issues

### Build Errors

#### "No such module 'FirebaseAuth'"

**Problem:** Firebase SDK not properly added to project.

**Solution:**
```bash
# In Xcode:
1. File → Packages → Resolve Package Versions
2. Wait for download to complete
3. Clean Build Folder (Cmd+Shift+K)
4. Build again (Cmd+B)
```

**If still failing:**
1. File → Packages → Reset Package Caches
2. Restart Xcode
3. Build again

---

#### "Could not find module 'ReplyCopilot' for target 'ShareExtension'"

**Problem:** Shared files not added to extension targets.

**Solution:**
1. Select file in Project Navigator
2. Open File Inspector (right panel)
3. Under "Target Membership", check:
   - ✅ ReplyCopilot
   - ✅ ShareExtension
   - ✅ KeyboardExtension
4. Rebuild

---

#### "Bundle identifier is already in use"

**Problem:** Bundle ID conflicts with existing app.

**Solution:**
```swift
// In Config.swift, change:
static let bundleIdentifier = "com.YOUR_DOMAIN.replycopilot"

// Also update in:
// - Xcode Project Settings → General → Bundle Identifier
// - Info.plist (if manually edited)
// - Firebase Console (add new iOS app with new bundle ID)
```

---

#### "Provisioning profile doesn't support App Groups"

**Problem:** App Groups capability not in provisioning profile.

**Solution:**
1. Go to https://developer.apple.com/account
2. Certificates, Identifiers & Profiles
3. Select your App ID
4. Click "Edit"
5. Enable "App Groups"
6. Save
7. In Xcode: Settings → Account → Download Manual Profiles
8. Clean and rebuild

---

### Runtime Crashes

#### App crashes on launch with "Firebase not configured"

**Problem:** GoogleService-Info.plist missing or not added to target.

**Solution:**
1. Download GoogleService-Info.plist from Firebase Console
2. Drag into Xcode project
3. **Important:** Check "Copy items if needed"
4. **Important:** Add to targets: ReplyCopilot, ShareExtension
5. **Don't** add to KeyboardExtension (Firebase doesn't work in keyboards)
6. Rebuild and run

---

#### "Keychain error: errSecItemNotFound"

**Problem:** Trying to read token before it's saved.

**Solution:**
```swift
// Always check if token exists before reading:
do {
    let token = try KeychainItem.sharedApiToken.read()
} catch KeychainError.itemNotFound {
    // User not logged in, show login screen
    showLoginScreen()
} catch {
    // Other keychain error
    print("Keychain error: \(error)")
}
```

---

#### Share Extension not appearing in Share Sheet

**Problem:** Extension not properly registered or app not installed.

**Solution:**
1. **Completely delete app** from device (don't just rebuild)
2. Restart device
3. Build and run again from Xcode
4. Extension should now appear

**Still not working?**
```bash
# Check bundle IDs match:
# Main app: com.replycopilot.app
# Extension: com.replycopilot.app.share  # Must be child of main app

# In Xcode → ShareExtension target → General:
# Bundle Identifier: com.replycopilot.app.share
```

---

#### Custom Keyboard not appearing in keyboard list

**Problem:** Keyboard extension not registered or bundle ID wrong.

**Solution:**
1. Delete app completely
2. Check bundle ID: `com.replycopilot.app.keyboard`
3. Rebuild and install
4. Go to Settings → General → Keyboard → Keyboards
5. Tap "Add New Keyboard..."
6. Look for "ReplyCopilot"

**If still missing:**
- Restart device
- Reinstall app
- Check keyboard extension Info.plist for NSExtension configuration

---

### API/Network Issues

#### "API request failed: SSL error"

**Problem:** Certificate pinning or TLS issue.

**Solution:**
```swift
// Temporarily disable certificate pinning for testing:
// In APIClient.swift:
#if DEBUG
let session = URLSession.shared  // Use default session
#else
let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
#endif
```

**Production:** Ensure backend has valid SSL certificate.

---

#### "Rate limit exceeded" error on free tier

**Problem:** Used all 20 daily requests.

**Solution:**
```swift
// Show upgrade prompt:
func handleRateLimitError() {
    let alert = UIAlertController(
        title: "Daily Limit Reached",
        message: "You've used all 20 free replies today. Upgrade to Pro for unlimited replies!",
        preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "Upgrade", style: .default) { _ in
        self.showSubscriptionView()
    })
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    present(alert, animated: true)
}
```

**Or wait:** Limits reset at midnight UTC.

---

## ☁️ Azure Deployment Issues

### Azure CLI

#### "az: command not found"

**Problem:** Azure CLI not installed.

**Solution:**
```bash
# macOS:
brew install azure-cli

# Windows:
# Download from: https://aka.ms/installazurecliwindows

# Linux:
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

---

#### "Please run 'az login' to access your accounts"

**Problem:** Not logged into Azure.

**Solution:**
```bash
az login

# Browser will open for authentication
# Select your Azure account
# Return to terminal

# Verify login:
az account show
```

---

### Azure OpenAI

#### "Deployment not found" error

**Problem:** GPT-4o Vision model not deployed.

**Solution:**
```bash
# Check available deployments:
az cognitiveservices account deployment list \
  --name replycopilot-openai \
  --resource-group replycopilot-rg

# If empty, deploy model:
az cognitiveservices account deployment create \
  --name replycopilot-openai \
  --resource-group replycopilot-rg \
  --deployment-name gpt-4o-vision \
  --model-name gpt-4o-vision-preview \
  --model-version "2024-05-01" \
  --model-format OpenAI \
  --sku-capacity 10 \
  --sku-name Standard
```

---

#### "Quota exceeded" error

**Problem:** Azure OpenAI quota insufficient.

**Solution:**
1. Go to Azure Portal → Your OpenAI resource
2. Click "Quotas" in left menu
3. Request quota increase
4. Wait for approval (usually 1-2 business days)

**Temporary workaround:**
- Reduce concurrent requests
- Add rate limiting in backend
- Use lower `sku-capacity`

---

### Azure Functions

#### Function app deployment fails

**Problem:** Various deployment issues.

**Solution:**
```bash
# Check deployment logs:
az functionapp log deployment show \
  --name replycopilot-api \
  --resource-group replycopilot-rg

# Common fixes:
# 1. Ensure package.json is valid:
cd backend
npm install  # Regenerate package-lock.json

# 2. Check Node.js version:
# Azure Functions supports Node.js 18, 20
# Update in package.json if needed

# 3. Redeploy:
bash deploy-azure.sh
```

---

#### Function returns 500 error

**Problem:** Runtime error in backend code.

**Solution:**
```bash
# Check Application Insights logs:
az monitor app-insights query \
  --app replycopilot-insights \
  --analytics-query "exceptions | order by timestamp desc | take 10"

# Or view in Azure Portal:
# Your Function App → Monitor → Logs

# Common issues:
# - Missing environment variables
# - Invalid OpenAI API key
# - Network timeout to OpenAI
```

---

## 🔥 Firebase Issues

### Authentication

#### "Firebase Auth domain not authorized"

**Problem:** OAuth redirect URI not whitelisted.

**Solution:**
1. Firebase Console → Authentication → Settings
2. Scroll to "Authorized domains"
3. Add your domain (e.g., `replycopilot.app`)
4. For local testing, add `localhost`

---

#### "Google Sign-In failed"

**Problem:** GoogleService-Info.plist has wrong OAuth client ID.

**Solution:**
1. Firebase Console → Project Settings → General
2. Download **latest** GoogleService-Info.plist
3. Replace in Xcode project
4. Clean build folder and rebuild

---

### Firestore

#### "Permission denied" when writing to Firestore

**Problem:** Security rules too restrictive.

**Solution:**
```javascript
// In Firebase Console → Firestore → Rules:
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Allow users to read/write their own preferences
    match /userPreferences/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

**Test rules** before deploying to production!

---

## 🔐 Security Issues

### Keychain Access

#### "Keychain access denied" error

**Problem:** App not properly configured for Keychain Sharing.

**Solution:**
1. Xcode → Target → Signing & Capabilities
2. Click **+ Capability**
3. Add **Keychain Sharing**
4. Add keychain group: `com.replycopilot.keychain`
5. Repeat for **all 3 targets** (main app, share extension, keyboard)

---

### App Groups

#### "App Group not accessible"

**Problem:** App Groups not configured or bundle IDs don't match.

**Solution:**
1. Check bundle IDs follow pattern:
   - Main: `com.replycopilot.app`
   - Share: `com.replycopilot.app.share`
   - Keyboard: `com.replycopilot.app.keyboard`

2. All targets must have **same** App Group:
   - Group ID: `group.com.replycopilot.shared`

3. Verify in code:
```swift
// In Config.swift:
static let appGroupIdentifier = "group.com.replycopilot.shared"

// Test access:
let defaults = UserDefaults(suiteName: Config.appGroupIdentifier)
defaults?.set("test", forKey: "test")
let value = defaults?.string(forKey: "test")
print("App Groups working: \(value != nil)")
```

---

## 📲 Device Testing

### Simulator Issues

#### Extensions don't work in Simulator

**Problem:** Share/Keyboard extensions have limited Simulator support.

**Solution:**
- **Use a real device** for testing extensions
- Simulator can test main app UI
- Extensions require physical iOS device

---

### Physical Device Issues

#### "Untrusted Developer" warning

**Problem:** Developer certificate not trusted.

**Solution:**
1. Settings → General → VPN & Device Management
2. Find your developer account
3. Tap "Trust"
4. Confirm trust

---

#### App installed but won't launch

**Problem:** Code signing or provisioning issue.

**Solution:**
1. Xcode → Settings → Accounts
2. Select your Apple ID
3. Click "Download Manual Profiles"
4. In project settings, set "Automatically manage signing"
5. Clean build folder
6. Rebuild and install

---

## 🐛 Debugging Tips

### Enable Debug Logging

```swift
// In Config.swift:
static var isDebugMode: Bool {
    #if DEBUG
    return true
    #else
    return false
    #endif
}

// In code:
if Config.isDebugMode {
    print("🔍 API Request: \(endpoint)")
    print("🔍 Parameters: \(parameters)")
}
```

### Check Network Requests

```swift
// In APIClient.swift, add logging:
private func logRequest(_ request: URLRequest) {
    print("📡 \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "?")")
    print("📡 Headers: \(request.allHTTPHeaderFields ?? [:])")
    if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
        print("📡 Body: \(bodyString.prefix(200))...")  // First 200 chars
    }
}

private func logResponse(_ response: HTTPURLResponse, data: Data) {
    print("📥 Status: \(response.statusCode)")
    print("📥 Headers: \(response.allHeaderFields)")
    if let bodyString = String(data: data, encoding: .utf8) {
        print("📥 Body: \(bodyString.prefix(500))...")
    }
}
```

### Monitor Memory Usage

```swift
// Check for memory leaks:
class APIClient: ObservableObject {
    deinit {
        print("🗑️ APIClient deallocated")  // Should print when app closes
    }
}
```

---

## 🆘 Still Stuck?

### Checklist

Before asking for help, verify:

- [ ] Read this entire troubleshooting guide
- [ ] Checked [QUICK_START_CHECKLIST.md](../QUICK_START_CHECKLIST.md)
- [ ] Reviewed [XCODE_PROJECT_SETUP.md](../XCODE_PROJECT_SETUP.md)
- [ ] Checked Firebase Console for errors
- [ ] Checked Azure Portal for errors
- [ ] Tried on a real device (not just Simulator)
- [ ] Tried deleting app and reinstalling
- [ ] Tried restarting Xcode
- [ ] Tried restarting device
- [ ] Checked internet connection

### Get Help

1. **GitHub Issues:** https://github.com/DandaAkhilReddy/Agent_danda/issues
   - Search existing issues first
   - Provide full error message
   - Include iOS version, Xcode version, device model

2. **Stack Overflow:**
   - Tag: `[ios]` `[swift]` `[swiftui]` `[azure]` `[firebase]`
   - Include code snippet
   - Include error message

3. **Documentation:**
   - Apple Developer Forums: https://developer.apple.com/forums/
   - Azure Support: https://portal.azure.com → Support
   - Firebase Support: https://firebase.google.com/support

---

## 📚 Additional Resources

- **Apple Developer Documentation:** https://developer.apple.com/documentation/
- **Azure Documentation:** https://docs.microsoft.com/azure/
- **Firebase Documentation:** https://firebase.google.com/docs/
- **Swift Forums:** https://forums.swift.org/

---

**Last Updated:** October 3, 2025

**Found a solution not listed here?** Please contribute by opening a PR!
