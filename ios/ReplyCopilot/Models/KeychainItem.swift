import Foundation
import Security

/**
 KeychainItem - Secure Storage Wrapper

 LEARNING: iOS Keychain
 ======================
 The Keychain is iOS's secure storage system for:
 - Passwords
 - API tokens
 - Authentication credentials
 - Encryption keys
 - Sensitive user data

 WHY use Keychain?
 - Hardware-encrypted
 - Survives app deletion (optionally)
 - Syncs across devices (optionally)
 - Protected by device passcode
 - Not accessible to other apps

 WHY NOT UserDefaults?
 - UserDefaults is NOT secure
 - Data stored in plain text
 - Easy to read with jailbreak
 - NEVER store sensitive data there!
 */

struct KeychainItem {

    // MARK: - Properties

    /**
     LEARNING: Keychain Attributes
     ==============================
     service: Group related items (usually bundle ID)
     account: Unique identifier for item (e.g., "apiToken")
     accessGroup: Share between apps (for extensions)
     */

    /// Service identifier (typically bundle ID)
    let service: String

    /// Account name (key for the item)
    let account: String

    /// Access group for app extensions
    let accessGroup: String?

    // MARK: - Initialization

    init(service: String, account: String, accessGroup: String? = nil) {
        self.service = service
        self.account = account
        self.accessGroup = accessGroup
    }

    // MARK: - CRUD Operations

    /**
     LEARNING: Keychain CRUD
     =======================
     Create/Update: SecItemAdd or SecItemUpdate
     Read: SecItemCopyMatching
     Delete: SecItemDelete

     All operations use dictionaries (CFDictionary)
     Status codes indicate success/failure
     */

    /// Save data to keychain
    func save(_ data: Data) throws {
        // Build query dictionary
        var query = baseQuery
        query[kSecValueData as String] = data

        // Try to delete existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.from(status)
        }
    }

    /// Save string to keychain
    func save(_ string: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.encodingError
        }
        try save(data)
    }

    /// Read data from keychain
    func read() throws -> Data {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            throw KeychainError.from(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.unexpectedData
        }

        return data
    }

    /// Read string from keychain
    func readString() throws -> String {
        let data = try read()
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingError
        }
        return string
    }

    /// Delete item from keychain
    func delete() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.from(status)
        }
    }

    /// Check if item exists in keychain
    func exists() -> Bool {
        var query = baseQuery
        query[kSecReturnData as String] = false
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Query Building

    /**
     LEARNING: Keychain Query Dictionary
     ====================================
     kSecClass: Type of item (generic password, internet password, etc.)
     kSecAttrService: Service identifier
     kSecAttrAccount: Account name
     kSecAttrAccessGroup: Share with extensions
     kSecAttrAccessible: When item is accessible
     */

    private var baseQuery: [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        // Add access group if specified (for app extensions)
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        // Set accessibility (when item can be accessed)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        return query
    }
}

// MARK: - Keychain Error

/**
 LEARNING: Keychain Status Codes
 ================================
 Keychain operations return OSStatus codes
 Map them to user-friendly errors
 */

enum KeychainError: Error, LocalizedError {
    case itemNotFound
    case duplicateItem
    case invalidData
    case unexpectedData
    case encodingError
    case decodingError
    case unhandledError(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Item not found in keychain"
        case .duplicateItem:
            return "Item already exists in keychain"
        case .invalidData:
            return "Invalid data format"
        case .unexpectedData:
            return "Unexpected data returned from keychain"
        case .encodingError:
            return "Failed to encode data"
        case .decodingError:
            return "Failed to decode data"
        case .unhandledError(let status):
            return "Keychain error: \(status)"
        }
    }

    /// Create error from OSStatus
    static func from(_ status: OSStatus) -> KeychainError {
        switch status {
        case errSecItemNotFound:
            return .itemNotFound
        case errSecDuplicateItem:
            return .duplicateItem
        case errSecInvalidData:
            return .invalidData
        default:
            return .unhandledError(status: status)
        }
    }
}

// MARK: - Convenience Methods

extension KeychainItem {

    /**
     LEARNING: Common Keychain Operations
     ====================================
     Provide convenience methods for common tasks
     Hide complexity from callers
     */

    /// Save Codable object to keychain
    func save<T: Encodable>(_ object: T) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        try save(data)
    }

    /// Read Codable object from keychain
    func read<T: Decodable>() throws -> T {
        let data = try read()
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    /// Update existing item (alias for save)
    func update(_ data: Data) throws {
        try save(data)
    }

    /// Update string (alias for save)
    func update(_ string: String) throws {
        try save(string)
    }
}

// MARK: - Static Factory Methods

extension KeychainItem {

    /**
     LEARNING: Factory Methods
     =========================
     Provide pre-configured instances for common use cases
     Ensures consistent naming/configuration
     */

    /// Keychain item for API access token
    static func apiToken(accessGroup: String? = nil) -> KeychainItem {
        KeychainItem(
            service: Config.bundleIdentifier,
            account: "apiToken",
            accessGroup: accessGroup
        )
    }

    /// Keychain item for Firebase auth token
    static func firebaseToken(accessGroup: String? = nil) -> KeychainItem {
        KeychainItem(
            service: Config.bundleIdentifier,
            account: "firebaseToken",
            accessGroup: accessGroup
        )
    }

