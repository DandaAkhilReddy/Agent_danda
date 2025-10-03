import Foundation

/**
 API Models - Network Communication Types

 LEARNING: API Communication
 ============================
 These models handle:
 - Request/Response structure
 - Error handling
 - Type-safe networking
 - JSON serialization

 WHY separate file?
 - Keep networking logic together
 - Reusable across services
 - Clear API contract
 */

// MARK: - API Request

/**
 Request to generate replies from screenshot
 */
struct GenerateRepliesRequest: Codable {

    /**
     LEARNING: Codable Property Names
     ================================
     Swift properties use camelCase
     JSON often uses snake_case
     CodingKeys maps between them
     */

    /// Base64-encoded screenshot image
    let imageData: String

    /// Messaging platform detected
    let platform: Platform

    /// Desired reply tone
    let tone: Tone

    /// User ID for analytics (optional)
    let userId: String?

    /// Additional metadata
    let metadata: RequestMetadata?

    /// Coding keys for JSON conversion
    private enum CodingKeys: String, CodingKey {
        case imageData = "image_data"
        case platform
        case tone
        case userId = "user_id"
        case metadata
    }
}

/**
 Request metadata
 */
struct RequestMetadata: Codable {
    /// App version
    let appVersion: String

    /// iOS version
    let iosVersion: String

    /// Device model
    let deviceModel: String

    /// Request timestamp
    let timestamp: Date

    /// User's timezone
    let timezone: String

    private enum CodingKeys: String, CodingKey {
        case appVersion = "app_version"
        case iosVersion = "ios_version"
        case deviceModel = "device_model"
        case timestamp
        case timezone
    }
}

// MARK: - API Response

/**
 Response from reply generation endpoint
 */
struct GenerateRepliesResponse: Codable {

    /// Generated reply suggestions
    let suggestions: [ReplySuggestion]

    /// Processing time (seconds)
    let processingTime: Double

    /// Request ID for tracking
    let requestId: String

    /// Confidence score (0.0-1.0)
    let confidence: Double?

    /// API version
    let apiVersion: String

    /// Coding keys for JSON conversion
    private enum CodingKeys: String, CodingKey {
        case suggestions
        case processingTime = "processing_time"
        case requestId = "request_id"
        case confidence
        case apiVersion = "api_version"
    }
}

/**
 Response for subscription status
 */
struct SubscriptionStatusResponse: Codable {
    let userId: String
    let tier: SubscriptionTier
    let expiresAt: Date?
    let autoRenew: Bool
    let usageToday: Int
    let usageLimit: Int?

    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case tier
        case expiresAt = "expires_at"
        case autoRenew = "auto_renew"
        case usageToday = "usage_today"
        case usageLimit = "usage_limit"
    }
}

// MARK: - API Error

/**
 LEARNING: Error Handling
 ========================
 Custom errors provide:
 - Clear error messages
 - Localized descriptions
 - Recovery suggestions
 - Error categorization

 LocalizedError: Built-in protocol for user-facing errors
 */

enum APIError: Error, LocalizedError, Equatable {

    // MARK: - Error Cases

    /// Network connection failed
    case networkError(underlying: String)

    /// Request timeout
    case timeout

    /// Invalid request data
    case invalidRequest(reason: String)

    /// Authentication failed
    case unauthorized

    /// Rate limit exceeded
    case rateLimitExceeded(retryAfter: TimeInterval?)

    /// Subscription required
    case subscriptionRequired

    /// Server error (5xx)
    case serverError(statusCode: Int)

    /// Invalid response format
    case invalidResponse

    /// Failed to decode JSON
    case decodingError(underlying: String)

    /// Failed to encode JSON
    case encodingError(underlying: String)

    /// Image too large
    case imageTooLarge(maxSize: Int)

    /// Unsupported platform
    case unsupportedPlatform

    /// No suggestions generated
    case noSuggestionsGenerated

    /// Unknown error
    case unknown(message: String)

    // MARK: - LocalizedError Implementation

