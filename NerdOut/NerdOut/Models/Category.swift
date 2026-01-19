import Foundation

enum Category: String, Codable, CaseIterable, Identifiable {
    case sports = "Sports"
    case music = "Music"
    case science = "Science"
    case history = "History"
    case literature = "Literature"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .sports: return "sportscourt"
        case .music: return "music.note"
        case .science: return "atom"
        case .history: return "clock.arrow.circlepath"
        case .literature: return "book"
        }
    }
}
