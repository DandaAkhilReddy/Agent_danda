import Foundation
import SwiftUI

/**
 Platform - Messaging Platform Enumeration

 LEARNING: Enums for Domain Modeling
 ====================================
 Using enums to represent messaging platforms gives us:
 - Type safety (can't pass invalid platform)
 - Exhaustive handling (switch must cover all cases)
 - Easy to add new platforms
 - Platform-specific behavior in one place
 */

enum Platform: String, Codable, CaseIterable, Identifiable {

    // MARK: - Cases

    case whatsapp = "whatsapp"
    case imessage = "imessage"
    case instagram = "instagram"
    case outlook = "outlook"
    case slack = "slack"
    case teams = "teams"

    // MARK: - Identifiable

    var id: String { rawValue }

    // MARK: - Display Properties

    /// User-friendly display name
    var displayName: String {
        switch self {
        case .whatsapp:  return "WhatsApp"
        case .imessage:  return "iMessage"
        case .instagram: return "Instagram"
        case .outlook:   return "Outlook"
        case .slack:     return "Slack"
        case .teams:     return "Microsoft Teams"
        }
    }

    /// SF Symbol icon name for UI
    /// LEARNING: SF Symbols are Apple's icon system
    /// Over 5,000 icons built into iOS
    var iconName: String {
        switch self {
        case .whatsapp:  return "message.fill"
        case .imessage:  return "message.badge.filled.fill"
        case .instagram: return "camera.fill"
        case .outlook:   return "envelope.fill"
        case .slack:     return "bubble.left.and.bubble.right.fill"
        case .teams:     return "person.2.fill"
        }
    }

    /// Brand color (hex string)
    var color: String {
        switch self {
        case .whatsapp:  return "#25D366" // WhatsApp green
        case .imessage:  return "#007AFF" // iOS blue
        case .instagram: return "#E4405F" // Instagram pink
        case .outlook:   return "#0078D4" // Outlook blue
        case .slack:     return "#4A154B" // Slack purple
        case .teams:     return "#6264A7" // Teams purple
        }
    }

    /// SwiftUI Color for UI
    /// LEARNING: Converting hex to SwiftUI Color
    var swiftUIColor: Color {
        Color(hex: color) ?? .blue
    }

    // MARK: - Platform Characteristics

    /// Messaging style description
    var style: String {
        switch self {
        case .whatsapp:
            return "Emoji-heavy, very casual, short messages"
        case .imessage:
            return "Natural iOS style, moderate emojis, conversational"
        case .instagram:
            return "Trendy, lots of emojis, ultra-casual, Gen Z style"
        case .outlook:
            return "Professional email, minimal emojis, proper grammar"
        case .slack:
            return "Professional but casual, use :emoji: format"
        case .teams:
            return "Business formal, clear and direct, minimal emojis"
        }
    }

    /// Whether platform is primarily for business
    var isBusinessPlatform: Bool {
        switch self {
        case .outlook, .teams, .slack:
            return true
        case .whatsapp, .imessage, .instagram:
            return false
        }
    }

    /// Whether platform supports rich formatting
    var supportsRichFormatting: Bool {
        switch self {
        case .outlook, .teams, .slack:
            return true
        case .whatsapp, .imessage, .instagram:
            return false
        }
    }

    /// Typical message length
    var typicalMessageLength: MessageLength {
        switch self {
        case .whatsapp, .instagram:
            return .short // 1-2 sentences
        case .imessage, .slack:
            return .medium // 2-3 sentences
        case .outlook, .teams:
            return .long // 3-5 sentences or paragraphs
        }
    }

    /// Emoji usage level
    var emojiUsage: EmojiUsage {
        switch self {
        case .instagram:
            return .heavy // Every message
        case .whatsapp, .imessage:
            return .moderate // Most messages
        case .slack:
            return .light // Occasional
        case .outlook, .teams:
            return .minimal // Rare
        }
    }

    // MARK: - API Integration

