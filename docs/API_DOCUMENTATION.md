# 🔌 ReplyCopilot API Documentation

Complete API reference for the Azure Functions backend.

---

## 📡 Base URL

**Development:**
```
http://localhost:7071/api
```

**Production:**
```
https://replycopilot-api.azurewebsites.net/api
```

---

## 🔐 Authentication

All API requests require authentication via Azure AD OAuth 2.0 tokens.

### Authorization Header

```http
Authorization: Bearer {id_token}
```

### Getting a Token

**iOS (Firebase Auth):**
```swift
let token = try await Auth.auth().currentUser?.getIDToken()
```

**Token Expiration:** 1 hour (refresh automatically)

---

## 📋 Endpoints

### 1. Generate Replies

**Endpoint:** `POST /generateReplies`

**Description:** Analyzes screenshot and generates 3-5 contextual reply suggestions.

#### Request

**Headers:**
```http
Content-Type: application/json
Authorization: Bearer {id_token}
```

**Body:**
```json
{
  "imageData": "base64_encoded_image_string",
  "platform": "whatsapp",
  "tone": "friendly",
  "userId": "firebase_user_id",
  "metadata": {
    "timestamp": "2025-10-03T10:30:00Z",
    "deviceModel": "iPhone 15 Pro",
    "appVersion": "1.0.0",
    "osVersion": "iOS 17.0"
  }
}
```

**Field Descriptions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `imageData` | string | Yes | Base64-encoded JPEG/PNG image |
| `platform` | string | Yes | One of: `whatsapp`, `imessage`, `instagram`, `outlook`, `slack`, `teams` |
| `tone` | string | Yes | One of: `professional`, `friendly`, `funny`, `flirty` |
| `userId` | string | No | Firebase user ID for analytics |
| `metadata` | object | No | Additional context for analytics |

#### Response

**Success (200 OK):**
```json
{
  "suggestions": [
    {
      "id": "uuid-v4-string",
      "text": "Thanks for reaching out! I'd be happy to help with that.",
      "tone": "friendly",
      "platform": "whatsapp",
      "confidence": 0.95,
      "reasoning": "Polite acknowledgment with offer to help"
    },
    {
      "id": "uuid-v4-string",
      "text": "Sure thing! Let me know what you need.",
      "tone": "friendly",
      "platform": "whatsapp",
      "confidence": 0.92,
      "reasoning": "Casual but professional response"
    },
    {
      "id": "uuid-v4-string",
      "text": "Absolutely! I'm here to assist.",
      "tone": "friendly",
      "platform": "whatsapp",
      "confidence": 0.89,
      "reasoning": "Enthusiastic and supportive tone"
    }
  ],
  "processingTime": 1847,
  "requestId": "azure-invocation-id",
  "timestamp": "2025-10-03T10:30:02Z"
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `suggestions` | array | 3-5 reply suggestions |
| `suggestions[].id` | string | Unique suggestion ID |
| `suggestions[].text` | string | Reply text (ready to send) |
| `suggestions[].tone` | string | Tone used for generation |
| `suggestions[].platform` | string | Platform optimized for |
| `suggestions[].confidence` | number | AI confidence score (0-1) |
| `suggestions[].reasoning` | string | Why this reply was suggested |
| `processingTime` | number | Time in milliseconds |
| `requestId` | string | Azure request ID for debugging |
| `timestamp` | string | ISO 8601 timestamp |

#### Error Responses

**400 Bad Request - Invalid Input:**
```json
{
  "error": {
    "code": "INVALID_INPUT",
    "message": "Image data is required",
    "field": "imageData",
    "timestamp": "2025-10-03T10:30:00Z"
  }
}
```

**401 Unauthorized - Missing/Invalid Token:**
```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid or expired authentication token",
    "timestamp": "2025-10-03T10:30:00Z"
  }
}
```

**429 Too Many Requests - Rate Limit:**
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Daily limit of 20 requests exceeded. Upgrade to Pro for unlimited.",
    "retryAfter": 43200,
    "timestamp": "2025-10-03T10:30:00Z"
  }
}
```

**500 Internal Server Error:**
```json
{
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "An unexpected error occurred. Please try again.",
    "requestId": "azure-invocation-id",
    "timestamp": "2025-10-03T10:30:00Z"
  }
}
```

**503 Service Unavailable - OpenAI Down:**
```json
{
  "error": {
    "code": "SERVICE_UNAVAILABLE",
    "message": "AI service temporarily unavailable. Please try again shortly.",
    "retryAfter": 60,
    "timestamp": "2025-10-03T10:30:00Z"
  }
}
```

