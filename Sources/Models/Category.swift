import Foundation

enum Category: String, CaseIterable, Identifiable {
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

struct CategoryStats: Identifiable {
    let id = UUID()
    let category: Category
    let articlesRead: Int
    let totalArticles: Int

    var progress: Double {
        guard totalArticles > 0 else { return 0 }
        return Double(articlesRead) / Double(totalArticles)
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }
}

extension CategoryStats {
    static var sampleData: [CategoryStats] {
        [
            CategoryStats(category: .sports, articlesRead: 12, totalArticles: 20),
            CategoryStats(category: .music, articlesRead: 8, totalArticles: 15),
            CategoryStats(category: .science, articlesRead: 25, totalArticles: 30),
            CategoryStats(category: .history, articlesRead: 5, totalArticles: 25),
            CategoryStats(category: .literature, articlesRead: 18, totalArticles: 22)
        ]
    }
}