    /// Detailed instructions for GPT about this platform's style
    var systemPrompt: String {
        switch self {
        case .whatsapp:
            return """
            Platform: WhatsApp
            Style: Very casual, friendly, emoji-heavy
            Message length: 1-2 sentences max
            Emoji frequency: Use in most messages
            Tone: Conversational, like texting a friend
            Formatting: Plain text only, no markdown
            """

        case .imessage:
            return """
            Platform: iMessage (Apple Messages)
            Style: Casual but natural iOS messaging style
            Message length: 2-3 sentences
            Emoji frequency: Use when appropriate
            Tone: Friendly, conversational
            Formatting: Plain text, occasional emoji
            """

        case .instagram:
            return """
            Platform: Instagram DM
            Style: Trendy, Gen Z, very casual
            Message length: 1-2 sentences, often shorter
            Emoji frequency: Use frequently, 2-3 per message
            Tone: Fun, upbeat, trendy language
            Formatting: Abbreviations okay (lol, omg, tbh)
            """

        case .outlook:
            return """
            Platform: Outlook / Professional Email
            Style: Professional, business formal
            Message length: 3-5 sentences, can be longer
            Emoji frequency: Rarely or never
            Tone: Polite, respectful, clear
            Formatting: Proper email structure, grammar
            """

        case .slack:
            return """
            Platform: Slack
            Style: Professional but casual, tech-friendly
            Message length: 2-4 sentences
            Emoji frequency: Light use, :emoji: format
            Tone: Collaborative, helpful
            Formatting: Can use *bold*, `code`, etc.
            """

        case .teams:
            return """
            Platform: Microsoft Teams
            Style: Business professional, corporate
            Message length: 2-4 sentences
            Emoji frequency: Minimal, professional contexts only
            Tone: Clear, direct, professional
            Formatting: Clean, well-organized
            """
        }
    }

    // MARK: - Detection

    /**
     LEARNING: Static Methods for Business Logic
     ============================================
     Static methods don't need an instance
     Perfect for utility functions like detection
     */

    /// Detect platform from screenshot (future AI enhancement)
    static func detect(from screenshot: UIImage) -> Platform? {
        // TODO: Implement ML-based platform detection
        // For now, ask user to select
        return nil
    }

    /// Detect platform from app bundle identifier
    static func from(bundleId: String) -> Platform? {
        switch bundleId.lowercased() {
        case let id where id.contains("whatsapp"):
            return .whatsapp
        case let id where id.contains("messages"):
            return .imessage
        case let id where id.contains("instagram"):
            return .instagram
        case let id where id.contains("outlook") || id.contains("mail"):
            return .outlook
        case let id where id.contains("slack"):
            return .slack
        case let id where id.contains("teams"):
            return .teams
        default:
            return nil
        }
    }

    // MARK: - Statistics

    /// Usage popularity ranking
    var popularityRank: Int {
        switch self {
        case .whatsapp:  return 1 // Most popular globally
        case .imessage:  return 2 // Popular in US
        case .outlook:   return 3 // Professional
        case .instagram: return 4 // Social
        case .slack:     return 5 // Tech/Startups
        case .teams:     return 6 // Enterprise
        }
    }

    /// Get platforms sorted by popularity
    static var byPopularity: [Platform] {
        allCases.sorted { $0.popularityRank < $1.popularityRank }
    }
}

// MARK: - Supporting Types

/**
 LEARNING: Nested Enums
 ======================
 Enums can contain other enums
 Keeps related types together
 Platform.MessageLength.short reads nicely
 */

extension Platform {

    enum MessageLength {
        case short  // 1-2 sentences
        case medium // 2-3 sentences
        case long   // 3-5+ sentences
    }

    enum EmojiUsage {
        case minimal  // Rare
        case light    // Occasional
        case moderate // Most messages
        case heavy    // Every message
    }
}

// MARK: - Color Extension

/**
 LEARNING: SwiftUI Color from Hex
 =================================
 SwiftUI uses Color, not UIColor
 This extension converts hex strings to Color
 */

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0

        guard Scanner(string: hex).scanHexInt64(&int) else {
            return nil
        }

        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

// MARK: - Comparable

extension Platform: Comparable {
    static func < (lhs: Platform, rhs: Platform) -> Bool {
        lhs.popularityRank < rhs.popularityRank
    }
}

/**
 KEY CONCEPTS LEARNED:
 =====================

 1. Rich Domain Models
    - Not just data containers
    - Encapsulate business logic
    - Platform-specific behavior

 2. Type Safety
    - Can't pass invalid platform
    - Compiler checks all switches
    - Refactoring is safer

 3. SF Symbols
    - Apple's icon system
    - 5,000+ built-in icons
    - Scale perfectly
    - Support dark mode

 4. SwiftUI Color
    - Different from UIColor
    - Hex conversion utility
    - Used in SwiftUI views

 USAGE EXAMPLE:
 ==============
 ```swift
 // Display all platforms
 ForEach(Platform.allCases) { platform in
     Label(platform.displayName, systemImage: platform.iconName)
         .foregroundColor(platform.swiftUIColor)
 }

 // Get recommended tone
 let tone = Tone.recommended(for: .outlook) // .professional

 // Use in API
 let style = platform.systemPrompt
 ```
 */
