import Foundation

/// Service for generating related topic suggestions (pivots) based on article content
/// Enables rabbit-holing by suggesting interesting tangent topics for exploration
actor PivotGenerator {
    private let apiClient: OpenAIClient
    private let maxPivots: Int

    init(apiClient: OpenAIClient, maxPivots: Int = 5) {
        self.apiClient = apiClient
        self.maxPivots = maxPivots
    }

    /// Generate pivot suggestions based on article content
    /// - Parameters:
    ///   - articleContent: The full text of the article
    ///   - articleTitle: The title of the current article
    ///   - currentCategory: The category of the current article (for context)
    /// - Returns: Array of pivot suggestions for rabbit-holing
    func generatePivots(
        from articleContent: String,
        articleTitle: String,
        currentCategory: Category
    ) async throws -> [PivotSuggestion] {
        let prompt = buildPrompt(
            articleContent: articleContent,
            articleTitle: articleTitle,
            currentCategory: currentCategory
        )

        let response = try await apiClient.sendChatCompletion(
            messages: [
                .system(content: systemPrompt),
                .user(content: prompt)
            ],
            responseFormat: .json
        )

        return try parsePivotResponse(response, sourceArticle: articleTitle)
    }

    private var systemPrompt: String {
        """
        You are a curious intellectual guide helping readers explore fascinating tangent topics. \
        Your role is to identify the most intriguing rabbit holes - unexpected connections, \
        deeper explorations, and adjacent discoveries that would delight a curious mind.

        When suggesting pivots:
        - Prioritize unexpected but relevant connections over obvious next steps
        - Include a mix of deeper dives (more specific) and broader contexts (more general)
        - Favor topics that reveal surprising relationships or hidden histories
        - Consider cross-disciplinary connections (science + history, art + technology, etc.)
        - Each suggestion should feel like discovering a secret passage in a library

        Always respond with valid JSON in this exact format:
        {
          "pivots": [
            {
              "title": "Brief compelling title (3-7 words)",
              "description": "One sentence explaining why this is fascinating and how it connects",
              "category": "One of: Sports, Music, Science, History, Literature, Technology, Arts, Philosophy, Nature, Culture",
              "relevanceScore": 0.0-1.0,
              "sourceContext": "The specific phrase or concept from the article that inspired this pivot"
            }
          ]
        }
        """
    }

    private func buildPrompt(
        articleContent: String,
        articleTitle: String,
        currentCategory: Category
    ) -> String {
        """
        Based on this article, suggest \(maxPivots) fascinating pivot topics for rabbit-holing.

        ARTICLE TITLE: \(articleTitle)
        CURRENT CATEGORY: \(currentCategory.rawValue)

        ARTICLE CONTENT:
        \(articleContent.prefix(4000))

        Generate \(maxPivots) pivot suggestions that would captivate a curious reader. \
        Include at least one cross-disciplinary suggestion that connects to a different field. \
        Prioritize the unexpected and delightful over the predictable.
        """
    }

    private func parsePivotResponse(_ response: String, sourceArticle: String) throws -> [PivotSuggestion] {
        guard let data = response.data(using: .utf8) else {
            throw PivotGeneratorError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(PivotAPIResponse.self, from: data)
        return decoded.pivots.map { apiPivot in
            PivotSuggestion(
                title: apiPivot.title,
                description: apiPivot.description,
                category: Category(rawValue: apiPivot.category) ?? .culture,
                relevanceScore: apiPivot.relevanceScore,
                sourceContext: apiPivot.sourceContext
            )
        }
    }
}

// MARK: - API Response Types

private struct PivotAPIResponse: Codable {
    let pivots: [APIPivot]
}

private struct APIPivot: Codable {
    let title: String
    let description: String
    let category: String
    let relevanceScore: Double
    let sourceContext: String
}

// MARK: - Errors

enum PivotGeneratorError: Error, LocalizedError {
    case invalidResponse
    case apiError(String)
    case parsingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Received invalid response from pivot generation"
        case .apiError(let message):
            return "API error: \(message)"
        case .parsingFailed(let error):
            return "Failed to parse pivot suggestions: \(error.localizedDescription)"
        }
    }
}

// MARK: - OpenAI Client Protocol

/// Protocol for OpenAI API interactions (to be implemented by API client layer)
protocol OpenAIClient: Sendable {
    func sendChatCompletion(messages: [ChatMessage], responseFormat: ResponseFormat) async throws -> String
}

enum ChatMessage {
    case system(content: String)
    case user(content: String)
    case assistant(content: String)
}

enum ResponseFormat {
    case text
    case json
}
