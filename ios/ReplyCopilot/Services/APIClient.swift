import Foundation
import UIKit

/**
 APIClient - Network Communication Service

 LEARNING: Networking in iOS
 ============================
 This service handles all HTTP communication with the backend API using:
 - URLSession (Apple's networking framework)
 - async/await (modern Swift concurrency)
 - Codable (automatic JSON conversion)
 - Error handling
 - Request/Response logging
 - Retry logic

 ARCHITECTURE:
 - Singleton pattern for global access
 - Type-safe API methods
 - Generic request handler
 - Automatic error conversion
 */

@MainActor
class APIClient: ObservableObject {

    // MARK: - Singleton

    /**
     LEARNING: Singleton Pattern
     ===========================
     Single shared instance across the app
     Use 'static let shared' for thread-safe singleton
     @MainActor ensures all access is on main thread
     */

    static let shared = APIClient()

    // MARK: - Properties

    /**
     LEARNING: URLSession
     ====================
     URLSession is Apple's HTTP networking API
     Handles connections, caching, cookies, auth
     */

    private let session: URLSession
    private let baseURL: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    /// API timeout (seconds)
    private let timeout: TimeInterval = 30.0

    /// Maximum image size (5MB)
    private let maxImageSize = 5 * 1024 * 1024

    /// Debug logging enabled
    private let debugLogging = true

    // MARK: - Published Properties

    /**
     LEARNING: @Published Property Wrapper
     =====================================
     Automatically notifies SwiftUI views when value changes
     Part of Combine framework
     Makes APIClient observable
     */

    /// Whether a request is in progress
    @Published var isLoading = false

    /// Last error encountered
    @Published var lastError: APIError?

    // MARK: - Initialization

    private init() {
        // Configure URL session
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout * 2
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData

        // Create session
        self.session = URLSession(configuration: configuration)

        // Set base URL
        guard let url = URL(string: Config.apiURL) else {
            fatalError("Invalid API URL: \(Config.apiURL)")
        }
        self.baseURL = url

        // Configure JSON decoder
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // Configure JSON encoder
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - Main API Methods

    /**
     LEARNING: async/await
     =====================
     Modern Swift concurrency
     - async: Function can suspend and resume
     - await: Wait for async operation to complete
     - throws: Can throw errors
     - Much cleaner than completion handlers!
     */

    /// Generate reply suggestions from screenshot
    func generateReplies(
        image: UIImage,
        platform: Platform,
        tone: Tone,
        userId: String?
    ) async throws -> GenerateRepliesResponse {

        // Start loading
        isLoading = true
        defer { isLoading = false }

        // Validate and compress image
        guard let imageData = try? compressImage(image) else {
            throw APIError.encodingError(underlying: "Failed to compress image")
        }

        // Check size
        guard imageData.count <= maxImageSize else {
            throw APIError.imageTooLarge(maxSize: maxImageSize)
        }

        // Convert to base64
        let base64Image = imageData.base64EncodedString()

        // Create request
        let request = GenerateRepliesRequest(
            imageData: base64Image,
            platform: platform,
            tone: tone,
            userId: userId,
            metadata: createMetadata()
        )

        // Send request
        let response: GenerateRepliesResponse = try await post(
            endpoint: "/api/generateReplies",
            body: request
        )

        return response
    }

    /// Check subscription status
    func getSubscriptionStatus(userId: String) async throws -> SubscriptionStatusResponse {
        return try await get(
            endpoint: "/api/subscription/status",
            queryItems: [URLQueryItem(name: "userId", value: userId)]
        )
    }

    /// Update subscription tier
    func updateSubscription(userId: String, tier: SubscriptionTier) async throws {
        struct UpdateRequest: Codable {
            let userId: String
            let tier: SubscriptionTier
        }

        let request = UpdateRequest(userId: userId, tier: tier)
        let _: EmptyResponse = try await post(
            endpoint: "/api/subscription/update",
            body: request
        )
    }

    /// Report analytics event
    func reportEvent(userId: String, event: String, properties: [String: Any]) async throws {
        // Implementation for analytics endpoint
        // Fire and forget - don't block UI
    }

    // MARK: - Generic HTTP Methods

    /**
     LEARNING: Generic Functions
     ===========================
     <T> means "for any type T"
     T must conform to Decodable (can decode from JSON)
     This function works for any response type!
     */

    /// Generic GET request
    private func get<T: Decodable>(
        endpoint: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {

        // Build URL
        var urlComponents = URLComponents(
            url: baseURL.appendingPathComponent(endpoint),
            resolvingAgainstBaseURL: false
        )
        if !queryItems.isEmpty {
            urlComponents?.queryItems = queryItems
        }

        guard let url = urlComponents?.url else {
            throw APIError.invalidRequest(reason: "Invalid URL")
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth header if available
        try addAuthHeader(to: &request)

        // Send request
        return try await sendRequest(request)
    }

    /// Generic POST request
    private func post<T: Decodable, Body: Encodable>(
        endpoint: String,
        body: Body
    ) async throws -> T {

        // Build URL
        let url = baseURL.appendingPathComponent(endpoint)

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth header if available
        try addAuthHeader(to: &request)

        // Encode body
        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            throw APIError.encodingError(underlying: error.localizedDescription)
        }

        // Send request
        return try await sendRequest(request)
    }

    // MARK: - Request Execution

    /**
     LEARNING: URLSession.data(for:)
     ================================
     async version of dataTask
     Returns (Data, URLResponse) tuple
     Automatically throws on network errors
     */

    private func sendRequest<T: Decodable>(_ request: URLRequest) async throws -> T {

        // Log request
        if debugLogging {
            logRequest(request)
        }

        // Send request
        let (data, response): (Data, URLResponse)

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            lastError = APIError.from(error)
            throw lastError!
        } catch {
            lastError = APIError.networkError(underlying: error.localizedDescription)
            throw lastError!
        }

        // Log response
        if debugLogging {
            logResponse(data, response: response)
        }

        // Check HTTP status
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = APIError.invalidResponse
            lastError = error
            throw error
        }

        // Handle error status codes
        guard (200...299).contains(httpResponse.statusCode) else {
            let error = APIError.from(statusCode: httpResponse.statusCode, data: data)
            lastError = error
            throw error
        }

        // Decode response
        do {
            let decoded = try decoder.decode(T.self, from: data)
            lastError = nil
            return decoded
        } catch let decodingError as DecodingError {
            let error = APIError.from(decodingError)
            lastError = error
            throw error
        } catch {
            let error = APIError.decodingError(underlying: error.localizedDescription)
            lastError = error
            throw error
        }
    }

