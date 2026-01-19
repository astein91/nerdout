import Foundation

/// Service for generating level-setting questions via ChatGPT
actor LevelSettingService {
    private let apiClient: OpenAIAPIClient

    init(apiClient: OpenAIAPIClient = .shared) {
        self.apiClient = apiClient
    }

    /// Generates familiarity questions for a given topic description
    func generateQuestions(for topicDescription: String) async throws -> [LevelSettingQuestion] {
        let prompt = buildPrompt(for: topicDescription)
        let response = try await apiClient.complete(prompt: prompt)
        return try parseQuestions(from: response)
    }

    private func buildPrompt(for topicDescription: String) -> String {
        """
        You are helping gauge a user's familiarity with a learning topic. Generate 4-5 familiarity questions \
        to understand their background knowledge.

        IMPORTANT: These are NOT quiz questions. Do not test knowledge. Instead, ask about:
        - Whether they've heard of key concepts
        - Their comfort level with related terminology
        - Whether they've done related activities before

        Topic the user wants to learn about: "\(topicDescription)"

        Generate questions in this JSON format:
        {
          "questions": [
            {
              "text": "Have you heard of [concept]?",
              "type": "heard_of",
              "concept": "[concept name]"
            },
            {
              "text": "How familiar are you with [terminology]?",
              "type": "familiar_with",
              "concept": "[concept name]"
            },
            {
              "text": "Have you ever [practiced/used] [activity]?",
              "type": "used_before",
              "concept": "[activity name]"
            },
            {
              "text": "How comfortable do you feel with [concept]?",
              "type": "comfortable",
              "concept": "[concept name]"
            }
          ]
        }

        Question types must be one of: heard_of, familiar_with, used_before, comfortable

        Keep questions conversational and non-intimidating. Order from basic to more advanced concepts.
        """
    }

    private func parseQuestions(from response: String) throws -> [LevelSettingQuestion] {
        guard let data = extractJSON(from: response)?.data(using: .utf8) else {
            throw LevelSettingError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(QuestionsResponse.self, from: data)
        return decoded.questions.compactMap { item in
            guard let type = LevelSettingQuestion.QuestionType(rawValue: item.type) else {
                return nil
            }
            return LevelSettingQuestion(
                text: item.text,
                questionType: type,
                concept: item.concept
            )
        }
    }

    private func extractJSON(from response: String) -> String? {
        guard let start = response.firstIndex(of: "{"),
              let end = response.lastIndex(of: "}") else {
            return nil
        }
        return String(response[start...end])
    }
}

// MARK: - Response Parsing Types

private struct QuestionsResponse: Decodable {
    let questions: [QuestionItem]
}

private struct QuestionItem: Decodable {
    let text: String
    let type: String
    let concept: String
}

// MARK: - Errors

enum LevelSettingError: LocalizedError {
    case invalidResponse
    case noQuestionsGenerated
    case apiError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Could not parse the response"
        case .noQuestionsGenerated:
            return "No questions were generated"
        case .apiError(let error):
            return "API error: \(error.localizedDescription)"
        }
    }
}

// MARK: - OpenAI API Client Protocol

/// Protocol for OpenAI API communication
protocol OpenAIAPIClientProtocol {
    func complete(prompt: String) async throws -> String
}

/// Placeholder for the actual OpenAI API client (implemented in hq-jvt)
class OpenAIAPIClient: OpenAIAPIClientProtocol {
    static let shared = OpenAIAPIClient()

    func complete(prompt: String) async throws -> String {
        // Placeholder - actual implementation in API Client Layer (hq-jvt)
        fatalError("OpenAI API client not yet implemented")
    }
}
