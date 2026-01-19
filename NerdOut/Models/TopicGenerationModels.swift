import Foundation

// MARK: - Input Models

/// User's responses to clarifying questions about what they want to learn
struct ClarifyingResponses: Codable {
    /// The original topic description from the user
    let topicDescription: String

    /// Responses to clarifying questions (question -> answer)
    let responses: [ClarifyingResponse]
}

struct ClarifyingResponse: Codable {
    let question: String
    let answer: String
}

/// User's responses to level-setting questions about their familiarity
struct LevelSettingResponses: Codable {
    /// Overall assessed sophistication level (1-5)
    let sophisticationLevel: Int

    /// Individual familiarity responses
    let responses: [LevelSettingResponse]
}

struct LevelSettingResponse: Codable {
    let question: String
    let familiarityLevel: FamiliarityLevel
}

enum FamiliarityLevel: String, Codable {
    case neverHeard = "never_heard"
    case heardOfIt = "heard_of_it"
    case basicUnderstanding = "basic_understanding"
    case comfortable = "comfortable"
    case expert = "expert"
}

// MARK: - Output Models

/// A generated topic with its learning path
struct GeneratedTopic: Codable, Identifiable {
    let id: UUID
    let title: String
    let summary: String
    let category: TopicCategory
    let sophisticationLevel: Int
    let learningPath: LearningPath
    let createdAt: Date
}

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

/// A structured learning path for a topic
struct LearningPath: Codable {
    /// Ordered list of pivots (sub-topics) to explore
    let pivots: [TopicPivot]

    /// Estimated total reading time in minutes
    let estimatedReadingTime: Int

    /// Key concepts that will be covered
    let keyConcepts: [String]
}

/// A pivot point in the learning path - represents a sub-topic article
struct TopicPivot: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let order: Int
    let estimatedReadingTime: Int
    let prerequisites: [UUID]
}

// MARK: - API Response Models

/// Response structure from ChatGPT for topic generation
struct TopicGenerationAPIResponse: Codable {
    let title: String
    let summary: String
    let category: String
    let pivots: [PivotAPIResponse]
    let keyConcepts: [String]
}

struct PivotAPIResponse: Codable {
    let title: String
    let description: String
    let estimatedReadingTime: Int
    let dependsOn: [Int]?
}