    /// Keychain item for user ID
    static func userId(accessGroup: String? = nil) -> KeychainItem {
        KeychainItem(
            service: Config.bundleIdentifier,
            account: "userId",
            accessGroup: accessGroup
        )
    }

    /// Keychain item for Azure OpenAI key (if stored locally)
    static func azureKey(accessGroup: String? = nil) -> KeychainItem {
        KeychainItem(
            service: Config.bundleIdentifier,
            account: "azureKey",
            accessGroup: accessGroup
        )
    }

    /// Keychain item for encryption key
    static func encryptionKey(accessGroup: String? = nil) -> KeychainItem {
        KeychainItem(
            service: Config.bundleIdentifier,
            account: "encryptionKey",
            accessGroup: accessGroup
        )
    }
}

// MARK: - App Group Support

extension KeychainItem {

    /**
     LEARNING: App Groups for Extensions
     ====================================
     Share keychain items between:
     - Main app
     - Share extension
     - Keyboard extension

     Use the same access group for all targets
     */

    /// Create keychain item with app group access
    static func shared(account: String) -> KeychainItem {
        KeychainItem(
            service: Config.bundleIdentifier,
            account: account,
            accessGroup: Config.appGroupIdentifier
        )
    }

    /// Shared API token (accessible from extensions)
    static var sharedApiToken: KeychainItem {
        shared(account: "apiToken")
    }

    /// Shared user ID (accessible from extensions)
    static var sharedUserId: KeychainItem {
        shared(account: "userId")
    }
}

/**
 KEY CONCEPTS LEARNED:
 =====================

 1. Keychain Security
    - Hardware-encrypted storage
    - Protected by device passcode
    - Survives app deletion (optional)
    - Not accessible to other apps

 2. Keychain Architecture
    - CFDictionary-based API (C API)
    - OSStatus return codes
    - Query dictionaries for operations
    - Attributes for configuration

 3. Data Protection
    - kSecAttrAccessibleAfterFirstUnlock
    - Device must be unlocked once after boot
    - Good balance of security and usability

 4. App Groups
    - Share data between app and extensions
    - Use kSecAttrAccessGroup
    - Configure in Xcode capabilities

 5. Error Handling
    - Map OSStatus to Swift errors
    - Provide user-friendly messages
    - Handle common cases (not found, duplicate)

 6. Type Safety
    - Generic methods for Codable
    - String convenience methods
    - Factory methods for common items

 SECURITY BEST PRACTICES:
 ========================
 ✅ Use Keychain for sensitive data
 ✅ Use access groups for extensions
 ✅ Use kSecAttrAccessibleAfterFirstUnlock
 ✅ Delete items when no longer needed
 ❌ Don't store sensitive data in UserDefaults
 ❌ Don't hardcode credentials in code
 ❌ Don't log keychain contents

 USAGE EXAMPLE:
 ==============
 ```swift
 // Save API token
 do {
     let token = KeychainItem.apiToken()
     try token.save("abc123xyz")
     print("Token saved securely")
 } catch {
     print("Failed to save token: \\(error)")
 }

 // Read API token
 do {
     let token = KeychainItem.apiToken()
     let value = try token.readString()
     print("Token: \\(value)")
 } catch {
     print("Token not found")
 }

 // Save Codable object
 do {
     let prefs = UserPreferences(userId: "user123")
     let item = KeychainItem(service: Bundle.main.bundleIdentifier!,
                             account: "preferences")
     try item.save(prefs)
 } catch {
     print("Failed to save: \\(error)")
 }

 // Read Codable object
 do {
     let item = KeychainItem(service: Bundle.main.bundleIdentifier!,
                             account: "preferences")
     let prefs: UserPreferences = try item.read()
     print("Loaded preferences")
 } catch {
     print("Failed to load: \\(error)")
 }

 // Delete token
 do {
     let token = KeychainItem.apiToken()
     try token.delete()
     print("Token deleted")
 } catch {
     print("Failed to delete: \\(error)")
 }

 // Check if exists
 let token = KeychainItem.apiToken()
 if token.exists() {
     print("Token exists")
 }

 // Shared between app and extensions
 let sharedToken = KeychainItem.sharedApiToken
 try sharedToken.save("token-accessible-from-extensions")
 ```

 TESTING:
 ========
 ```swift
 // Test save/read
 func testKeychainSaveRead() throws {
     let item = KeychainItem(service: "test", account: "testAccount")
     try item.save("testValue")
     let value = try item.readString()
     XCTAssertEqual(value, "testValue")
     try item.delete()
 }

 // Test Codable
 func testKeychainCodable() throws {
     let item = KeychainItem(service: "test", account: "testPrefs")
     let original = UserPreferences(userId: "test123")
     try item.save(original)
     let loaded: UserPreferences = try item.read()
     XCTAssertEqual(loaded, original)
     try item.delete()
 }
 ```

 NEXT STEPS:
 ===========
 - Use in AuthService for token storage
 - Use in StorageService wrapper
 - Configure App Groups in Xcode
 - Test with extensions
 - Add biometric authentication (Face ID/Touch ID)
 */
