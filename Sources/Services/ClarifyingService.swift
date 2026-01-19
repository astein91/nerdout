import Foundation

enum ClarifyingServiceError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

actor ClarifyingService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4o"
    private let questionCount = 3

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func generateClarifyingQuestions(for userInput: String) async throws -> [ClarifyingQuestion] {
        guard let url = URL(string: baseURL) else {
            throw ClarifyingServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let systemPrompt = """
        You are helping a user learn about a topic. Based on their initial description of what they want to learn, generate exactly \(questionCount) clarifying questions to better understand:
        1. Their current knowledge level
        2. Specific aspects they're most interested in
        3. How they plan to apply this knowledge

        Return ONLY a JSON object with a "questions" array containing exactly \(questionCount) question strings.
        Example: {"questions": ["What is your current experience with X?", "Which aspect interests you most?", "How do you plan to use this knowledge?"]}
        """

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": "I want to learn about: \(userInput)"]
        ]

        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 500,
            "response_format": ["type": "json_object"]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClarifyingServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw ClarifyingServiceError.apiError(message)
            }
            throw ClarifyingServiceError.apiError("Status code: \(httpResponse.statusCode)")
        }

        let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)

        guard let content = chatResponse.choices.first?.message.content else {
            throw ClarifyingServiceError.invalidResponse
        }

        guard let contentData = content.data(using: .utf8) else {
            throw ClarifyingServiceError.invalidResponse
        }

        let clarifyingResponse = try JSONDecoder().decode(ClarifyingResponse.self, from: contentData)

        return clarifyingResponse.questions.map { ClarifyingQuestion(text: $0) }
    }
}

private struct ChatCompletionResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String
    }
}
