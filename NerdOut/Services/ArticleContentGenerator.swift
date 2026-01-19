import Foundation

/// Generates article content (text and sections) using OpenAI's ChatGPT API
actor ArticleContentGenerator {

    private let apiClient: OpenAIAPIClient

    init(apiClient: OpenAIAPIClient) {
        self.apiClient = apiClient
    }

    /// Generates article content for a given topic pivot
    /// - Parameters:
    ///   - pivot: The topic pivot to generate an article for
    ///   - category: The topic category for style hints
    ///   - sophisticationLevel: User's knowledge level (1-5)
    /// - Returns: Generated article content with sections
    func generateArticleContent(
        pivot: TopicPivot,
        category: TopicCategory,
        sophisticationLevel: Int
    ) async throws -> GeneratedArticleContent {
        let prompt = buildArticlePrompt(
            pivotTitle: pivot.title,
            pivotDescription: pivot.description,
            category: category,
            sophisticationLevel: sophisticationLevel
        )

        let response = try await apiClient.sendChatCompletion(
            messages: [
                ChatMessage(role: .system, content: systemPrompt),
                ChatMessage(role: .user, content: prompt)
            ],
            responseFormat: .json
        )

        return try parseResponse(response)
    }

    // MARK: - Private

    private var systemPrompt: String {
        """
        You are an expert educational content writer for the NerdOut learning app. \
        Your articles should be engaging, informative, and tailored to the reader's \
        knowledge level. Articles should feel like a fascinating conversation with \
        a knowledgeable friend, not a textbook.

        Writing guidelines:
        1. Use clear, accessible language appropriate to the sophistication level
        2. Include interesting facts, examples, and connections
        3. Structure content into 3-5 logical sections with clear headings
        4. Each section should be 100-200 words
        5. Total article length: 500-1000 words
        6. Make concepts concrete through analogies and real-world examples
        7. End with something thought-provoking that invites further exploration

        Always respond with valid JSON matching the specified schema.
        """
    }

    private func buildArticlePrompt(
        pivotTitle: String,
        pivotDescription: String,
        category: TopicCategory,
        sophisticationLevel: Int
    ) -> String {
        let levelDescription = sophisticationDescription(sophisticationLevel)
        let styleGuide = categoryWritingStyle(for: category)

        return """
        Generate an educational article about the following topic.

        ## Topic
        Title: \(pivotTitle)
        Description: \(pivotDescription)

        ## Context
        - Category: \(category.rawValue)
        - Reader sophistication level: \(levelDescription)

        ## Style Guidelines
        \(styleGuide)

        ## Required JSON Response Format
        {
            "title": "Engaging article title",
            "summary": "2-3 sentence summary for preview cards",
            "sections": [
                {
                    "heading": "Section heading",
                    "content": "Section content (100-200 words)",
                    "imageDescription": "Brief description of an ideal illustration for this section"
                }
            ],
            "estimatedReadingTime": 5,
            "heroImageDescription": "Description of an ideal hero image that captures the article's essence"
        }

        Requirements:
        - Generate 3-5 sections
        - Total content should be 500-1000 words
        - Make the title engaging and specific
        - imageDescription should describe a visual that would enhance understanding
        - heroImageDescription should describe a striking visual for the article header
        """
    }

    private func sophisticationDescription(_ level: Int) -> String {
        switch level {
        case 1: return "Complete beginner - explain everything simply, no jargon"
        case 2: return "Novice - basic awareness, needs gentle introductions"
        case 3: return "Intermediate - comfortable with fundamentals"
        case 4: return "Advanced - can handle nuance and complexity"
        case 5: return "Expert - appreciates deep dives and technical details"
        default: return "General audience"
        }
    }

    private func categoryWritingStyle(for category: TopicCategory) -> String {
        switch category {
        case .sports:
            return """
            - Use dynamic, energetic language
            - Include statistics and records where relevant
            - Reference memorable moments and athletes
            - Connect to broader themes of competition and excellence
            """
        case .music:
            return """
            - Use rhythmic, flowing prose
            - Reference specific pieces, artists, or traditions
            - Connect to emotional and cultural significance
            - Include technical terms with clear explanations
            """
        case .science:
            return """
            - Emphasize the process of discovery
            - Use clear explanations of complex concepts
            - Include real-world applications
            - Connect to the wonder of understanding nature
            """
        case .history:
            return """
            - Bring historical figures and events to life
            - Connect past to present
            - Include specific dates and context
            - Emphasize cause and effect relationships
            """
        case .literature:
            return """
            - Use rich, descriptive language
            - Reference specific works and authors
            - Explore themes and interpretations
            - Connect to universal human experiences
            """
        case .technology:
            return """
            - Balance technical accuracy with accessibility
            - Include practical applications
            - Reference the evolution of technology
            - Connect to impact on daily life
            """
        case .arts:
            return """
            - Use vivid, descriptive language
            - Reference specific works and artists
            - Explore techniques and movements
            - Connect to cultural and emotional significance
            """
        case .philosophy:
            return """
            - Present ideas clearly and fairly
            - Use thought experiments and examples
            - Connect to everyday relevance
            - Acknowledge complexity and competing views
            """
        case .other:
            return """
            - Use clear, engaging language
            - Include specific examples
            - Connect to broader themes
            - Make abstract concepts concrete
            """
        }
    }

    private func parseResponse(_ response: String) throws -> GeneratedArticleContent {
        guard let data = response.data(using: .utf8) else {
            throw ArticleContentError.invalidResponse
        }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(GeneratedArticleContent.self, from: data)
        } catch {
            throw ArticleContentError.parsingFailed(error)
        }
    }
}

// MARK: - Generated Content Models

/// Content generated by ArticleContentGenerator
struct GeneratedArticleContent: Codable {
    let title: String
    let summary: String
    let sections: [GeneratedSection]
    let estimatedReadingTime: Int
    let heroImageDescription: String
}

/// A section of generated article content
struct GeneratedSection: Codable {
    let heading: String
    let content: String
    let imageDescription: String
}

// MARK: - Errors

enum ArticleContentError: Error, LocalizedError {
    case invalidResponse
    case parsingFailed(Error)
    case contentTooShort
    case contentTooLong

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from article content generation"
        case .parsingFailed(let error):
            return "Failed to parse article content: \(error.localizedDescription)"
        case .contentTooShort:
            return "Generated content is too short"
        case .contentTooLong:
            return "Generated content is too long"
        }
    }
}
