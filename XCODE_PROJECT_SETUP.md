# 🔨 Xcode Project Setup Guide

**Complete step-by-step instructions to create the Xcode project**

---

## 📋 Prerequisites

- ✅ Mac with macOS 14+ (Sonoma or later)
- ✅ Xcode 15+ installed from App Store
- ✅ Apple Developer account (free tier works for testing)
- ✅ All code files from this project

---

## 🎯 Step-by-Step Instructions

### Part 1: Create New Xcode Project (10 minutes)

#### 1. Create Base Project

1. Open Xcode
2. **File → New → Project** (or Cmd+Shift+N)
3. Select **iOS → App**
4. Click **Next**
5. Configure project:
   - **Product Name:** ReplyCopilot
   - **Team:** Your Apple Developer team
   - **Organization Identifier:** com.yourname (use your domain)
   - **Bundle Identifier:** Will be `com.yourname.replycopilot`
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** None (we'll use our own)
   - **Include Tests:** ✅ Check
6. Click **Next**
7. Choose location: `C:\users\akhil\projects\ReplyCopilot` (if on Mac, equivalent location)
8. Click **Create**

#### 2. Update Bundle Identifier

1. Select **ReplyCopilot** project in navigator
2. Select **ReplyCopilot** target
3. Go to **General** tab
4. Update **Bundle Identifier** to: `com.replycopilot.app`
   (Or keep your own domain, just update Config.swift to match)

---

### Part 2: Add Share Extension Target (5 minutes)

#### 1. Create Share Extension

1. **File → New → Target**
2. Select **iOS → Application Extension → Share Extension**
3. Click **Next**
4. Configure:
   - **Product Name:** ShareExtension
   - **Team:** Same as main app
   - **Language:** Swift
   - **Bundle Identifier:** com.replycopilot.share
5. Click **Finish**
6. Dialog asks "Activate ShareExtension scheme?" → Click **Cancel** (we'll use main scheme)

#### 2. Configure Share Extension

1. Select **ShareExtension** target
2. Go to **Info** tab
3. Expand **NSExtension → NSExtensionAttributes**
4. Set **NSExtensionActivationRule**:
   ```
   Key: NSExtensionActivationSupportsImageWithMaxCount
   Value: 1
   ```

---

### Part 3: Add Keyboard Extension Target (5 minutes)

#### 1. Create Keyboard Extension

1. **File → New → Target**
2. Select **iOS → Application Extension → Custom Keyboard**
3. Click **Next**
4. Configure:
   - **Product Name:** KeyboardExtension
   - **Team:** Same as main app
   - **Language:** Swift
   - **Bundle Identifier:** com.replycopilot.keyboard
5. Click **Finish**
6. Click **Cancel** on activate scheme dialog

#### 2. Configure Keyboard Extension

1. Select **KeyboardExtension** target
2. Go to **Info** tab
3. Expand **NSExtension → NSExtensionAttributes**
4. Verify settings:
   - **IsASCIICapable:** NO
   - **PrefersRightToLeft:** NO
   - **PrimaryLanguage:** en-US
   - **RequestsOpenAccess:** NO (change to YES if you want network access)

---

### Part 4: Delete Default Files (2 minutes)

Xcode created some files we don't need. Delete these:

**Main App:**
- Delete `ContentView.swift` (we have our own)
- Keep `ReplyCopilotApp.swift` (we'll replace contents)

**ShareExtension:**
- Delete `ShareViewController.swift` (we have our own)
- Delete `MainInterface.storyboard` (we use SwiftUI)

**KeyboardExtension:**
- Delete `KeyboardViewController.swift` (we have our own)

**To delete:**
1. Right-click file
2. Select **Delete**
3. Choose **Move to Trash** (not just remove reference)

---

### Part 5: Add Our Code Files (10 minutes)

#### 1. Create Folder Structure

In Xcode Project Navigator, create these groups (folders):

**ReplyCopilot:**
- Models (folder)
- Services (folder)
- Views (folder)

**To create folder:**
1. Right-click **ReplyCopilot** group
2. **New Group**
3. Name it

#### 2. Add Model Files

1. Right-click **Models** folder
2. **Add Files to "ReplyCopilot"...**
3. Navigate to: `C:\users\akhil\projects\ReplyCopilot\ios\ReplyCopilot\Models\`
4. Select all `.swift` files:
   - Tone.swift
   - Platform.swift
   - UserPreferences.swift
   - UsageMetrics.swift
   - APIModels.swift
   - KeychainItem.swift
   - ReplySuggestion.swift
5. **Options:**
   - ✅ Copy items if needed
   - ✅ Create groups
   - ✅ Add to targets: ReplyCopilot, ShareExtension, KeyboardExtension
6. Click **Add**

#### 3. Add Service Files

1. Right-click **Services** folder
2. **Add Files to "ReplyCopilot"...**
3. Navigate to: `C:\users\akhil\projects\ReplyCopilot\ios\ReplyCopilot\Services\`
4. Select all `.swift` files:
   - APIClient.swift
   - AuthService.swift
   - StorageService.swift
   - AnalyticsService.swift
5. **Options:**
   - ✅ Copy items if needed
   - ✅ Create groups
   - ✅ Add to targets: ReplyCopilot, ShareExtension, KeyboardExtension
6. Click **Add**

#### 4. Add View Files

1. Right-click **Views** folder
2. **Add Files to "ReplyCopilot"...**
3. Navigate to: `C:\users\akhil\projects\ReplyCopilot\ios\ReplyCopilot\Views\`
4. Select all `.swift` files:
   - OnboardingView.swift
   - ContentView.swift
   - SettingsView.swift
   - HistoryView.swift
5. **Options:**
   - ✅ Copy items if needed
   - ✅ Create groups
   - ✅ Add to targets: ReplyCopilot ONLY (views not needed in extensions)
6. Click **Add**

#### 5. Add App Entry Point

1. Right-click **ReplyCopilot** group (root)
2. **Add Files to "ReplyCopilot"...**
3. Select:
   - ReplyCopilotApp.swift
   - Config.swift
4. **Options:**
   - ✅ Copy items if needed
   - ✅ Replace existing files (for ReplyCopilotApp.swift)
   - ✅ Add to targets: ReplyCopilot, ShareExtension, KeyboardExtension
6. Click **Add**

#### 6. Add Extension Files

1. Right-click **ShareExtension** group
2. **Add Files to "ReplyCopilot"...**
3. Navigate to: `C:\users\akhil\projects\ReplyCopilot\ios\ShareExtension\`
4. Select: `ShareViewController.swift`
5. **Options:**
   - ✅ Copy items if needed
   - ✅ Add to targets: ShareExtension ONLY
6. Click **Add**

7. Right-click **KeyboardExtension** group
8. **Add Files to "ReplyCopilot"...**
9. Navigate to: `C:\users\akhil\projects\ReplyCopilot\ios\KeyboardExtension\`
10. Select: `KeyboardViewController.swift`
11. **Options:**
    - ✅ Copy items if needed
    - ✅ Add to targets: KeyboardExtension ONLY
12. Click **Add**

---

### Part 6: Add Swift Package Dependencies (5 minutes)

#### 1. Add Firebase SDK

1. **File → Add Package Dependencies...**
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Click **Add Package**
4. **Dependency Rule:** Up to Next Major Version (latest)
5. Click **Add Package**
6. Select products to add:
   - ✅ FirebaseAuth (add to: ReplyCopilot, ShareExtension)
   - ✅ FirebaseAnalytics (add to: ReplyCopilot, ShareExtension)
   - ✅ FirebaseFirestore (add to: ReplyCopilot)
7. Click **Add Package**

**Note:** Firebase packages are large. This may take a few minutes to download.

---

### Part 7: Configure Capabilities (10 minutes)

#### 1. Enable App Groups

**For ReplyCopilot target:**
1. Select **ReplyCopilot** project
2. Select **ReplyCopilot** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Select **App Groups**
6. Click **+** under App Groups
7. Enter: `group.com.replycopilot.shared`
8. Click **OK**

**For ShareExtension target:**
1. Select **ShareExtension** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Select **App Groups**
5. Click **+** under App Groups
6. Enter: `group.com.replycopilot.shared` (same as main app)
7. Click **OK**

**For KeyboardExtension target:**
1. Select **KeyboardExtension** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Select **App Groups**
5. Click **+** under App Groups
6. Enter: `group.com.replycopilot.shared` (same as main app)
7. Click **OK**

#### 2. Enable Keychain Sharing

**For all three targets** (repeat for each):
1. Select target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Select **Keychain Sharing**
5. Click **+** under Keychain Groups
6. Enter: `com.replycopilot.keychain`
7. Click **OK**

---

### Part 8: Add Firebase Configuration (5 minutes)

#### 1. Download GoogleService-Info.plist

1. Go to https://console.firebase.google.com
2. Create new project: "ReplyCopilot"
3. Add iOS app:
   - Bundle ID: `com.replycopilot.app`
4. Download `GoogleService-Info.plist`

#### 2. Add to Xcode

1. Drag `GoogleService-Info.plist` into Xcode
2. Drop it in **ReplyCopilot** group (root level)
3. **Options:**
   - ✅ Copy items if needed
   - ✅ Add to targets: ReplyCopilot, ShareExtension
4. Click **Finish**

**IMPORTANT:** Do NOT add to KeyboardExtension target (Firebase doesn't work in keyboards)

---

### Part 9: Configure Build Settings (5 minutes)

#### 1. Set iOS Deployment Target

**For all three targets:**
1. Select target
2. Go to **General** tab
3. Set **Minimum Deployments** to: **iOS 16.0**

#### 2. Set Swift Language Version

Should be automatic, but verify:
1. Select target
2. Go to **Build Settings** tab
3. Search for "swift language"
4. Verify **Swift Language Version** is: **Swift 5**

#### 3. Enable SwiftUI

Already enabled by default for new projects.

---

### Part 10: Fix Build Issues (10 minutes)

After adding all files, you'll likely see some build errors. Let's fix them:

#### 1. Build the Project

1. Select **ReplyCopilot** scheme (top left)
2. Select a simulator (e.g., iPhone 15 Pro)
3. Press **Cmd+B** to build

#### 2. Common Errors and Fixes

**Error: "Cannot find type 'UIImage' in scope"**
- **Fix:** Add `import UIKit` at top of file

**Error: "Cannot find 'FirebaseApp' in scope"**
- **Fix:** Add `import FirebaseCore` and `import FirebaseAuth`

**Error: "Value of type 'ReplySuggestion' has no member 'text'"**
- **Fix:** Make sure ReplySuggestion.swift is added to project

**Error: "Use of unresolved identifier 'Config'"**
- **Fix:** Make sure Config.swift is added to all targets

#### 3. Clean Build Folder

If you still have issues:
1. **Product → Clean Build Folder** (or Cmd+Shift+K)
2. **Product → Build** (or Cmd+B)

---

### Part 11: Update Info.plist Values (5 minutes)

#### 1. Main App Info.plist

1. Select **ReplyCopilot** target
2. Go to **Info** tab
3. Add these keys (click **+** button):

```
Key: Privacy - Camera Usage Description
Value: ReplyCopilot needs access to your camera to capture screenshots for reply generation.

Key: Privacy - Photo Library Usage Description
Value: ReplyCopilot needs access to your photos to process screenshots for reply generation.

Key: LSApplicationQueriesSchemes
Type: Array
Items:
  - whatsapp
  - instagram
  - fb-messenger
```

#### 2. Share Extension Info.plist

Should already be configured from earlier steps.

#### 3. Keyboard Extension Info.plist

Should already be configured from earlier steps.

---

### Part 12: Run the App! (5 minutes)

#### 1. Select Scheme and Device

1. Select **ReplyCopilot** scheme (top left)
2. Select a device:
   - **Simulator:** iPhone 15 Pro
   - **Real Device:** Your iPhone (recommended for extensions)

#### 2. Build and Run

1. Press **Cmd+R** (or click Play button)
2. Wait for build to complete
3. App should launch!

#### 3. Test the App

**Main App:**
1. Should show onboarding on first launch
2. Complete onboarding
3. See home screen
4. Navigate through tabs

**Share Extension:**
1. Take screenshot (use Photos app)
2. Tap screenshot thumbnail
3. Tap Share button
4. Select "ReplyCopilot"
5. Should generate replies!

**Keyboard Extension:**
1. Go to **Settings → General → Keyboard → Keyboards**
2. Tap **Add New Keyboard...**
3. Select **ReplyCopilot**
4. Open any app with text input
5. Tap globe icon to switch keyboards
6. Should see ReplyCopilot keyboard!

---

## 🐛 Troubleshooting

### Build Errors

**"No such module 'FirebaseAuth'"**
- Solution: File → Packages → Resolve Package Versions

**"Could not find module 'ReplyCopilot' for target 'ShareExtension'"**
- Solution: Make sure shared files are added to extension targets

**"Ambiguous use of 'Color'"**
- Solution: Add `import SwiftUI` at top of file

### Runtime Errors

**"App crashes on launch"**
- Solution: Check Console for error message, likely Firebase configuration issue

**"Share extension not appearing"**
- Solution: Rebuild, reinstall app, restart device

**"Keyboard not appearing in keyboard list"**
- Solution: Check keyboard target bundle ID, rebuild, reinstall

### Signing Issues

**"Failed to register bundle identifier"**
- Solution: Change bundle ID to use your domain, or use Xcode automatic signing

**"Provisioning profile doesn't include App Groups"**
- Solution: Regenerate provisioning profiles in Apple Developer portal

---

## ✅ Success Checklist

After completing all steps, verify:

- [ ] Project builds without errors
- [ ] App launches and shows onboarding
- [ ] Can navigate through tabs
- [ ] Share extension appears in share sheet
- [ ] Keyboard extension appears in keyboard list
- [ ] Firebase configured (check Firebase console)
- [ ] App Groups enabled for all targets
- [ ] Keychain sharing enabled for all targets
- [ ] All Swift files imported correctly
- [ ] No build warnings (or very few)

---

## 🎉 You're Done!

Your Xcode project is now fully configured with:

✅ Main app with 4 beautiful views
✅ Share Extension for screenshot capture
✅ Keyboard Extension for quick replies
✅ Firebase integration
✅ App Groups for data sharing
✅ Keychain for secure storage
✅ All 17 code files integrated

**Next step:** Deploy your Azure backend and Firebase, then test end-to-end!

---

## 📚 Additional Resources

**Xcode Help:**
- Help → Xcode Help
- https://developer.apple.com/documentation/xcode

**SwiftUI Tutorials:**
- https://developer.apple.com/tutorials/swiftui

**App Extensions:**
- https://developer.apple.com/app-extensions/

**Firebase iOS Setup:**
- https://firebase.google.com/docs/ios/setup

---

**Questions?** Check the troubleshooting section or search on Stack Overflow with tag [ios] [xcode] [swiftui]

**Good luck with your app! 🚀**
