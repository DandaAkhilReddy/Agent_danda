import SwiftUI

/**
 HistoryView - Past Reply Suggestions Browser

 LEARNING: List in SwiftUI
 ==========================
 List is the primary scrolling container
 - Similar to UITableView
 - Automatic scroll behavior
 - Built-in swipe actions
 - Search integration
 - Section support
 */

struct HistoryView: View {

    // MARK: - Properties

    @StateObject private var viewModel = HistoryViewModel()

    /// Search text
    @State private var searchText = ""

    /// Selected filter
    @State private var filterOption: FilterOption = .all

    /// Show filter menu
    @State private var showingFilterMenu = false

    /// Selected suggestion for detail
    @State private var selectedSuggestion: ReplySuggestion?

    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter bar
                if !viewModel.suggestions.isEmpty {
                    filterBar
                }

                // Suggestions list
                if viewModel.filteredSuggestions.isEmpty {
                    emptyState
                } else {
                    suggestionsList
                }
            }
            .navigationTitle("History")
            .searchable(text: $searchText, prompt: "Search replies")
            .onChange(of: searchText) { _ in
                viewModel.search(searchText)
            }
            .onChange(of: filterOption) { _ in
                viewModel.filter(filterOption)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            viewModel.exportHistory()
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }

                        Button(role: .destructive) {
                            viewModel.clearAll()
                        } label: {
                            Label("Clear All", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $selectedSuggestion) { suggestion in
                SuggestionDetailView(suggestion: suggestion)
            }
            .task {
                await viewModel.loadHistory()
            }
        }
    }

    // MARK: - Subviews

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(FilterOption.allCases) { option in
                    FilterChip(
                        title: option.title,
                        icon: option.icon,
                        isSelected: filterOption == option
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            filterOption = option
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var suggestionsList: some View {
        List {
            ForEach(viewModel.groupedSuggestions.keys.sorted(by: >), id: \.self) { date in
                Section(header: Text(date.formatted(.dateTime.month().day().year()))) {
                    ForEach(viewModel.groupedSuggestions[date] ?? []) { suggestion in
                        HistoryRow(suggestion: suggestion)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedSuggestion = suggestion
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        viewModel.delete(suggestion)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    UIPasteboard.general.string = suggestion.text
                                    viewModel.trackCopy(suggestion)
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    viewModel.toggleFavorite(suggestion)
                                } label: {
                                    Label("Favorite", systemImage: suggestion.isUsed ? "star.fill" : "star")
                                }
                                .tint(.yellow)
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: searchText.isEmpty ? "clock.badge" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text(searchText.isEmpty ? "No History Yet" : "No Results")
                .font(.title2)
                .fontWeight(.semibold)

            Text(searchText.isEmpty
                 ? "Your generated replies will appear here"
                 : "Try a different search term")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - History Row

struct HistoryRow: View {
    let suggestion: ReplySuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Platform and tone badges
            HStack {
                // Platform
                Label(suggestion.platform.displayName, systemImage: suggestion.platform.iconName)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: suggestion.platform.color)?.opacity(0.15))
                    .foregroundColor(Color(hex: suggestion.platform.color))
                    .clipShape(Capsule())

                // Tone
                Text("\(suggestion.tone.emoji) \(suggestion.tone.displayName)")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.15))
                    .foregroundColor(.secondary)
                    .clipShape(Capsule())

                Spacer()

                // Favorite indicator
                if suggestion.isUsed {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }

            // Reply text
            Text(suggestion.text)
                .font(.body)
                .lineLimit(2)

            // Time and confidence
            HStack {
                Text(suggestion.timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if let confidence = suggestion.confidence {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("\(suggestion.confidenceEmoji) \(Int(confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Suggestion Detail View

struct SuggestionDetailView: View {
    @Environment(\.dismiss) var dismiss
    let suggestion: ReplySuggestion

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Platform and Tone
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Platform")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Label(suggestion.platform.displayName, systemImage: suggestion.platform.iconName)
                                .font(.headline)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Tone")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack {
                                Text(suggestion.tone.emoji)
                                Text(suggestion.tone.displayName)
                            }
                            .font(.headline)
                        }
                    }

                    Divider()

                    // Reply text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reply")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(suggestion.text)
                            .font(.body)
                            .textSelection(.enabled)
                    }

                    Divider()

                    // Metadata
                    VStack(alignment: .leading, spacing: 12) {
                        MetadataRow(label: "Created", value: suggestion.createdAt.formatted(.dateTime))

                        if let confidence = suggestion.confidence {
                            MetadataRow(
                                label: "Confidence",
                                value: "\(suggestion.confidenceEmoji) \(Int(confidence * 100))%"
                            )
                        }

                        MetadataRow(label: "Characters", value: "\(suggestion.characterCount)")
                    }

                    Spacer()

                    // Actions
                    HStack(spacing: 12) {
                        Button {
                            UIPasteboard.general.string = suggestion.text
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        ShareLink(item: suggestion.text) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// MARK: - Filter Option

enum FilterOption: String, CaseIterable, Identifiable {
    case all
    case whatsapp
    case imessage
    case instagram
    case outlook
    case slack
    case teams
    case professional
    case friendly
    case funny
    case flirty

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .whatsapp: return "WhatsApp"
        case .imessage: return "iMessage"
        case .instagram: return "Instagram"
        case .outlook: return "Outlook"
        case .slack: return "Slack"
        case .teams: return "Teams"
        case .professional: return "Professional"
        case .friendly: return "Friendly"
        case .funny: return "Funny"
        case .flirty: return "Flirty"
        }
    }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .whatsapp: return "message.fill"
        case .imessage: return "message.badge.filled.fill"
        case .instagram: return "camera.fill"
        case .outlook: return "envelope.fill"
        case .slack: return "bubble.left.and.bubble.right.fill"
        case .teams: return "person.2.fill"
        case .professional: return "💼"
        case .friendly: return "😊"
        case .funny: return "😂"
        case .flirty: return "😘"
        }
    }
}

// MARK: - History ViewModel

@MainActor
class HistoryViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var suggestions: [ReplySuggestion] = []
    @Published var filteredSuggestions: [ReplySuggestion] = []
    @Published var groupedSuggestions: [Date: [ReplySuggestion]] = [:]

    // MARK: - Services

    private let storage = StorageService.shared
    private let analytics = AnalyticsService.shared

    // MARK: - Methods

    func loadHistory() async {
        suggestions = storage.loadHistory()
        filteredSuggestions = suggestions
        groupByDate()

        analytics.trackScreenView("History")
    }

    func refresh() async {
        await loadHistory()
    }

    func search(_ query: String) {
        if query.isEmpty {
            filteredSuggestions = suggestions
        } else {
            filteredSuggestions = suggestions.filter { suggestion in
                suggestion.text.localizedCaseInsensitiveContains(query) ||
                suggestion.platform.displayName.localizedCaseInsensitiveContains(query) ||
                suggestion.tone.displayName.localizedCaseInsensitiveContains(query)
            }
        }
        groupByDate()
    }

    func filter(_ option: FilterOption) {
        switch option {
        case .all:
            filteredSuggestions = suggestions

        case .whatsapp:
            filteredSuggestions = suggestions.filter { $0.platform == .whatsapp }
        case .imessage:
            filteredSuggestions = suggestions.filter { $0.platform == .imessage }
        case .instagram:
            filteredSuggestions = suggestions.filter { $0.platform == .instagram }
        case .outlook:
            filteredSuggestions = suggestions.filter { $0.platform == .outlook }
        case .slack:
            filteredSuggestions = suggestions.filter { $0.platform == .slack }
        case .teams:
            filteredSuggestions = suggestions.filter { $0.platform == .teams }

        case .professional:
            filteredSuggestions = suggestions.filter { $0.tone == .professional }
        case .friendly:
            filteredSuggestions = suggestions.filter { $0.tone == .friendly }
        case .funny:
            filteredSuggestions = suggestions.filter { $0.tone == .funny }
        case .flirty:
            filteredSuggestions = suggestions.filter { $0.tone == .flirty }
        }

        groupByDate()
        analytics.trackButtonTap("filter_\(option.rawValue)", screen: "History")
    }

    func delete(_ suggestion: ReplySuggestion) {
        try? storage.deleteFromHistory(suggestion)
        suggestions.removeAll { $0.id == suggestion.id }
        filteredSuggestions.removeAll { $0.id == suggestion.id }
        groupByDate()

        analytics.trackButtonTap("delete_suggestion", screen: "History")
    }

    func toggleFavorite(_ suggestion: ReplySuggestion) {
        // Mark as used/favorite
        if let index = suggestions.firstIndex(where: { $0.id == suggestion.id }) {
            suggestions[index].markAsUsed()
            try? storage.saveHistory(suggestions)
        }
        Task {
            await loadHistory()
        }
    }

    func trackCopy(_ suggestion: ReplySuggestion) {
        analytics.trackReplyCopied(tone: suggestion.tone, platform: suggestion.platform)
    }

    func clearAll() {
        storage.clearHistory()
        suggestions = []
        filteredSuggestions = []
        groupedSuggestions = [:]

        analytics.trackButtonTap("clear_all_history", screen: "History")
    }

    func exportHistory() {
        // TODO: Implement export to CSV/JSON
        analytics.trackButtonTap("export_history", screen: "History")
    }

    // MARK: - Helper Methods

    private func groupByDate() {
        let calendar = Calendar.current
        groupedSuggestions = Dictionary(grouping: filteredSuggestions) { suggestion in
            calendar.startOfDay(for: suggestion.createdAt)
        }
    }
}

// MARK: - Preview

#Preview("History - Filled") {
    HistoryView()
}

#Preview("History - Empty") {
    HistoryView()
}

