import Foundation

struct Pivot: Codable, Identifiable {
    let id: UUID
    let sourceArticleId: UUID
    let suggestedTopicTitle: String
    let suggestedTopicDescription: String
    let category: Category
    let relevanceScore: Double
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case sourceArticleId = "source_article_id"
        case suggestedTopicTitle = "suggested_topic_title"
        case suggestedTopicDescription = "suggested_topic_description"
        case category
        case relevanceScore = "relevance_score"
        case createdAt = "created_at"
    }
}
