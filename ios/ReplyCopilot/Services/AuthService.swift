import Foundation
import FirebaseAuth
import FirebaseCore

/**
 AuthService - Authentication Management

 LEARNING: Firebase Authentication
 ==================================
 Firebase Auth provides:
 - Email/password authentication
 - OAuth providers (Google, Apple, Microsoft)
 - Anonymous auth
 - Phone auth
 - Custom tokens
 - Session management

 LEARNING: ObservableObject
 ===========================
 SwiftUI's way of creating reactive state
 - ObservableObject protocol
 - @Published properties automatically update UI
 - Use with @StateObject or @ObservedObject
 */

@MainActor
class AuthService: ObservableObject {

    // MARK: - Singleton

    static let shared = AuthService()

    // MARK: - Published Properties

    /**
     LEARNING: @Published
     ====================
     Automatically notify SwiftUI when value changes
     Triggers view updates
     Part of Combine framework
     */

    /// Currently authenticated user
    @Published var currentUser: User?

    /// Whether user is authenticated
    @Published var isAuthenticated = false

    /// Whether authentication is in progress
    @Published var isLoading = false

    /// Last authentication error
    @Published var lastError: AuthError?

    // MARK: - Private Properties

    /// Firebase Auth instance
    private let auth: Auth

    /// Auth state listener handle
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    // MARK: - Initialization

    private init() {
        // Initialize Firebase if needed
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        self.auth = Auth.auth()

        // Set up auth state listener
        setupAuthStateListener()
    }

    // MARK: - Auth State Management

    /**
     LEARNING: Firebase Auth State Listener
     =======================================
     Automatically called when auth state changes:
     - User signs in
     - User signs out
     - Token refreshes
     - App launch (restores session)
     */

    private func setupAuthStateListener() {
        authStateHandle = auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    // User is signed in
                    self?.currentUser = self?.createUser(from: firebaseUser)
                    self?.isAuthenticated = true

                    // Save user ID to keychain for extensions
                    try? KeychainItem.sharedUserId.save(firebaseUser.uid)

                    // Get and save auth token
                    try? await self?.refreshToken()

                } else {
                    // User is signed out
                    self?.currentUser = nil
                    self?.isAuthenticated = false

                    // Clear keychain
                    try? KeychainItem.sharedUserId.delete()
                    try? KeychainItem.sharedApiToken.delete()
                }
            }
        }
    }

    // MARK: - Sign In Methods

    /**
     LEARNING: async/await Error Handling
     =====================================
     async throws functions can:
     - Suspend execution (async)
     - Return a value
     - Throw errors (throws)
     Use with try await
     */

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            print("✅ Signed in: \(result.user.uid)")

        } catch {
            let authError = AuthError.from(error)
            lastError = authError
            throw authError
        }
    }

    /// Sign up with email and password
    func signUp(email: String, password: String, displayName: String?) async throws {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            let result = try await auth.createUser(withEmail: email, password: password)

            // Update display name if provided
            if let displayName = displayName {
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try await changeRequest.commitChanges()
            }

            print("✅ Signed up: \(result.user.uid)")

            // Create initial user preferences in Firebase
            await createInitialUserData(userId: result.user.uid)

        } catch {
            let authError = AuthError.from(error)
            lastError = authError
            throw authError
        }
    }

    /// Sign in with Google
    func signInWithGoogle() async throws {
        // TODO: Implement Google Sign In
        // Requires GoogleSignIn SDK
        throw AuthError.providerNotConfigured
    }

    /// Sign in with Apple
    func signInWithApple() async throws {
        // TODO: Implement Apple Sign In
        // Requires AuthenticationServices framework
        throw AuthError.providerNotConfigured
    }

    /// Sign in anonymously
    func signInAnonymously() async throws {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            let result = try await auth.signInAnonymously()
            print("✅ Signed in anonymously: \(result.user.uid)")

        } catch {
            let authError = AuthError.from(error)
            lastError = authError
            throw authError
        }
    }

    // MARK: - Sign Out

    /// Sign out current user
    func signOut() throws {
        do {
            try auth.signOut()
            print("✅ Signed out")

        } catch {
            let authError = AuthError.from(error)
            lastError = authError
            throw authError
        }
    }

    // MARK: - Password Management

    /// Send password reset email
    func resetPassword(email: String) async throws {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            try await auth.sendPasswordReset(withEmail: email)
            print("✅ Password reset email sent")

        } catch {
            let authError = AuthError.from(error)
            lastError = authError
            throw authError
        }
    }

    /// Update password for current user
    func updatePassword(newPassword: String) async throws {
        guard let user = auth.currentUser else {
            throw AuthError.noUser
        }

        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            try await user.updatePassword(to: newPassword)
            print("✅ Password updated")

        } catch {
            let authError = AuthError.from(error)
            lastError = authError
            throw authError
        }
    }

    /// Update email for current user
    func updateEmail(newEmail: String) async throws {
        guard let user = auth.currentUser else {
            throw AuthError.noUser
        }

        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            try await user.updateEmail(to: newEmail)
            print("✅ Email updated")

        } catch {
            let authError = AuthError.from(error)
            lastError = authError
            throw authError
        }
    }

    // MARK: - Token Management

    /**
     LEARNING: ID Tokens
     ===================
     Firebase ID tokens:
     - JWT format
     - Contain user claims
     - Expire after 1 hour
     - Used for API authentication
     - Auto-refreshed by Firebase
     */

    /// Get current ID token
    func getIdToken() async throws -> String {
        guard let user = auth.currentUser else {
            throw AuthError.noUser
        }

        do {
            let token = try await user.getIDToken()
            return token

        } catch {
            throw AuthError.from(error)
        }
    }

    /// Refresh and save ID token
    func refreshToken() async throws {
        guard let user = auth.currentUser else {
            throw AuthError.noUser
        }

        do {
            // Force refresh
            let token = try await user.getIDToken(forcingRefresh: true)

            // Save to keychain for API calls
            try KeychainItem.sharedApiToken.save(token)

            print("✅ Token refreshed")

        } catch {
            throw AuthError.from(error)
        }
    }

    // MARK: - Account Management

    /// Delete current user account
    func deleteAccount() async throws {
        guard let user = auth.currentUser else {
            throw AuthError.noUser
        }

        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            // Delete user data from Firebase
            await deleteUserData(userId: user.uid)

            // Delete Firebase Auth account
            try await user.delete()

            print("✅ Account deleted")

        } catch {
            let authError = AuthError.from(error)
            lastError = authError
            throw authError
        }
    }

    /// Send email verification
    func sendEmailVerification() async throws {
        guard let user = auth.currentUser else {
            throw AuthError.noUser
        }

        do {
            try await user.sendEmailVerification()
            print("✅ Verification email sent")

        } catch {
            let authError = AuthError.from(error)
            lastError = authError
            throw authError
        }
    }

    /// Reload user data
    func reloadUser() async throws {
        guard let user = auth.currentUser else {
            throw AuthError.noUser
        }

        do {
            try await user.reload()
            currentUser = createUser(from: user)

        } catch {
            throw AuthError.from(error)
        }
    }

    // MARK: - User Data Management

    /**
     LEARNING: Firebase Integration Points
     ======================================
     After auth, we need to:
     - Create user document in Firestore
     - Initialize user preferences
     - Set up analytics
     - Track registration event
     */

    /// Create initial user data after signup
    private func createInitialUserData(userId: String) async {
        // TODO: Create Firestore document
        // /users/{userId}/preferences
        // Will be implemented when we add Firestore service

        print("📝 Creating initial user data for: \(userId)")
    }

    /// Delete user data before account deletion
    private func deleteUserData(userId: String) async {
        // TODO: Delete all user data
        // - Firestore documents
        // - Storage files
        // - Analytics data

        print("🗑️ Deleting user data for: \(userId)")
    }

    // MARK: - Helper Methods

    /// Convert Firebase User to our User model
    private func createUser(from firebaseUser: FirebaseAuth.User) -> User {
        User(
            id: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL,
            isEmailVerified: firebaseUser.isEmailVerified,
            createdAt: firebaseUser.metadata.creationDate ?? Date()
        )
    }

    // MARK: - Cleanup

    deinit {
        // Remove auth state listener
        if let handle = authStateHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }
}