#Preview("Suggestion Detail") {
    SuggestionDetailView(
        suggestion: ReplySuggestion(
            text: "Thanks! That sounds great. I'll be there at 3pm.",
            tone: .friendly,
            platform: .whatsapp,
            createdAt: Date(),
            confidence: 0.95,
            isUsed: false
        )
    )
}

/**
 KEY CONCEPTS LEARNED:
 =====================

 1. List in SwiftUI
    - Scrolling container
    - Section support
    - Swipe actions
    - Search integration

 2. Searchable Modifier
    - Built-in search bar
    - Placeholder text
    - onChange callback
    - Dismiss on scroll

 3. Swipe Actions
    - Leading/trailing
    - Multiple actions
    - Tint colors
    - Full swipe

 4. Grouped Data
    - Dictionary grouping
    - Date-based sections
    - Sorted keys
    - Dynamic sections

 5. Filter Chips
    - Horizontal scroll
    - Active state
    - Tap to filter
    - Visual feedback

 6. Detail Sheet
    - Modal presentation
    - Item binding
    - Dismiss action
    - Text selection

 7. Empty States
    - Show when no data
    - Different messages
    - Search vs no data
    - Helpful guidance

 8. Context Menus
    - Long press
    - Multiple actions
    - Icons and labels
    - Destructive actions

 NEXT STEPS:
 ===========
 - Add export to CSV/JSON
 - Add favorites section
 - Add date range filter
 - Add statistics view
 - Add batch operations
 */
