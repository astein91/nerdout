import Foundation

struct UserProgress: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let articleId: UUID
    let readAt: Date
    let readDurationSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case articleId = "article_id"
        case readAt = "read_at"
        case readDurationSeconds = "read_duration_seconds"
    }
}

struct CategoryProgress: Codable, Identifiable {
    let category: Category
    let articlesRead: Int
    let totalArticles: Int

    var id: String { category.id }

    var progressPercentage: Double {
        guard totalArticles > 0 else { return 0 }
        return Double(articlesRead) / Double(totalArticles)
    }

    enum CodingKeys: String, CodingKey {
        case category
        case articlesRead = "articles_read"
        case totalArticles = "total_articles"
    }
}