    /**
     LEARNING: User-Facing Error Messages
     =====================================
     errorDescription: Main error message
     failureReason: Why it happened
     recoverySuggestion: What user can do
     */

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network Connection Failed"
        case .timeout:
            return "Request Timed Out"
        case .invalidRequest:
            return "Invalid Request"
        case .unauthorized:
            return "Authentication Required"
        case .rateLimitExceeded:
            return "Rate Limit Exceeded"
        case .subscriptionRequired:
            return "Subscription Required"
        case .serverError(let code):
            return "Server Error (\(code))"
        case .invalidResponse:
            return "Invalid Server Response"
        case .decodingError:
            return "Failed to Parse Response"
        case .encodingError:
            return "Failed to Create Request"
        case .imageTooLarge:
            return "Image Too Large"
        case .unsupportedPlatform:
            return "Platform Not Supported"
        case .noSuggestionsGenerated:
            return "No Suggestions Generated"
        case .unknown:
            return "Unknown Error"
        }
    }

    var failureReason: String? {
        switch self {
        case .networkError(let underlying):
            return "Network connection failed: \(underlying)"
        case .timeout:
            return "The server took too long to respond"
        case .invalidRequest(let reason):
            return reason
        case .unauthorized:
            return "Your session has expired or is invalid"
        case .rateLimitExceeded(let retryAfter):
            if let seconds = retryAfter {
                return "You've made too many requests. Try again in \(Int(seconds)) seconds."
            }
            return "You've made too many requests. Please try again later."
        case .subscriptionRequired:
            return "You've reached your daily limit. Upgrade to Pro for unlimited replies."
        case .serverError(let code):
            return "The server encountered an error (HTTP \(code))"
        case .invalidResponse:
            return "The server returned an unexpected response"
        case .decodingError(let underlying):
            return "Failed to parse server response: \(underlying)"
        case .encodingError(let underlying):
            return "Failed to encode request: \(underlying)"
        case .imageTooLarge(let maxSize):
            return "Image size exceeds maximum allowed size of \(maxSize / 1024 / 1024)MB"
        case .unsupportedPlatform:
            return "This messaging platform is not yet supported"
        case .noSuggestionsGenerated:
            return "AI could not generate suggestions for this screenshot"
        case .unknown(let message):
            return message
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkError, .timeout:
            return "Check your internet connection and try again"
        case .invalidRequest:
            return "Please try a different screenshot"
        case .unauthorized:
            return "Please sign in again"
        case .rateLimitExceeded:
            return "Wait a moment and try again"
        case .subscriptionRequired:
            return "Upgrade to Pro in Settings for unlimited access"
        case .serverError:
            return "Our team has been notified. Please try again later."
        case .invalidResponse, .decodingError:
            return "Please update to the latest version of the app"
        case .encodingError:
            return "Please restart the app and try again"
        case .imageTooLarge:
            return "Try taking a new screenshot with less content"
        case .unsupportedPlatform:
            return "Check back soon - we're adding new platforms regularly"
        case .noSuggestionsGenerated:
            return "Try a screenshot with more visible conversation text"
        case .unknown:
            return "Please try again or contact support"
        }
    }

    // MARK: - Error Properties

    /// Whether error is recoverable by user action
    var isRecoverable: Bool {
        switch self {
        case .networkError, .timeout, .invalidRequest, .imageTooLarge:
            return true
        case .unauthorized, .rateLimitExceeded, .subscriptionRequired:
            return true
        case .serverError, .invalidResponse, .decodingError, .encodingError:
            return false
        case .unsupportedPlatform, .noSuggestionsGenerated:
            return false
        case .unknown:
            return false
        }
    }

    /// Whether error should be reported to analytics
    var shouldReport: Bool {
        switch self {
        case .networkError, .timeout, .invalidRequest:
            return false // User errors, don't report
        case .unauthorized, .rateLimitExceeded, .subscriptionRequired:
            return false // Expected errors
        case .serverError, .invalidResponse, .decodingError, .encodingError:
            return true // System errors, report
        case .imageTooLarge, .unsupportedPlatform, .noSuggestionsGenerated:
            return false // Expected errors
        case .unknown:
            return true // Unknown errors, report
        }
    }

    /// HTTP status code (if applicable)
    var statusCode: Int? {
        switch self {
        case .unauthorized:
            return 401
        case .rateLimitExceeded:
            return 429
        case .subscriptionRequired:
            return 402
        case .serverError(let code):
            return code
        default:
            return nil
        }
    }

    // MARK: - Equatable

    /**
     LEARNING: Equatable for Enums with Associated Values
     ====================================================
     Need custom implementation when cases have associated values
     */

    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.networkError(let a), .networkError(let b)):
            return a == b
        case (.timeout, .timeout):
            return true
        case (.invalidRequest(let a), .invalidRequest(let b)):
            return a == b
        case (.unauthorized, .unauthorized):
            return true
        case (.rateLimitExceeded(let a), .rateLimitExceeded(let b)):
            return a == b
        case (.subscriptionRequired, .subscriptionRequired):
            return true
        case (.serverError(let a), .serverError(let b)):
            return a == b
        case (.invalidResponse, .invalidResponse):
            return true
        case (.decodingError(let a), .decodingError(let b)):
            return a == b
        case (.encodingError(let a), .encodingError(let b)):
            return a == b
        case (.imageTooLarge(let a), .imageTooLarge(let b)):
            return a == b
        case (.unsupportedPlatform, .unsupportedPlatform):
            return true
        case (.noSuggestionsGenerated, .noSuggestionsGenerated):
            return true
        case (.unknown(let a), .unknown(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Error Conversion

extension APIError {
    /**
     LEARNING: Error Conversion
     ==========================
     Convert system errors to our custom errors
     Provides consistent error handling
     */

    /// Create APIError from URLError
    static func from(_ error: URLError) -> APIError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkError(underlying: "No internet connection")
        case .timedOut:
            return .timeout
        case .cannotFindHost, .cannotConnectToHost:
            return .networkError(underlying: "Cannot reach server")
        default:
            return .networkError(underlying: error.localizedDescription)
        }
    }

    /// Create APIError from HTTP status code
    static func from(statusCode: Int, data: Data?) -> APIError {
        switch statusCode {
        case 401:
            return .unauthorized
        case 402:
            return .subscriptionRequired
        case 429:
            // Try to parse Retry-After header
            return .rateLimitExceeded(retryAfter: nil)
        case 500...599:
            return .serverError(statusCode: statusCode)
        default:
            return .unknown(message: "HTTP \(statusCode)")
        }
    }

    /// Create APIError from DecodingError
    static func from(_ error: DecodingError) -> APIError {
        switch error {
        case .keyNotFound(let key, _):
            return .decodingError(underlying: "Missing key: \(key.stringValue)")
        case .typeMismatch(let type, _):
            return .decodingError(underlying: "Type mismatch: expected \(type)")
        case .valueNotFound(let type, _):
            return .decodingError(underlying: "Value not found: \(type)")
        case .dataCorrupted(let context):
            return .decodingError(underlying: context.debugDescription)
        @unknown default:
            return .decodingError(underlying: "Unknown decoding error")
        }
    }
}

