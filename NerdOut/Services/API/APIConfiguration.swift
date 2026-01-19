import Foundation

/// API configuration and environment settings
struct APIConfiguration {
    /// OpenAI API configuration
    struct OpenAI {
        /// API key loaded from environment or Keychain
        static var apiKey: String {
            // First check environment (for development)
            if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
                return envKey
            }
            // In production, load from Keychain via AuthService
            // This will be integrated when Auth module is available
            return ""
        }

        /// Base URL for OpenAI API
        static let baseURL = "https://api.openai.com/v1"

        /// Default model for chat completions
        static let defaultModel = "gpt-4o"

        /// Model for generating images
        static let imageModel = "gpt-image-1"

        /// Maximum tokens for article generation
        static let articleMaxTokens = 2000

        /// Maximum tokens for clarifying questions
        static let clarifyingMaxTokens = 500

        /// Temperature for creative content
        static let creativeTemperature = 0.8

        /// Temperature for factual content
        static let factualTemperature = 0.3
    }

    /// Supabase configuration
    struct Supabase {
        static var url: String {
            ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
        }

        static var anonKey: String {
            ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
        }
    }

    /// Network configuration
    struct Network {
        /// Default request timeout in seconds
        static let requestTimeout: TimeInterval = 30.0

        /// Extended timeout for AI generation requests
        static let generationTimeout: TimeInterval = 120.0

        /// Maximum retry attempts for retryable errors
        static let maxRetryAttempts = 3

        /// Base delay for exponential backoff (seconds)
        static let retryBaseDelay: TimeInterval = 1.0
    }
}

/// HTTP method enumeration
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Content types for API requests
enum ContentType: String {
    case json = "application/json"
    case formData = "multipart/form-data"
}