// MARK: - User Model

/**
 LEARNING: User Model
 ====================
 Simplified user model for our app
 Maps from Firebase User
 */

struct User: Identifiable, Codable, Equatable {
    let id: String
    let email: String?
    let displayName: String?
    let photoURL: URL?
    let isEmailVerified: Bool
    let createdAt: Date

    var initials: String {
        guard let name = displayName else {
            return email?.prefix(1).uppercased() ?? "?"
        }

        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.prefix(1) ?? ""
        let lastInitial = components.count > 1 ? components.last?.prefix(1) ?? "" : ""
        return (firstInitial + lastInitial).uppercased()
    }
}

// MARK: - Auth Error

/**
 LEARNING: Error Mapping
 =======================
 Convert Firebase errors to our custom errors
 Provides user-friendly messages
 */

enum AuthError: Error, LocalizedError {
    case noUser
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case wrongPassword
    case userNotFound
    case networkError
    case tooManyRequests
    case providerNotConfigured
    case accountExistsWithDifferentCredential
    case requiresRecentLogin
    case unknown(message: String)

    var errorDescription: String? {
        switch self {
        case .noUser:
            return "No User Signed In"
        case .invalidEmail:
            return "Invalid Email"
        case .weakPassword:
            return "Weak Password"
        case .emailAlreadyInUse:
            return "Email Already in Use"
        case .wrongPassword:
            return "Wrong Password"
        case .userNotFound:
            return "User Not Found"
        case .networkError:
            return "Network Error"
        case .tooManyRequests:
            return "Too Many Requests"
        case .providerNotConfigured:
            return "Provider Not Configured"
        case .accountExistsWithDifferentCredential:
            return "Account Exists"
        case .requiresRecentLogin:
            return "Requires Recent Login"
        case .unknown(let message):
            return message
        }
    }

