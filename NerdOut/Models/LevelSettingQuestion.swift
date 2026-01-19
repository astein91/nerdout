import Foundation

/// Represents a familiarity question used to gauge user sophistication on a topic.
/// These are NOT quiz questions - they assess prior exposure and comfort level.
struct LevelSettingQuestion: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let questionType: QuestionType
    let concept: String

    init(
        id: UUID = UUID(),
        text: String,
        questionType: QuestionType,
        concept: String
    ) {
        self.id = id
        self.text = text
        self.questionType = questionType
        self.concept = concept
    }

    enum QuestionType: String, Codable, CaseIterable {
        case heardOf = "heard_of"
        case familiarWith = "familiar_with"
        case usedBefore = "used_before"
        case comfortable = "comfortable"

        var responseOptions: [FamiliarityLevel] {
            switch self {
            case .heardOf:
                return [.never, .vaguely, .yes]
            case .familiarWith:
                return [.notAtAll, .somewhat, .very]
            case .usedBefore:
                return [.never, .occasionally, .regularly]
            case .comfortable:
                return [.notAtAll, .somewhat, .very]
            }
        }
    }
}

/// User's familiarity level for a given concept
enum FamiliarityLevel: String, Codable, CaseIterable, Identifiable {
    case never
    case notAtAll = "not_at_all"
    case vaguely
    case occasionally
    case somewhat
    case regularly
    case yes
    case very

    var id: String { rawValue }

    var displayText: String {
        switch self {
        case .never: return "Never heard of it"
        case .notAtAll: return "Not at all"
        case .vaguely: return "Vaguely familiar"
        case .occasionally: return "Occasionally"
        case .somewhat: return "Somewhat"
        case .regularly: return "Regularly"
        case .yes: return "Yes, I know it"
        case .very: return "Very familiar"
        }
    }

    /// Numeric weight for calculating overall sophistication score (0.0 - 1.0)
    var weight: Double {
        switch self {
        case .never, .notAtAll: return 0.0
        case .vaguely: return 0.25
        case .occasionally, .somewhat: return 0.5
        case .regularly, .yes: return 0.75
        case .very: return 1.0
        }
    }
}
