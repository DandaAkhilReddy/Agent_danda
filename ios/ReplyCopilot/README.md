# ReplyCopilot iOS App

Complete, production-ready iOS app with educational comments throughout.

## 📱 What You're Building

A professional iOS app that demonstrates:
- ✅ SwiftUI for modern UI
- ✅ MVVM architecture pattern
- ✅ App Extensions (Share + Keyboard)
- ✅ Networking with async/await
- ✅ Keychain for secure storage
- ✅ App Groups for data sharing
- ✅ Firebase integration
- ✅ Azure AD authentication

## 🏗️ Architecture

```
ReplyCopilot/
├── App/                          # App entry point
│   ├── ReplyCopilotApp.swift    # Main app lifecycle
│   └── AppDelegate.swift        # App delegate (Firebase setup)
│
├── Views/                        # SwiftUI views
│   ├── Onboarding/
│   │   └── OnboardingView.swift
│   ├── Main/
│   │   ├── ContentView.swift
│   │   ├── SettingsView.swift
│   │   └── HistoryView.swift
│   └── Components/
│       ├── TonePickerView.swift
│       └── SuggestionCard.swift
│
├── ViewModels/                   # MVVM ViewModels
│   ├── OnboardingViewModel.swift
│   ├── SettingsViewModel.swift
│   └── HistoryViewModel.swift
│
├── Models/                       # Data models
│   ├── ReplySuggestion.swift
│   ├── UserPreferences.swift
│   └── Platform.swift
│
├── Services/                     # Business logic
│   ├── APIClient.swift          # Azure backend API
│   ├── AuthService.swift        # Firebase + Azure AD
│   ├── StorageService.swift     # App Groups + Keychain
│   └── AnalyticsService.swift   # Firebase Analytics
│
├── Extensions/                   # Swift extensions
│   ├── View+Extensions.swift
│   ├── Color+Theme.swift
│   └── String+Extensions.swift
│
├── Utilities/                    # Helper utilities
│   ├── Constants.swift
│   ├── Logger.swift
│   └── NetworkMonitor.swift
│
└── Resources/                    # Assets & config
    ├── Assets.xcassets
    ├── GoogleService-Info.plist
    └── Info.plist

ShareExtension/                   # Share Extension target
├── ShareViewController.swift
├── ShareView.swift
└── Info.plist

KeyboardExtension/                # Keyboard Extension target
├── KeyboardViewController.swift
├── KeyboardView.swift
└── Info.plist

Shared/                           # Shared between targets
├── Models/
├── Config.swift
└── SharedConstants.swift
```

## 🎓 Learning Path

Each file includes detailed comments explaining:
1. **Why** - Why this code exists
2. **How** - How it works
3. **iOS Concepts** - iOS-specific patterns and best practices
4. **Swift Features** - Modern Swift syntax and features

## 🚀 Getting Started

### Prerequisites
- macOS 13+ (Ventura or later)
- Xcode 15+
- Apple Developer account (for device testing)

### Setup Steps

1. **Install Xcode**
   ```bash
   # Download from Mac App Store or:
   # https://developer.apple.com/xcode/
   ```

2. **Open Project**
   ```bash
   cd ios/ReplyCopilot
   open ReplyCopilot.xcodeproj
   # Or double-click ReplyCopilot.xcodeproj in Finder
   ```

3. **Install Dependencies**
   - Xcode will auto-download Swift Package Manager dependencies
   - Wait for "Dependencies Resolved" notification

4. **Configure Firebase**
   - Download `GoogleService-Info.plist` from Firebase Console
   - Drag into Xcode project (Resources folder)

5. **Configure Azure**
   - Edit `Config.swift`
   - Add your Azure OpenAI endpoint and credentials

6. **Configure Bundle IDs**
   - Select project in Xcode
   - Change Bundle Identifier to your own:
     - Main app: `com.yourname.replycopilot`
     - Share: `com.yourname.replycopilot.share`
     - Keyboard: `com.yourname.replycopilot.keyboard`

7. **Configure App Groups**
   - Select each target → Signing & Capabilities
   - Add "App Groups" capability
   - Create: `group.com.yourname.replycopilot`

8. **Build & Run**
   - Select "ReplyCopilot" scheme
   - Choose simulator or device
   - Press ⌘R to run

## 📚 Key Concepts You'll Learn

### 1. SwiftUI Basics
- Declarative UI syntax
- State management (@State, @ObservedObject, @EnvironmentObject)
- View composition and modifiers
- Navigation and sheets

### 2. MVVM Architecture
- Separation of concerns
- ViewModels for business logic
- ObservableObject and @Published
- Dependency injection

### 3. Networking
- URLSession and async/await
- Codable for JSON parsing
- Error handling
- Background tasks

### 4. Data Persistence
- UserDefaults for simple data
- Keychain for secure storage
- App Groups for sharing between extensions
- Firebase Firestore

### 5. App Extensions
- Share Extension (receiving screenshots)
- Keyboard Extension (inserting text)
- Extension lifecycle and limitations
- Communication with main app

### 6. Security
- Keychain for tokens
- Certificate pinning
- Secure network requests
- Privacy best practices

