import Foundation

/// Generates related topic suggestions for rabbit-holing based on article content.
///
/// The PivotGenerator analyzes article content and generates suggestions for related
/// topics that users might want to explore. These suggestions enable "rabbit-holing" -
/// the delightful experience of following curiosity from one interesting topic to another.
actor PivotGenerator {

    private let apiClient: OpenAIAPIClient
    private let maxSuggestions: Int

    /// Creates a new PivotGenerator
    /// - Parameters:
    ///   - apiClient: The OpenAI API client for ChatGPT requests
    ///   - maxSuggestions: Maximum number of pivot suggestions to generate (default: 5)
    init(apiClient: OpenAIAPIClient, maxSuggestions: Int = 5) {
        self.apiClient = apiClient
        self.maxSuggestions = maxSuggestions
    }

    /// Generates pivot suggestions based on article content
    /// - Parameter articleContent: The article content to analyze
    /// - Returns: A result containing pivot suggestions and extracted concepts
    func generatePivots(from articleContent: ArticleContent) async throws -> PivotSuggestionResult {
        let prompt = buildPrompt(from: articleContent)

        let response = try await apiClient.sendChatCompletion(
            messages: [
                ChatMessage(role: .system, content: systemPrompt),
                ChatMessage(role: .user, content: prompt)
            ],
            responseFormat: .json
        )

        let apiResponse = try parseResponse(response)
        return buildPivotSuggestionResult(from: apiResponse)
    }

    // MARK: - Private

    private var systemPrompt: String {
        """
        You are an expert at finding fascinating connections between topics for the \
        NerdOut learning app. Your role is to suggest related topics that will spark \
        curiosity and enable delightful "rabbit-holing" - the experience of following \
        one's curiosity from topic to topic.

        When generating pivot suggestions:
        1. Identify the core concepts and themes in the article
        2. Find genuinely interesting connections - not obvious or superficial ones
        3. Balance between going deeper, exploring tangents, and zooming out
        4. Match suggestions to the user's sophistication level
        5. Make hooks compelling - explain why someone would want to learn this
        6. Ensure connection reasons show clear relevance to the source article

        Aim for a mix of:
        - 1-2 "deeper" pivots that explore specific aspects in more detail
        - 2-3 "tangent" pivots that branch into fascinating related areas
        - 1 "broader" pivot that provides wider context

        Always respond with valid JSON matching the specified schema.
        """
    }

    private func buildPrompt(from content: ArticleContent) -> String {
        let sophisticationDesc = sophisticationDescription(content.userSophisticationLevel)
        let coveredList = content.coveredConcepts.isEmpty
            ? "None specified"
            : content.coveredConcepts.joined(separator: ", ")

        return """
        Generate \(maxSuggestions) pivot suggestions for rabbit-holing based on this article.

        ## Article Title
        \(content.title)

        ## Article Content
        \(content.bodyText)

        ## Context
        - Category: \(content.category.rawValue)
        - User sophistication level: \(sophisticationDesc)
        - Concepts already covered in learning path: \(coveredList)

        ## Requirements
        - Suggest topics NOT already in the covered concepts list
        - Match complexity to sophistication level \(content.userSophisticationLevel)/5
        - Make hooks engaging and specific to what makes each topic fascinating
        - Explain clearly how each suggestion connects to the source article

        ## Required JSON Response Format
        {
            "suggestions": [
                {
                    "title": "Engaging topic title",
                    "hook": "1-2 sentences explaining why this is fascinating",
                    "connectionReason": "How this relates to the article they just read",
                    "suggestedCategory": "Sports|Music|Science|History|Literature|Technology|Arts|Philosophy|Other",
                    "relevanceScore": 0.85,
                    "depthType": "deeper|tangent|broader"
                }
            ],
            "extractedConcepts": ["concept1", "concept2", "concept3"]
        }

        Notes:
        - relevanceScore is 0-1 (how strongly connected to source article)
        - extractedConcepts are the key ideas you identified in the article
        - Order suggestions by relevanceScore descending
        """
    }

    private func sophisticationDescription(_ level: Int) -> String {
        switch level {
        case 1: return "Complete beginner - explain everything simply"
        case 2: return "Novice - basic awareness, needs gentle introductions"
        case 3: return "Intermediate - comfortable with fundamentals"
        case 4: return "Advanced - can handle nuance and complexity"
        case 5: return "Expert - appreciates deep dives and edge cases"
        default: return "Unknown"
        }
    }

    private func parseResponse(_ response: String) throws -> PivotGenerationAPIResponse {
        guard let data = response.data(using: .utf8) else {
            throw PivotGenerationError.invalidResponse
        }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(PivotGenerationAPIResponse.self, from: data)
        } catch {
            throw PivotGenerationError.parsingFailed(error)
        }
    }

    private func buildPivotSuggestionResult(
        from apiResponse: PivotGenerationAPIResponse
    ) -> PivotSuggestionResult {
        let suggestions = apiResponse.suggestions.map { suggestionResponse in
            let category = TopicCategory(rawValue: suggestionResponse.suggestedCategory) ?? .other
            let depthType = PivotDepthType(rawValue: suggestionResponse.depthType) ?? .tangent

            return PivotSuggestion(
                id: UUID(),
                title: suggestionResponse.title,
                hook: suggestionResponse.hook,
                connectionReason: suggestionResponse.connectionReason,
                suggestedCategory: category,
                relevanceScore: min(max(suggestionResponse.relevanceScore, 0), 1),
                depthType: depthType
            )
        }

        return PivotSuggestionResult(
            suggestions: suggestions,
            extractedConcepts: apiResponse.extractedConcepts
        )
    }
}

// MARK: - Errors

enum PivotGenerationError: Error, LocalizedError {
    case invalidResponse
    case parsingFailed(Error)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Received invalid response from pivot generation service"
        case .parsingFailed(let error):
            return "Failed to parse pivot generation response: \(error.localizedDescription)"
        case .apiError(let message):
            return "Pivot generation API error: \(message)"
        }
    }
}
