import Foundation

/// OpenAI API endpoints
enum OpenAIEndpoint: APIEndpoint {
    case chatCompletion(request: ChatCompletionRequest)
    case imageGeneration(request: ImageGenerationRequest)

    var baseURL: String {
        APIConfiguration.OpenAI.baseURL
    }

    var path: String {
        switch self {
        case .chatCompletion:
            return "/chat/completions"
        case .imageGeneration:
            return "/images/generations"
        }
    }

    var method: HTTPMethod {
        .post
    }

    var headers: [String: String] {
        [
            "Content-Type": ContentType.json.rawValue,
            "Authorization": "Bearer \(APIConfiguration.OpenAI.apiKey)"
        ]
    }

    var body: Encodable? {
        switch self {
        case .chatCompletion(let request):
            return request
        case .imageGeneration(let request):
            return request
        }
    }

    var timeout: TimeInterval {
        APIConfiguration.Network.generationTimeout
    }
}

// MARK: - Request Models

/// Chat completion request structure
struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let maxTokens: Int?
    let temperature: Double?
    let topP: Double?
    let n: Int?
    let stream: Bool?
    let stop: [String]?

    init(
        model: String = APIConfiguration.OpenAI.defaultModel,
        messages: [ChatMessage],
        maxTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        n: Int? = 1,
        stream: Bool? = false,
        stop: [String]? = nil
    ) {
        self.model = model
        self.messages = messages
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.topP = topP
        self.n = n
        self.stream = stream
        self.stop = stop
    }
}

/// Chat message structure
struct ChatMessage: Codable {
    let role: Role
    let content: String

    enum Role: String, Codable {
        case system
        case user
        case assistant
    }

    static func system(_ content: String) -> ChatMessage {
        ChatMessage(role: .system, content: content)
    }

    static func user(_ content: String) -> ChatMessage {
        ChatMessage(role: .user, content: content)
    }

    static func assistant(_ content: String) -> ChatMessage {
        ChatMessage(role: .assistant, content: content)
    }
}

/// Image generation request structure
struct ImageGenerationRequest: Encodable {
    let model: String
    let prompt: String
    let n: Int
    let size: String
    let quality: String?

    init(
        model: String = APIConfiguration.OpenAI.imageModel,
        prompt: String,
        n: Int = 1,
        size: String = "1024x1024",
        quality: String? = "standard"
    ) {
        self.model = model
        self.prompt = prompt
        self.n = n
        self.size = size
        self.quality = quality
    }
}

// MARK: - Response Models

/// Chat completion response structure
struct ChatCompletionResponse: Decodable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage?

    struct Choice: Decodable {
        let index: Int
        let message: ChatMessage
        let finishReason: String?
    }

    struct Usage: Decodable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
    }

    /// Convenience accessor for the first message content
    var content: String? {
        choices.first?.message.content
    }
}

/// Image generation response structure
struct ImageGenerationResponse: Decodable {
    let created: Int
    let data: [ImageData]

    struct ImageData: Decodable {
        let url: String?
        let b64Json: String?
        let revisedPrompt: String?
    }

    /// Convenience accessor for the first image URL
    var imageURL: String? {
        data.first?.url
    }
}
