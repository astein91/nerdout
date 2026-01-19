import Foundation

/// Represents a single article reading event
struct ReadingProgress: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: String
    let articleId: String
    let topicId: String
    let category: Category
    let readAt: Date
    let readDurationSeconds: Int?

    init(
        id: UUID = UUID(),
        userId: String,
        articleId: String,
        topicId: String,
        category: Category,
        readAt: Date = Date(),
        readDurationSeconds: Int? = nil
    ) {
        self.id = id
        self.userId = userId
        self.articleId = articleId
        self.topicId = topicId
        self.category = category
        self.readAt = readAt
        self.readDurationSeconds = readDurationSeconds
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case articleId = "article_id"
        case topicId = "topic_id"
        case category
        case readAt = "read_at"
        case readDurationSeconds = "read_duration_seconds"
    }
}

/// Aggregated progress stats for a user across all categories
struct UserProgressSummary: Equatable {
    let userId: String
    let totalArticlesRead: Int
    let articlesReadThisWeek: Int
    let categoryBreakdown: [Category: Int]
    let lastReadAt: Date?

    init(
        userId: String,
        totalArticlesRead: Int = 0,
        articlesReadThisWeek: Int = 0,
        categoryBreakdown: [Category: Int] = [:],
        lastReadAt: Date? = nil
    ) {
        self.userId = userId
        self.totalArticlesRead = totalArticlesRead
        self.articlesReadThisWeek = articlesReadThisWeek
        self.categoryBreakdown = categoryBreakdown
        self.lastReadAt = lastReadAt
    }

    func toCategoryStats(totalArticlesPerCategory: [Category: Int]) -> [CategoryStats] {
        Category.allCases.map { category in
            CategoryStats(
                category: category,
                articlesRead: categoryBreakdown[category] ?? 0,
                totalArticles: totalArticlesPerCategory[category] ?? 0
            )
        }
    }

    func articlesRead(for category: Category) -> Int {
        categoryBreakdown[category] ?? 0
    }
}

extension UserProgressSummary: Codable {
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case totalArticlesRead = "total_articles_read"
        case articlesReadThisWeek = "articles_read_this_week"
        case categoryBreakdown = "category_breakdown"
        case lastReadAt = "last_read_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = try container.decode(String.self, forKey: .userId)
        totalArticlesRead = try container.decode(Int.self, forKey: .totalArticlesRead)
        articlesReadThisWeek = try container.decode(Int.self, forKey: .articlesReadThisWeek)
        lastReadAt = try container.decodeIfPresent(Date.self, forKey: .lastReadAt)

        let stringDict = try container.decode([String: Int].self, forKey: .categoryBreakdown)
        var breakdown: [Category: Int] = [:]
        for (key, value) in stringDict {
            if let category = Category(rawValue: key) {
                breakdown[category] = value
            }
        }
        categoryBreakdown = breakdown
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(totalArticlesRead, forKey: .totalArticlesRead)
        try container.encode(articlesReadThisWeek, forKey: .articlesReadThisWeek)
        try container.encodeIfPresent(lastReadAt, forKey: .lastReadAt)

        var stringDict: [String: Int] = [:]
        for (category, count) in categoryBreakdown {
            stringDict[category.rawValue] = count
        }
        try container.encode(stringDict, forKey: .categoryBreakdown)
    }
}

/// Response structure from Supabase for progress records
struct ProgressResponse: Codable {
    let id: String
    let userId: String
    let articleId: String
    let topicId: String
    let category: String
    let readAt: String
    let readDurationSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case articleId = "article_id"
        case topicId = "topic_id"
        case category
        case readAt = "read_at"
        case readDurationSeconds = "read_duration_seconds"
    }

    func toReadingProgress() -> ReadingProgress? {
        guard let uuid = UUID(uuidString: id),
              let categoryEnum = Category(rawValue: category) else {
            return nil
        }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let date = dateFormatter.date(from: readAt) ?? Date()

        return ReadingProgress(
            id: uuid,
            userId: userId,
            articleId: articleId,
            topicId: topicId,
            category: categoryEnum,
            readAt: date,
            readDurationSeconds: readDurationSeconds
        )
    }
}

/// Request structure for creating progress records in Supabase
struct CreateProgressRequest: Codable {
    let userId: String
    let articleId: String
    let topicId: String
    let category: String
    let readDurationSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case articleId = "article_id"
        case topicId = "topic_id"
        case category
        case readDurationSeconds = "read_duration_seconds"
    }

    init(from progress: ReadingProgress) {
        self.userId = progress.userId
        self.articleId = progress.articleId
        self.topicId = progress.topicId
        self.category = progress.category.rawValue
        self.readDurationSeconds = progress.readDurationSeconds
    }
}

/// Response for category stats aggregation query
struct CategoryStatsResponse: Codable {
    let category: String
    let count: Int
}
