import Foundation

/// Protocol for OpenAI service operations
protocol OpenAIServiceProtocol {
    func generateClarifyingQuestions(for topic: String) async throws -> [String]
    func generateLevelSettingQuestions(for topic: String) async throws -> [String]
    func generateTopicOverview(topic: String, clarifications: [String], level: String) async throws -> TopicOverview
    func generateArticle(for pivot: String, context: ArticleContext) async throws -> GeneratedArticle
    func generatePivots(from articleContent: String, topic: String) async throws -> [String]
    func generateHeroImage(for title: String, topic: String) async throws -> String
}

/// OpenAI service for NerdOut content generation
final class OpenAIService: OpenAIServiceProtocol {
    private let client: APIClientProtocol

    /// Shared singleton instance
    static let shared = OpenAIService()

    init(client: APIClientProtocol = APIClient.shared) {
        self.client = client
    }

    // MARK: - Clarifying Questions

    /// Generate 2-3 clarifying questions about what the user wants to learn
    func generateClarifyingQuestions(for topic: String) async throws -> [String] {
        let systemPrompt = """
        You are helping a user learn about a topic. Generate 2-3 clarifying questions to understand \
        exactly what aspect of the topic they want to explore. Questions should help narrow down \
        their specific interests within the broader topic.

        Return only the questions, one per line, without numbering or bullet points.
        """

        let request = ChatCompletionRequest(
            messages: [
                .system(systemPrompt),
                .user("I want to learn about: \(topic)")
            ],
            maxTokens: APIConfiguration.OpenAI.clarifyingMaxTokens,
            temperature: APIConfiguration.OpenAI.factualTemperature
        )

        let response: ChatCompletionResponse = try await client.request(
            OpenAIEndpoint.chatCompletion(request: request)
        )

        guard let content = response.content else {
            throw APIError.emptyResponse
        }

        return content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Level Setting

    /// Generate questions to gauge user's familiarity with the topic
    func generateLevelSettingQuestions(for topic: String) async throws -> [String] {
        let systemPrompt = """
        Generate 2-3 questions to understand the user's current knowledge level about a topic. \
        These are NOT quiz questions - they are friendly questions to gauge familiarity. \
        Examples: "Have you read about X before?", "Are you familiar with the basics of Y?"

        Return only the questions, one per line, without numbering or bullet points.
        """

        let request = ChatCompletionRequest(
            messages: [
                .system(systemPrompt),
                .user("Topic: \(topic)")
            ],
            maxTokens: APIConfiguration.OpenAI.clarifyingMaxTokens,
            temperature: APIConfiguration.OpenAI.factualTemperature
        )

        let response: ChatCompletionResponse = try await client.request(
            OpenAIEndpoint.chatCompletion(request: request)
        )

        guard let content = response.content else {
            throw APIError.emptyResponse
        }

        return content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Topic Overview

    /// Generate a topic overview with learning path based on user responses
    func generateTopicOverview(
        topic: String,
        clarifications: [String],
        level: String
    ) async throws -> TopicOverview {
        let systemPrompt = """
        Create a learning overview for the user based on their topic interest and knowledge level.

        Return a JSON object with this structure:
        {
            "title": "Engaging title for the learning topic",
            "summary": "2-3 sentence summary of what they'll learn",
            "category": "One of: Sports, Music, Science, History, Literature, Technology, Art, Other",
            "initialPivots": ["First article topic", "Second article topic", "Third article topic"]
        }

        The initialPivots should be 3 specific article topics that form a good starting learning path.
        """

        let userMessage = """
        Topic: \(topic)
        User's clarifications: \(clarifications.joined(separator: "; "))
        Knowledge level: \(level)
        """

        let request = ChatCompletionRequest(
            messages: [
                .system(systemPrompt),
                .user(userMessage)
            ],
            maxTokens: 500,
            temperature: APIConfiguration.OpenAI.creativeTemperature
        )

        let response: ChatCompletionResponse = try await client.request(
            OpenAIEndpoint.chatCompletion(request: request)
        )

        guard let content = response.content else {
            throw APIError.emptyResponse
        }

        return try parseTopicOverview(from: content)
    }

    // MARK: - Article Generation

    /// Generate a 500-1000 word article on a topic pivot
    func generateArticle(for pivot: String, context: ArticleContext) async throws -> GeneratedArticle {
        let systemPrompt = """
        Write an engaging, educational article (500-1000 words) on the given topic.

        Style guidelines:
        - Write for a \(context.level) audience
        - Use clear, accessible language
        - Include interesting facts and examples
        - Break into logical sections with headers
        - End with a thought-provoking insight

        Return a JSON object:
        {
            "title": "Article title",
            "content": "Full article content with markdown formatting",
            "imagePrompt": "Detailed prompt for generating a hero image (describe visual scene, style, mood)"
        }
        """

        let userMessage = """
        Write about: \(pivot)
        Broader topic context: \(context.topicTitle)
        """

        let request = ChatCompletionRequest(
            messages: [
                .system(systemPrompt),
                .user(userMessage)
            ],
            maxTokens: APIConfiguration.OpenAI.articleMaxTokens,
            temperature: APIConfiguration.OpenAI.creativeTemperature
        )

        let response: ChatCompletionResponse = try await client.request(
            OpenAIEndpoint.chatCompletion(request: request)
        )

        guard let content = response.content else {
            throw APIError.emptyResponse
        }

        return try parseGeneratedArticle(from: content)
    }

    // MARK: - Pivot Generation

    /// Generate related topic suggestions for rabbit-holing
    func generatePivots(from articleContent: String, topic: String) async throws -> [String] {
        let systemPrompt = """
        Based on the article content, suggest 3-5 related topics the reader might want to explore next. \
        These should enable natural "rabbit-holing" - going deeper into interesting tangents.

        Return only the topics, one per line, without numbering or bullet points.
        Each topic should be specific enough for a focused article.
        """

        let request = ChatCompletionRequest(
            messages: [
                .system(systemPrompt),
                .user("Article topic: \(topic)\n\nContent:\n\(articleContent.prefix(2000))")
            ],
            maxTokens: 300,
            temperature: APIConfiguration.OpenAI.creativeTemperature
        )

        let response: ChatCompletionResponse = try await client.request(
            OpenAIEndpoint.chatCompletion(request: request)
        )

        guard let content = response.content else {
            throw APIError.emptyResponse
        }

        return content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Image Generation

    /// Generate a hero image for an article
    func generateHeroImage(for title: String, topic: String) async throws -> String {
        let prompt = """
        Create a visually striking hero image for an educational article.
        Topic: \(topic)
        Article: \(title)

        Style: Modern, clean, engaging. Suitable for a learning app.
        No text in the image.
        """

        let request = ImageGenerationRequest(prompt: prompt)

        let response: ImageGenerationResponse = try await client.request(
            OpenAIEndpoint.imageGeneration(request: request)
        )

        guard let imageURL = response.imageURL else {
            throw APIError.emptyResponse
        }

        return imageURL
    }

    // MARK: - Private Parsing Methods

    private func parseTopicOverview(from content: String) throws -> TopicOverview {
        guard let data = extractJSON(from: content)?.data(using: .utf8) else {
            throw APIError.decodingFailed(
                NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to extract JSON"])
            )
        }

        let decoder = JSONDecoder()
        return try decoder.decode(TopicOverview.self, from: data)
    }

    private func parseGeneratedArticle(from content: String) throws -> GeneratedArticle {
        guard let data = extractJSON(from: content)?.data(using: .utf8) else {
            throw APIError.decodingFailed(
                NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to extract JSON"])
            )
        }

        let decoder = JSONDecoder()
        return try decoder.decode(GeneratedArticle.self, from: data)
    }

    private func extractJSON(from text: String) -> String? {
        // Find JSON object in response (handles markdown code blocks)
        let patterns = [
            "```json\\s*([\\s\\S]*?)```",
            "```\\s*([\\s\\S]*?)```",
            "(\\{[\\s\\S]*\\})"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range])
            }
        }

        return nil
    }
}

// MARK: - Support Types

/// Context for article generation
struct ArticleContext {
    let topicTitle: String
    let level: String

    static func beginner(topic: String) -> ArticleContext {
        ArticleContext(topicTitle: topic, level: "beginner")
    }

    static func intermediate(topic: String) -> ArticleContext {
        ArticleContext(topicTitle: topic, level: "intermediate")
    }

    static func advanced(topic: String) -> ArticleContext {
        ArticleContext(topicTitle: topic, level: "advanced")
    }
}

/// Generated topic overview from OpenAI
struct TopicOverview: Decodable {
    let title: String
    let summary: String
    let category: String
    let initialPivots: [String]
}

/// Generated article from OpenAI
struct GeneratedArticle: Decodable {
    let title: String
    let content: String
    let imagePrompt: String
}
