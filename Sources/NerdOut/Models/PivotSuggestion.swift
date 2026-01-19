import Foundation

/// A suggested pivot topic for rabbit-holing based on article content
struct PivotSuggestion: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let description: String
    let category: Category
    let relevanceScore: Double
    let sourceContext: String

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: Category,
        relevanceScore: Double,
        sourceContext: String
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.relevanceScore = relevanceScore
        self.sourceContext = sourceContext
    }
}

/// Categories for organizing topics and tracking progress
enum Category: String, Codable, CaseIterable {
    case sports = "Sports"
    case music = "Music"
    case science = "Science"
    case history = "History"
    case literature = "Literature"
    case technology = "Technology"
    case arts = "Arts"
    case philosophy = "Philosophy"
    case nature = "Nature"
    case culture = "Culture"
}

/// Response structure for pivot generation API calls
struct PivotGenerationResponse: Codable {
    let pivots: [PivotSuggestion]
    let sourceArticleId: String?
}
