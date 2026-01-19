import Foundation

// MARK: - Shared Types (consolidated from TopicGenerationModels)

enum TopicCategory: String, Codable, CaseIterable {
    case sports = "Sports"
    case music = "Music"
    case science = "Science"
    case history = "History"
    case literature = "Literature"
    case technology = "Technology"
    case arts = "Arts"
    case philosophy = "Philosophy"
    case other = "Other"
}

// MARK: - Input Models

/// Content of an article that will be used to generate pivot suggestions
struct ArticleContent {
    /// The article's title
    let title: String

    /// The full article body text
    let bodyText: String

    /// The category of the parent topic
    let category: TopicCategory

    /// Key concepts already covered in the learning path
    let coveredConcepts: [String]

    /// User's sophistication level (1-5) for appropriate complexity matching
    let userSophisticationLevel: Int
}

// MARK: - Output Models

/// A suggested pivot for rabbit-holing into related topics
struct PivotSuggestion: Codable, Identifiable {
    let id: UUID

    /// Engaging title for the suggested topic
    let title: String

    /// Brief hook explaining why this is interesting and relevant
    let hook: String

    /// How this topic connects to the current article
    let connectionReason: String

    /// Suggested category for this pivot
    let suggestedCategory: TopicCategory

    /// Relevance score from 0-1 (how related to current content)
    let relevanceScore: Double

    /// Depth indicator: "deeper" (more detail on same topic),
    /// "tangent" (related but different angle), or "broader" (zoom out)
    let depthType: PivotDepthType
}

/// Indicates the relationship between pivot and source article
enum PivotDepthType: String, Codable {
    /// Goes deeper into a specific aspect of the current topic
    case deeper

    /// Explores a tangentially related but distinct topic
    case tangent

    /// Zooms out to broader context or umbrella topic
    case broader
}

/// Collection of pivot suggestions generated from article content
struct PivotSuggestionResult: Codable {
    /// Generated pivot suggestions, ordered by relevance
    let suggestions: [PivotSuggestion]

    /// Concepts extracted from the article that informed suggestions
    let extractedConcepts: [String]
}

// MARK: - API Response Models

/// Response structure from ChatGPT for pivot generation
struct PivotGenerationAPIResponse: Codable {
    let suggestions: [PivotSuggestionAPIResponse]
    let extractedConcepts: [String]
}

struct PivotSuggestionAPIResponse: Codable {
    let title: String
    let hook: String
    let connectionReason: String
    let suggestedCategory: String
    let relevanceScore: Double
    let depthType: String
}