---

## 📊 Rate Limiting

### Free Tier
- **Limit:** 20 requests per day
- **Reset:** Midnight UTC
- **Headers:**
  ```
  X-RateLimit-Limit: 20
  X-RateLimit-Remaining: 15
  X-RateLimit-Reset: 1696291200
  ```

### Pro Tier
- **Limit:** Unlimited
- **Burst Protection:** 100 requests/minute
- **Headers:**
  ```
  X-RateLimit-Limit: unlimited
  X-RateLimit-Remaining: unlimited
  ```

---

## 🔄 Request/Response Examples

### Example 1: WhatsApp - Friendly Tone

**Request:**
```bash
curl -X POST https://replycopilot-api.azurewebsites.net/api/generateReplies \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGc..." \
  -d '{
    "imageData": "/9j/4AAQSkZJRgABAQAA...",
    "platform": "whatsapp",
    "tone": "friendly",
    "userId": "firebase_user_123"
  }'
```

**Response:**
```json
{
  "suggestions": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "text": "Hey! Thanks for reaching out 😊 I'd love to help with that!",
      "tone": "friendly",
      "platform": "whatsapp",
      "confidence": 0.96,
      "reasoning": "Warm greeting with emoji, offers assistance"
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "text": "Sure thing! Let me know what you need and I'll get right on it",
      "tone": "friendly",
      "platform": "whatsapp",
      "confidence": 0.93,
      "reasoning": "Casual confirmation with commitment to action"
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440002",
      "text": "Absolutely! Happy to help. What's up?",
      "tone": "friendly",
      "platform": "whatsapp",
      "confidence": 0.90,
      "reasoning": "Enthusiastic and conversational"
    }
  ],
  "processingTime": 1654,
  "requestId": "7c3f8a12-9d4e-4b1a-8f2c-5e6d7f8g9h0i",
  "timestamp": "2025-10-03T10:30:02.123Z"
}
```

### Example 2: Outlook - Professional Tone

**Request:**
```bash
curl -X POST https://replycopilot-api.azurewebsites.net/api/generateReplies \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGc..." \
  -d '{
    "imageData": "/9j/4AAQSkZJRgABAQAA...",
    "platform": "outlook",
    "tone": "professional"
  }'
```

**Response:**
```json
{
  "suggestions": [
    {
      "id": "650e8400-e29b-41d4-a716-446655440003",
      "text": "Thank you for your email. I would be happy to discuss this further. Please let me know your availability for a meeting.\n\nBest regards",
      "tone": "professional",
      "platform": "outlook",
      "confidence": 0.97,
      "reasoning": "Formal acknowledgment with clear call-to-action"
    },
    {
      "id": "650e8400-e29b-41d4-a716-446655440004",
      "text": "I appreciate you reaching out regarding this matter. I will review the details and respond by end of day tomorrow.\n\nKind regards",
      "tone": "professional",
      "platform": "outlook",
      "confidence": 0.94,
      "reasoning": "Professional commitment with timeline"
    },
    {
      "id": "650e8400-e29b-41d4-a716-446655440005",
      "text": "Thank you for bringing this to my attention. I have added it to my priority list and will address it promptly.\n\nSincerely",
      "tone": "professional",
      "platform": "outlook",
      "confidence": 0.91,
      "reasoning": "Acknowledgment with action commitment"
    }
  ],
  "processingTime": 1923,
  "requestId": "8d4f9b23-0e5f-5c2b-9g3d-6f7e8g9h0i1j",
  "timestamp": "2025-10-03T10:30:04.456Z"
}
```

---

## 🛡️ Security Best Practices

### Client-Side

1. **Never Log Sensitive Data:**
   ```swift
   // ❌ BAD
   print("Image data: \(imageData)")

   // ✅ GOOD
   print("Sending request with \(imageData.count) bytes")
   ```

2. **Validate Input:**
   ```swift
   guard image.size.width >= 100 && image.size.height >= 100 else {
       throw APIError.invalidImage
   }
   ```

3. **Compress Images:**
   ```swift
   let imageData = image.jpegData(compressionQuality: 0.8)
   ```

4. **Handle Tokens Securely:**
   ```swift
   // Store in Keychain, never UserDefaults
   try KeychainItem.sharedApiToken.save(tokenData)
   ```

### Server-Side