/**
 KEY CONCEPTS LEARNED:
 =====================

 1. Request/Response Models
    - Type-safe API communication
    - Codable for JSON conversion
    - CodingKeys for field mapping

 2. Custom Error Types
    - Enum for error cases
    - LocalizedError for user messages
    - Associated values for details

 3. Error Handling Strategy
    - Categorize errors (recoverable vs not)
    - Provide user-facing messages
    - Include recovery suggestions
    - Report errors selectively

 4. Error Conversion
    - Convert system errors to custom types
    - Maintain error context
    - Simplify error handling

 5. Equatable for Testing
    - Compare errors in tests
    - Handle associated values
    - Exhaustive matching

 USAGE EXAMPLE:
 ==============
 ```swift
 // Create request
 let request = GenerateRepliesRequest(
     imageData: base64Image,
     platform: .whatsapp,
     tone: .friendly,
     userId: currentUserId,
     metadata: RequestMetadata(
         appVersion: "1.0.0",
         iosVersion: "17.0",
         deviceModel: "iPhone 15",
         timestamp: Date(),
         timezone: TimeZone.current.identifier
     )
 )

 // Handle response
 do {
     let response = try await apiClient.generateReplies(request)
     print("Got \(response.suggestions.count) suggestions")
 } catch let error as APIError {
     // Show user-friendly error
     showAlert(
         title: error.errorDescription ?? "Error",
         message: error.failureReason ?? "",
         action: error.recoverySuggestion
     )

     // Report if needed
     if error.shouldReport {
         analytics.reportError(error)
     }
 }
 ```

 NEXT STEPS:
 ===========
 - Use in APIClient.swift for networking
 - Display errors in UI with alerts
 - Track errors in AnalyticsService
 - Test error scenarios
 */
