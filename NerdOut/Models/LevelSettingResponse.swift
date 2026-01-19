import Foundation

/// A single response to a level-setting question
struct LevelSettingAnswer: Identifiable, Codable, Equatable {
    let id: UUID
    let questionId: UUID
    let concept: String
    let familiarityLevel: FamiliarityLevel
    let timestamp: Date

    init(
        id: UUID = UUID(),
        questionId: UUID,
        concept: String,
        familiarityLevel: FamiliarityLevel,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.questionId = questionId
        self.concept = concept
        self.familiarityLevel = familiarityLevel
        self.timestamp = timestamp
    }
}

/// Aggregated results from the level-setting flow
struct LevelSettingResult: Codable, Equatable {
    let topicDescription: String
    let answers: [LevelSettingAnswer]
    let completedAt: Date

    init(
        topicDescription: String,
        answers: [LevelSettingAnswer],
        completedAt: Date = Date()
    ) {
        self.topicDescription = topicDescription
        self.answers = answers
        self.completedAt = completedAt
    }

    /// Overall sophistication score from 0.0 (beginner) to 1.0 (expert)
    var sophisticationScore: Double {
        guard !answers.isEmpty else { return 0.0 }
        let totalWeight = answers.reduce(0.0) { $0 + $1.familiarityLevel.weight }
        return totalWeight / Double(answers.count)
    }

    /// User's sophistication level based on their answers
    var sophisticationLevel: SophisticationLevel {
        SophisticationLevel(score: sophisticationScore)
    }

    /// Concepts the user is familiar with (weight >= 0.5)
    var familiarConcepts: [String] {
        answers
            .filter { $0.familiarityLevel.weight >= 0.5 }
            .map { $0.concept }
    }

    /// Concepts the user is unfamiliar with (weight < 0.5)
    var unfamiliarConcepts: [String] {
        answers
            .filter { $0.familiarityLevel.weight < 0.5 }
            .map { $0.concept }
    }
}

/// Describes the user's overall sophistication level on a topic
enum SophisticationLevel: String, Codable, CaseIterable {
    case beginner
    case novice
    case intermediate
    case advanced
    case expert

    init(score: Double) {
        switch score {
        case 0.0..<0.2:
            self = .beginner
        case 0.2..<0.4:
            self = .novice
        case 0.4..<0.6:
            self = .intermediate
        case 0.6..<0.8:
            self = .advanced
        default:
            self = .expert
        }
    }

    var displayText: String {
        switch self {
        case .beginner: return "Beginner"
        case .novice: return "Novice"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }

    var description: String {
        switch self {
        case .beginner:
            return "New to this topic"
        case .novice:
            return "Some exposure to basic concepts"
        case .intermediate:
            return "Comfortable with core ideas"
        case .advanced:
            return "Strong grasp of the subject"
        case .expert:
            return "Deep expertise in the area"
        }
    }
}