    var failureReason: String? {
        switch self {
        case .noUser:
            return "No user is currently signed in"
        case .invalidEmail:
            return "The email address is not valid"
        case .weakPassword:
            return "Password must be at least 6 characters"
        case .emailAlreadyInUse:
            return "An account already exists with this email"
        case .wrongPassword:
            return "The password is incorrect"
        case .userNotFound:
            return "No account exists with this email"
        case .networkError:
            return "Please check your internet connection"
        case .tooManyRequests:
            return "Too many failed attempts. Try again later."
        case .providerNotConfigured:
            return "This sign-in method is not configured"
        case .accountExistsWithDifferentCredential:
            return "An account exists with a different sign-in method"
        case .requiresRecentLogin:
            return "This action requires recent authentication"
        case .unknown(let message):
            return message
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noUser:
            return "Please sign in first"
        case .invalidEmail:
            return "Enter a valid email address"
        case .weakPassword:
            return "Use a stronger password with at least 6 characters"
        case .emailAlreadyInUse:
            return "Try signing in instead, or use password reset"
        case .wrongPassword:
            return "Check your password or use 'Forgot Password'"
        case .userNotFound:
            return "Try creating a new account"
        case .networkError:
            return "Check your connection and try again"
        case .tooManyRequests:
            return "Wait a few minutes and try again"
        case .providerNotConfigured:
            return "Contact support"
        case .accountExistsWithDifferentCredential:
            return "Try signing in with your original method"
        case .requiresRecentLogin:
            return "Sign out and sign in again, then try this action"
        case .unknown:
            return "Please try again"
        }
    }

    /// Convert Firebase error to AuthError
    static func from(_ error: Error) -> AuthError {
        let nsError = error as NSError

        // Firebase error codes
        guard let errorCode = AuthErrorCode.Code(rawValue: nsError.code) else {
            return .unknown(message: error.localizedDescription)
        }

        switch errorCode {
        case .invalidEmail:
            return .invalidEmail
        case .weakPassword:
            return .weakPassword
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .wrongPassword:
            return .wrongPassword
        case .userNotFound:
            return .userNotFound
        case .networkError:
            return .networkError
        case .tooManyRequests:
            return .tooManyRequests
        case .accountExistsWithDifferentCredential:
            return .accountExistsWithDifferentCredential
        case .requiresRecentLogin:
            return .requiresRecentLogin
        default:
            return .unknown(message: error.localizedDescription)
        }
    }
}

/**
 KEY CONCEPTS LEARNED:
 =====================

 1. Firebase Authentication
    - Email/password auth
    - OAuth providers (Google, Apple)
    - Anonymous auth
    - Session management
    - Token handling

 2. ObservableObject
    - SwiftUI reactive state
    - @Published auto-updates UI
    - Use with @StateObject/@ObservedObject

 3. Auth State Listener
    - Automatically tracks sign in/out
    - Persists across app launches
    - Updates UI reactively

 4. ID Tokens
    - JWT format
    - Used for API authentication
    - Auto-refresh every hour
    - Store in keychain

 5. Error Handling
    - Convert Firebase errors
    - User-friendly messages
    - Recovery suggestions

 6. Account Management
    - Update email/password
    - Email verification
    - Account deletion
    - Password reset

 USAGE EXAMPLE:
 ==============
 ```swift
 // Get shared instance
 let auth = AuthService.shared

 // Sign up
 Task {
     do {
         try await auth.signUp(
             email: "user@example.com",
             password: "password123",
             displayName: "John Doe"
         )
         print("Signed up!")
     } catch let error as AuthError {
         print(error.localizedDescription)
     }
 }

 // Sign in
 Task {
     do {
         try await auth.signIn(
             email: "user@example.com",
             password: "password123"
         )
         print("Signed in!")
     } catch {
         print("Sign in failed")
     }
 }

 // Sign out
 do {
     try auth.signOut()
 } catch {
     print("Sign out failed")
 }

 // Get token for API
 Task {
     let token = try await auth.getIdToken()
     // Use in API calls
 }

 // Delete account
 Task {
     try await auth.deleteAccount()
 }
 ```

 SWIFTUI INTEGRATION:
 ===================
 ```swift
 struct ContentView: View {
     @StateObject private var auth = AuthService.shared

     var body: some View {
         if auth.isAuthenticated {
             HomeView()
                 .environmentObject(auth)
         } else {
             LoginView()
                 .environmentObject(auth)
         }
     }
 }

 struct LoginView: View {
     @EnvironmentObject var auth: AuthService
     @State private var email = ""
     @State private var password = ""

     var body: some View {
         VStack {
             TextField("Email", text: $email)
             SecureField("Password", text: $password)

             Button("Sign In") {
                 Task {
                     try? await auth.signIn(email: email, password: password)
                 }
             }
             .disabled(auth.isLoading)

             if auth.isLoading {
                 ProgressView()
             }

             if let error = auth.lastError {
                 Text(error.localizedDescription)
                     .foregroundColor(.red)
             }
         }
     }
 }
 ```

 NEXT STEPS:
 ===========
 - Add Google Sign In SDK
 - Add Apple Sign In
 - Create login/signup views
 - Integrate with Firestore
 - Add analytics tracking
 - Implement biometric auth
 */
