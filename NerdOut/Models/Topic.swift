import Foundation

struct Topic: Identifiable {
    let id: UUID
    let title: String
    let summary: String
    let totalArticles: Int
    let articlesRead: Int
    let lastReadDate: Date?

    var readingProgress: Double {
        guard totalArticles > 0 else { return 0 }
        return Double(articlesRead) / Double(totalArticles)
    }

    var progressDescription: String {
        "\(articlesRead) of \(totalArticles) articles"
    }

    init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        totalArticles: Int,
        articlesRead: Int,
        lastReadDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.totalArticles = totalArticles
        self.articlesRead = articlesRead
        self.lastReadDate = lastReadDate
    }
}

extension Topic {
    static let sampleTopics: [Topic] = [
        Topic(
            title: "Swift Concurrency",
            summary: "Modern async/await patterns and structured concurrency in Swift",
            totalArticles: 12,
            articlesRead: 8,
            lastReadDate: Date().addingTimeInterval(-86400)
        ),
        Topic(
            title: "SwiftUI Animations",
            summary: "Building fluid, responsive animations for iOS apps",
            totalArticles: 8,
            articlesRead: 3,
            lastReadDate: Date().addingTimeInterval(-172800)
        ),
        Topic(
            title: "Core Data Fundamentals",
            summary: "Persistent storage and data modeling on Apple platforms",
            totalArticles: 15,
            articlesRead: 15,
            lastReadDate: Date().addingTimeInterval(-259200)
        ),
        Topic(
            title: "Machine Learning with Core ML",
            summary: "Integrating ML models into iOS applications",
            totalArticles: 10,
            articlesRead: 0,
            lastReadDate: nil
        ),
        Topic(
            title: "Networking Best Practices",
            summary: "URLSession, async networking, and error handling strategies",
            totalArticles: 7,
            articlesRead: 5,
            lastReadDate: Date().addingTimeInterval(-43200)
        )
    ]
}