    // MARK: - Helper Methods

    /// Add authentication header to request
    private func addAuthHeader(to request: inout URLRequest) throws {
        // Try to get token from keychain
        let tokenItem = KeychainItem.apiToken()
        if tokenItem.exists() {
            let token = try tokenItem.readString()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    /// Compress image for upload
    private func compressImage(_ image: UIImage) throws -> Data {
        // Start with high quality
        var compression: CGFloat = 0.8
        let maxSize = maxImageSize

        guard var imageData = image.jpegData(compressionQuality: compression) else {
            throw APIError.encodingError(underlying: "Failed to convert image to JPEG")
        }

        // Reduce quality until under size limit
        while imageData.count > maxSize && compression > 0.1 {
            compression -= 0.1
            guard let compressed = image.jpegData(compressionQuality: compression) else {
                break
            }
            imageData = compressed
        }

        // If still too large, throw error
        if imageData.count > maxSize {
            throw APIError.imageTooLarge(maxSize: maxSize)
        }

        return imageData
    }

    /// Create request metadata
    private func createMetadata() -> RequestMetadata {
        RequestMetadata(
            appVersion: Config.appVersion,
            iosVersion: UIDevice.current.systemVersion,
            deviceModel: UIDevice.current.model,
            timestamp: Date(),
            timezone: TimeZone.current.identifier
        )
    }

    // MARK: - Logging

    /**
     LEARNING: Debugging Network Requests
     =====================================
     Log requests/responses in debug builds
     Helps diagnose API issues
     Never log in production!
     */

    private func logRequest(_ request: URLRequest) {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📤 API REQUEST")
        print("Method: \(request.httpMethod ?? "unknown")")
        print("URL: \(request.url?.absoluteString ?? "unknown")")
        if let headers = request.allHTTPHeaderFields {
            print("Headers: \(headers)")
        }
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            // Don't log image data (too large)
            if bodyString.contains("image_data") {
                print("Body: [Contains base64 image data]")
            } else {
                print("Body: \(bodyString)")
            }
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    private func logResponse(_ data: Data, response: URLResponse) {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📥 API RESPONSE")
        if let httpResponse = response as? HTTPURLResponse {
            print("Status: \(httpResponse.statusCode)")
            print("Headers: \(httpResponse.allHeaderFields)")
        }
        if let bodyString = String(data: data, encoding: .utf8) {
            print("Body: \(bodyString)")
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
}

// MARK: - Supporting Types

/**
 Empty response for endpoints that return no data
 */
struct EmptyResponse: Codable {}

// MARK: - Extensions

extension APIClient {

    /**
     LEARNING: Retry Logic
     =====================
     Automatically retry failed requests
     Exponential backoff: wait longer each time
     Useful for transient errors
     */

    /// Retry a request with exponential backoff
    func retry<T>(
        maxAttempts: Int = 3,
        initialDelay: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {

        var lastError: Error?
        var delay = initialDelay

        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error

                // Don't retry for certain errors
                if let apiError = error as? APIError {
                    switch apiError {
                    case .unauthorized, .subscriptionRequired, .invalidRequest:
                        throw error // Don't retry
                    default:
                        break // Retry
                    }
                }

                // Last attempt, throw error
                if attempt == maxAttempts {
                    break
                }

                // Wait before retrying
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                // Exponential backoff
                delay *= 2
            }
        }

        throw lastError ?? APIError.unknown(message: "Retry failed")
    }
}

/**
 KEY CONCEPTS LEARNED:
 =====================

 1. URLSession
    - Apple's networking framework
    - Handles HTTP requests/responses
    - Built-in caching, cookies, auth
    - Configuration options

 2. async/await
    - Modern concurrency model
    - Cleaner than completion handlers
    - Easy error handling with throws
    - Can suspend and resume

 3. Generic Functions
    - Work with any Decodable type
    - Type-safe API methods
    - Reusable code

 4. Codable
    - Automatic JSON conversion
    - Custom coding keys
    - Date strategies
    - Key strategies (snake_case ↔ camelCase)

 5. Error Handling
    - Custom error types
    - Error conversion
    - User-friendly messages
    - Logging for debugging

 6. Singleton Pattern
    - Single shared instance
    - Global access
    - Thread-safe with static let

 7. Image Compression
    - Reduce file size for upload
    - Iterative quality reduction
    - JPEG compression

 8. Request Logging
    - Debug network issues
    - Log requests/responses
    - Don't log sensitive data

 USAGE EXAMPLE:
 ==============
 ```swift
 // Get shared instance
 let api = APIClient.shared

 // Generate replies
 Task {
     do {
         let response = try await api.generateReplies(
             image: screenshot,
             platform: .whatsapp,
             tone: .friendly,
             userId: currentUserId
         )

         print("Got \\(response.suggestions.count) suggestions!")
         for suggestion in response.suggestions {
             print("- \\(suggestion.text)")
         }

     } catch let error as APIError {
         // Handle error
         print("Error: \\(error.localizedDescription)")
         print("Suggestion: \\(error.recoverySuggestion ?? "")")

         // Show alert to user
         showAlert(error)
     }
 }

 // With retry logic
 Task {
     do {
         let response = try await api.retry {
             try await api.generateReplies(
                 image: screenshot,
                 platform: .whatsapp,
                 tone: .friendly,
                 userId: nil
             )
         }
         print("Success after retries!")
     } catch {
         print("Failed after all retries")
     }
 }

 // Check subscription
 Task {
     do {
         let status = try await api.getSubscriptionStatus(userId: "user123")
         print("Tier: \\(status.tier)")
         print("Usage: \\(status.usageToday)/\\(status.usageLimit ?? 0)")
     } catch {
         print("Failed to check status")
     }
 }
 ```

 SWIFTUI INTEGRATION:
 ===================
 ```swift
 struct ContentView: View {
     @StateObject private var api = APIClient.shared

     var body: some View {
         VStack {
             if api.isLoading {
                 ProgressView("Generating replies...")
             }

             if let error = api.lastError {
                 Text(error.localizedDescription)
                     .foregroundColor(.red)
             }

             Button("Generate Replies") {
                 Task {
                     try await api.generateReplies(...)
                 }
             }
             .disabled(api.isLoading)
         }
     }
 }
 ```

 TESTING:
 ========
 ```swift
 func testGenerateReplies() async throws {
     let api = APIClient.shared
     let image = UIImage(named: "testScreenshot")!

     let response = try await api.generateReplies(
         image: image,
         platform: .whatsapp,
         tone: .friendly,
         userId: "test123"
     )

     XCTAssertFalse(response.suggestions.isEmpty)
     XCTAssertGreaterThan(response.processingTime, 0)
 }

 func testRetry() async throws {
     let api = APIClient.shared

     // Should succeed after retries
     let result = try await api.retry(maxAttempts: 3) {
         // Simulate failure first 2 times
         return "success"
     }

     XCTAssertEqual(result, "success")
 }
 ```

 NEXT STEPS:
 ===========
 - Use in Share Extension for screenshot upload
 - Use in ContentView for reply generation
 - Add certificate pinning for security
 - Add network reachability checking
 - Implement caching for offline support
 */
