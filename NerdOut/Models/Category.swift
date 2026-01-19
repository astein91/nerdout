import Foundation

enum Category: String, CaseIterable, Identifiable, Codable {
    case sports = "Sports"
    case music = "Music"
    case science = "Science"
    case history = "History"
    case literature = "Literature"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .sports: return "sportscourt.fill"
        case .music: return "music.note"
        case .science: return "atom"
        case .history: return "clock.fill"
        case .literature: return "book.fill"
        }
    }

    var color: String {
        switch self {
        case .sports: return "orange"
        case .music: return "purple"
        case .science: return "blue"
        case .history: return "brown"
        case .literature: return "green"
        }
    }
}

struct CategoryStats: Identifiable, Codable {
    let id: UUID
    let category: Category
    let articlesRead: Int
    let totalArticles: Int

    init(id: UUID = UUID(), category: Category, articlesRead: Int, totalArticles: Int) {
        self.id = id
        self.category = category
        self.articlesRead = articlesRead
        self.totalArticles = totalArticles
    }

    var progress: Double {
        guard totalArticles > 0 else { return 0 }
        return Double(articlesRead) / Double(totalArticles)
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }
}