### 7. iOS APIs
- Photos framework (optional photo access)
- UIKit integration with SwiftUI
- Background processing
- Push notifications (future)

## 🔧 Build Configurations

### Debug
- Local Azure endpoint
- Verbose logging
- Mock data for testing
- No analytics

### Release
- Production Azure endpoint
- Error logging only
- Real backend calls
- Full analytics

## 🧪 Testing

### Unit Tests
```bash
# Press ⌘U in Xcode
# Or: xcodebuild test -scheme ReplyCopilot
```

### UI Tests
```bash
# Long press ⌘U in Xcode
# Select "Test Plan" → UI Tests
```

### Manual Testing Checklist
- [ ] Onboarding flow
- [ ] Share screenshot → Get suggestions
- [ ] Keyboard shows suggestions
- [ ] Settings save correctly
- [ ] Firebase auth works
- [ ] Azure API responds

## 📝 Code Style

This project follows:
- **Swift API Design Guidelines**
- **SwiftLint** rules (when configured)
- **SOLID principles**
- **Clean Architecture**

### Naming Conventions
- Types: `PascalCase` (e.g., `UserPreferences`)
- Variables/Functions: `camelCase` (e.g., `fetchSuggestions()`)
- Constants: `camelCase` with `k` prefix (e.g., `kMaxSuggestions`)
- Private properties: `_` prefix (e.g., `_apiClient`)

### Comments
```swift
// MARK: - Section Name       <- Section divider
// TODO: Future improvement   <- Tasks to do
// FIXME: Known issue         <- Bugs to fix
// NOTE: Important info       <- Important notes

/// Brief description         <- Documentation
/// - Parameter name: desc    <- Parameter docs
/// - Returns: description    <- Return value docs
```

## 🐛 Debugging Tips

### Common Issues

1. **Build Failed - Missing GoogleService-Info.plist**
   - Download from Firebase Console
   - Add to Xcode project (copy to project directory)

2. **Share Extension Not Showing**
   - Build and run on device (not simulator)
   - Check Photos app → Share button

3. **Keyboard Not Available**
   - Settings → General → Keyboard → Keyboards
   - Add New Keyboard → ReplyCopilot

4. **Network Requests Failing**
   - Check Info.plist → App Transport Security
   - Verify Azure endpoint is correct
   - Check internet connection

### Xcode Shortcuts
- ⌘R: Build & Run
- ⌘.: Stop
- ⌘B: Build
- ⌘U: Run Tests
- ⌘K: Clear Console
- ⌘/: Toggle Comment
- ⌘⌥/: Add Documentation Comment

## 📦 Dependencies

### Swift Package Manager
- Firebase iOS SDK (Auth, Firestore, Analytics)
- MSAL (Microsoft Authentication Library)

### Why These?
- **Firebase**: User management, database, analytics
- **MSAL**: Azure AD authentication

## 🚀 Deployment

### TestFlight
1. Archive: Product → Archive
2. Distribute App → TestFlight
3. Upload → Wait for processing
4. Add testers → Send invites

### App Store
1. Create app in App Store Connect
2. Fill metadata (description, screenshots, etc.)
3. Upload build via Xcode
4. Submit for review
5. Wait 1-3 days for approval

## 📈 Performance

### Optimization Tips
- Lazy loading for images
- Debounce user input
- Cache API responses
- Background processing for heavy tasks
- Instrument with Xcode Profiler

## 🔐 Security Checklist

- [x] No hardcoded API keys
- [x] Keychain for sensitive data
- [x] HTTPS only (no HTTP)
- [x] Certificate pinning
- [x] Input validation
- [x] Error messages don't leak info
- [x] App Transport Security configured

## 🎨 Design System

### Colors
- Primary: Blue (#007AFF)
- Success: Green (#34C759)
- Warning: Orange (#FF9500)
- Error: Red (#FF3B30)
- Background: System background
- Text: Label colors (adapts to dark mode)

### Typography
- Title: SF Pro Display, 34pt, Bold
- Headline: SF Pro Display, 28pt, Semibold
- Body: SF Pro Text, 17pt, Regular
- Caption: SF Pro Text, 12pt, Regular

### Spacing
- XXS: 4pt
- XS: 8pt
- S: 12pt
- M: 16pt
- L: 24pt
- XL: 32pt
- XXL: 48pt

## 📱 Platform Support

- iOS 16.0+
- iPhone only (iPad support in future)
- Portrait orientation
- Light & Dark mode
- Accessibility support (VoiceOver, Dynamic Type)

## 🌍 Localization

Ready for localization:
- All strings in `Localizable.strings`
- Right-to-left layout support
- Date/number formatting

## 🆘 Support

### Resources
- Apple Developer Documentation
- Swift.org
- SwiftUI by Example (hackingwithswift.com)
- Stack Overflow

### Getting Help
- Read inline comments in code
- Check Xcode documentation (⌥ + Click)
- Debug with breakpoints (Click line number)
- Use print() statements for logging

---

**Ready to learn iOS development!** 🎓

Every file has detailed comments explaining iOS concepts. Start with `ReplyCopilotApp.swift` and follow the imports!
