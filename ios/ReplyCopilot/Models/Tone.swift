import Foundation

/**
 Tone - Reply Tone Enumeration

 LEARNING: Swift Enums
 =====================
 Enums in Swift are powerful first-class types with:
 - Associated values
 - Computed properties
 - Methods
 - Protocol conformance
 - Much more than C-style enums!

 WHY use enum for Tone?
 - Type-safe (compiler checks)
 - Exhaustive switch statements
 - Can't have invalid values
 - Easy to add new tones
 */

enum Tone: String, Codable, CaseIterable, Identifiable {

    // MARK: - Cases

    /**
     LEARNING: Enum Cases with Raw Values
     =====================================
     String raw value makes it easy to:
     - Convert to/from JSON
     - Store in database
     - Use in API requests
     - Debug (readable strings)
     */

    case professional = "professional"
    case friendly = "friendly"
    case funny = "funny"
    case flirty = "flirty"

    // MARK: - Identifiable

    /**
     LEARNING: Identifiable Protocol
     ================================
     SwiftUI requires Identifiable for ForEach
     Using rawValue as ID is common pattern for enums
     */
    var id: String { rawValue }

    // MARK: - Display Properties

    /// User-friendly display name
    var displayName: String {
        switch self {
        case .professional:
            return "Professional"
        case .friendly:
            return "Friendly"
        case .funny:
            return "Funny"
        case .flirty:
            return "Flirty"
        }
    }

    /// Emoji representation for UI
    var emoji: String {
        switch self {
        case .professional:
            return "💼"
        case .friendly:
            return "😊"
        case .funny:
            return "😂"
        case .flirty:
            return "😘"
        }
    }

    /// Detailed description of when to use this tone
    var description: String {
        switch self {
        case .professional:
            return "For work emails, LinkedIn, and formal business communication"
        case .friendly:
            return "For friends, family, and casual conversations"
        case .funny:
            return "For humorous chats with close friends"
        case .flirty:
            return "For romantic interests and playful conversations"
        }
    }

    /// Example reply showing this tone's style
    var exampleReply: String {
        switch self {
        case .professional:
            return "Thank you for reaching out. I'll review this and get back to you by end of day."
        case .friendly:
            return "Thanks! I'll check that out 😊 Let me know if you need anything!"
        case .funny:
            return "Haha that's awesome! 😂 You're killing it!"
        case .flirty:
            return "You're the best! 💕 Can't wait to see you!"
        }
    }

    /// Color for UI (hex string)
    var color: String {
        switch self {
        case .professional:
            return "#007AFF" // Blue
        case .friendly:
            return "#34C759" // Green
        case .funny:
            return "#FF9500" // Orange
        case .flirty:
            return "#FF2D55" // Pink
        }
    }

    // MARK: - API Integration

    /**
     Instructions for GPT to use this tone
     Used in API prompt to Azure OpenAI
     */
    var systemPrompt: String {
        switch self {
        case .professional:
            return """
            Generate professional, business-appropriate replies.
            Use clear, polite language with proper grammar.
            Avoid slang and excessive emojis.
            Keep tone respectful and formal.
            """

        case .friendly:
            return """
            Generate warm, conversational replies.
            Use casual language with appropriate emojis.
            Be helpful and approachable.
            Keep tone natural and friendly.
            """

        case .funny:
            return """
            Generate witty, humorous replies.
            Use light jokes, puns, or clever wordplay.
            Keep it appropriate and fun.
            Add laughing emojis when fitting.
            """

        case .flirty:
            return """
            Generate playful, charming replies.
            Use subtle flirtation and compliments.
            Be tasteful, not overly forward.
            Add romantic emojis when appropriate.
            """
        }
    }

    // MARK: - Statistics

    /// Popularity ranking (for analytics)
    var popularityRank: Int {
        switch self {
        case .friendly:    return 1 // Most popular
        case .professional: return 2
        case .funny:       return 3
        case .flirty:      return 4
        }
    }

    // MARK: - CaseIterable

    /**
     LEARNING: CaseIterable Protocol
     ================================
     Provides static array of all cases: Tone.allCases
     Perfect for:
     - Picker views
     - Settings screens
     - Iteration in tests
     */

    /// Get all tones sorted by popularity
    static var byPopularity: [Tone] {
        allCases.sorted { $0.popularityRank < $1.popularityRank }
    }
}

// MARK: - Extensions

extension Tone {

    /**
     LEARNING: Static Factory Methods
     ==================================
     Provide convenient ways to create instances
     Better than init when you have common patterns
     */

    /// Get tone from string (case-insensitive)
    static func from(string: String) -> Tone? {
        Tone(rawValue: string.lowercased())
    }

    /// Get default tone (most popular)
    static var `default`: Tone {
        .friendly
    }

    /// Get recommended tone for a platform
    static func recommended(for platform: Platform) -> Tone {
        switch platform {
        case .outlook, .teams:
            return .professional
        case .whatsapp, .imessage:
            return .friendly
        case .instagram, .slack:
            return .funny
        }
    }
}

// MARK: - Comparable

extension Tone: Comparable {
    /**
     LEARNING: Comparable Protocol
     ==============================
     Allows sorting and comparison with <, >, <=, >=
     Useful for UI ordering
     */
    static func < (lhs: Tone, rhs: Tone) -> Bool {
        lhs.popularityRank < rhs.popularityRank
    }
}

// MARK: - CustomStringConvertible

extension Tone: CustomStringConvertible {
    /**
     LEARNING: CustomStringConvertible
     ==================================
     Provides better debug printing
     print(tone) will use this instead of raw value
     */
    var description: String {
        "\(displayName) \(emoji)"
    }
}

/**
 KEY CONCEPTS LEARNED:
 =====================

 1. Enum Best Practices
    - Raw values for API/database
    - Computed properties for UI
    - Protocol conformance (Codable, Identifiable)
    - CaseIterable for all cases

 2. Type Safety
    - Can't have invalid tone
    - Compiler enforces exhaustive switch
    - Autocomplete in Xcode

 3. Rich Enums
    - Not just simple constants
    - Methods, properties, extensions
    - Business logic encapsulated

 4. Protocols
    - Codable: JSON encoding/decoding
    - CaseIterable: Access all cases
    - Identifiable: SwiftUI ForEach
    - Comparable: Sorting support

 NEXT STEPS:
 ===========
 - See Platform.swift for similar pattern
 - Use in ReplySuggestion model
 - Use in Settings UI for picker

 USAGE EXAMPLE:
 ==============
 ```swift
 // Get all tones for picker
 ForEach(Tone.allCases) { tone in
     Text("\(tone.emoji) \(tone.displayName)")
 }

 // Get default tone
 let tone = Tone.default

 // Use in API
 let prompt = tone.systemPrompt
 ```
 */