1. **Validate Tokens:** Azure AD OAuth validation on every request
2. **Rate Limiting:** Prevent abuse with daily/minute limits
3. **Input Validation:** Sanitize and validate all inputs
4. **No Data Retention:** Delete screenshots immediately after processing
5. **Audit Logging:** Log requests (metadata only, no content)

---

## 📈 Performance Optimization

### Image Compression

**Recommended settings:**
```swift
let compressionQuality: CGFloat = 0.8  // Balance quality/size
let maxDimension: CGFloat = 1024       // Resize if larger
```

**Size guidelines:**
- Optimal: < 500 KB
- Maximum: 5 MB
- Typical: 200-400 KB

### Caching

**Client-side caching:**
```swift
// Cache suggestions for 5 minutes
let cacheKey = "\(platform)_\(tone)_\(imageHash)"
if let cached = cache.get(cacheKey, maxAge: 300) {
    return cached
}
```

### Retry Logic

**Exponential backoff:**
```swift
let delays = [1, 2, 4]  // seconds
for (attempt, delay) in delays.enumerated() {
    do {
        return try await makeRequest()
    } catch {
        if attempt < delays.count - 1 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }
}
```

---

## 🔧 Error Handling

### Error Codes

| Code | HTTP Status | Description | Recovery |
|------|-------------|-------------|----------|
| `INVALID_INPUT` | 400 | Missing/invalid request field | Fix input and retry |
| `UNAUTHORIZED` | 401 | Invalid/expired token | Refresh token and retry |
| `FORBIDDEN` | 403 | Insufficient permissions | Upgrade subscription |
| `NOT_FOUND` | 404 | Endpoint doesn't exist | Check URL |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests | Wait or upgrade |
| `INTERNAL_ERROR` | 500 | Server error | Retry after delay |
| `SERVICE_UNAVAILABLE` | 503 | OpenAI temporarily down | Retry after delay |

### iOS Error Handling

```swift
do {
    let response = try await apiClient.generateReplies(
        image: screenshot,
        platform: .whatsapp,
        tone: .friendly
    )
    // Handle success
} catch APIError.rateLimitExceeded(let retryAfter) {
    // Show upgrade prompt
    showUpgradeAlert(retryAfter: retryAfter)
} catch APIError.networkError {
    // Show retry option
    showRetryAlert()
} catch APIError.serviceUnavailable {
    // Show temporary error
    showTemporaryErrorAlert()
} catch {
    // Generic error
    showGenericErrorAlert()
}
```

---

## 📊 Analytics Events

The API automatically tracks these events:

| Event | When Triggered | Data Collected |
|-------|----------------|----------------|
| `reply_generated` | Successful generation | platform, tone, response_time |
| `reply_failed` | Generation error | error_code, platform, tone |
| `rate_limit_hit` | Daily limit reached | user_tier, limit |
| `api_latency` | Every request | duration_ms, endpoint |

**Privacy:** No screenshot content or reply text is logged.

---

## 🧪 Testing

### Test in Development

```bash
# Start local Azure Functions
cd backend
npm install
npm start

# Test endpoint
curl -X POST http://localhost:7071/api/generateReplies \
  -H "Content-Type: application/json" \
  -d @test-request.json
```

### Sample Test Data

**test-request.json:**
```json
{
  "imageData": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
  "platform": "whatsapp",
  "tone": "friendly",
  "userId": "test_user_123"
}
```

### Integration Tests

```swift
func testGenerateReplies() async throws {
    let testImage = UIImage(named: "test-screenshot")!

    let response = try await apiClient.generateReplies(
        image: testImage,
        platform: .whatsapp,
        tone: .friendly,
        userId: "test_user"
    )

    XCTAssertEqual(response.suggestions.count, 3...5)
    XCTAssertTrue(response.processingTime < 5000)
}
```

---

## 📚 Additional Resources

- **Azure Functions Docs:** https://docs.microsoft.com/azure/azure-functions/
- **OpenAI API Docs:** https://platform.openai.com/docs/
- **Firebase Auth Docs:** https://firebase.google.com/docs/auth

---

## 🆘 Support

**Issues with the API?**

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Review error codes above
3. Check Azure status: https://status.azure.com
4. Open GitHub issue with:
   - Request ID from error response
   - Timestamp
   - Platform/tone used
   - Error message

---

**Last Updated:** October 3, 2025
**API Version:** 1.0.0
**OpenAI Model:** gpt-4o-vision-preview
