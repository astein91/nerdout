import Foundation

// MARK: - Image Generation Request Models

/// Configuration for generating an image with OpenAI's GPT Image API
struct ImageGenerationRequest: Codable {
    /// The model to use for image generation
    let model: ImageModel

    /// Text prompt describing the desired image (max 32000 characters for GPT image models)
    let prompt: String

    /// Image dimensions
    let size: ImageSize

    /// Quality level of generated image
    let quality: ImageQuality

    /// Number of images to generate (1-10, typically 1 for GPT image models)
    let n: Int

    /// Output format for the generated image
    let outputFormat: ImageOutputFormat

    /// Background transparency setting
    let background: ImageBackground

    /// Content moderation level
    let moderation: ImageModeration

    enum CodingKeys: String, CodingKey {
        case model, prompt, size, quality, n
        case outputFormat = "output_format"
        case background, moderation
    }

    init(
        model: ImageModel = .gptImage1,
        prompt: String,
        size: ImageSize = .square1024,
        quality: ImageQuality = .medium,
        n: Int = 1,
        outputFormat: ImageOutputFormat = .png,
        background: ImageBackground = .opaque,
        moderation: ImageModeration = .auto
    ) {
        self.model = model
        self.prompt = prompt
        self.size = size
        self.quality = quality
        self.n = n
        self.outputFormat = outputFormat
        self.background = background
        self.moderation = moderation
    }
}

/// Available image generation models
enum ImageModel: String, Codable {
    /// GPT Image 1 - Primary recommended model (April 2025+)
    case gptImage1 = "gpt-image-1"

    /// GPT Image 1 Mini - Faster, lower cost variant
    case gptImage1Mini = "gpt-image-1-mini"

    /// GPT Image 1.5 - Latest model with enhanced capabilities
    case gptImage15 = "gpt-image-1.5"
}

/// Available image sizes for GPT Image models
enum ImageSize: String, Codable {
    /// 1024x1024 square format
    case square1024 = "1024x1024"

    /// 1536x1024 landscape format (ideal for hero images)
    case landscape = "1536x1024"

    /// 1024x1536 portrait format
    case portrait = "1024x1536"

    /// Let the model determine optimal size
    case auto = "auto"
}

/// Image quality levels
enum ImageQuality: String, Codable {
    /// Low quality - fastest, lowest cost (~$0.02/image)
    case low

    /// Medium quality - balanced (~$0.07/image)
    case medium

    /// High quality - best results (~$0.19/image)
    case high
}

/// Output format for generated images
enum ImageOutputFormat: String, Codable {
    case png
    case jpeg
    case webp
}

/// Background transparency options
enum ImageBackground: String, Codable {
    /// Transparent background (requires PNG or WebP format)
    case transparent

    /// Solid background
    case opaque

    /// Let model decide
    case auto
}

/// Content moderation strictness
enum ImageModeration: String, Codable {
    /// Standard filtering for age-appropriate content
    case auto

    /// Less restrictive filtering
    case low
}

// MARK: - Image Generation Response Models

/// Response from OpenAI Image Generation API
struct ImageGenerationResponse: Codable {
    /// Unix timestamp when the image was created
    let created: Int

    /// Background setting used
    let background: String?

    /// Array of generated images
    let data: [GeneratedImageData]

    /// Output format used
    let outputFormat: String?

    /// Quality level used
    let quality: String?

    /// Size of generated images
    let size: String?

    /// Token usage for this request
    let usage: ImageGenerationUsage?

    enum CodingKeys: String, CodingKey {
        case created, background, data
        case outputFormat = "output_format"
        case quality, size, usage
    }
}

/// Individual generated image data
struct GeneratedImageData: Codable {
    /// URL to download the image (valid for 60 minutes)
    let url: String?

    /// Base64-encoded image data (used by GPT Image models)
    let b64Json: String?

    /// Revised prompt if the model modified it
    let revisedPrompt: String?

    enum CodingKeys: String, CodingKey {
        case url
        case b64Json = "b64_json"
        case revisedPrompt = "revised_prompt"
    }
}

/// Token usage information for image generation
struct ImageGenerationUsage: Codable {
    let inputTokens: Int
    let outputTokens: Int
    let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Article Image Models

/// Represents an image associated with an article
struct ArticleImage: Codable, Identifiable {
    let id: UUID

    /// The image type (hero or embedded)
    let imageType: ArticleImageType

    /// Base64-encoded image data
    let imageData: String

    /// The prompt used to generate this image
    let generationPrompt: String

    /// Image format
    let format: ImageOutputFormat

    /// Image dimensions
    let size: ImageSize

    /// Position in article (for embedded images)
    let position: Int?

    /// Alt text for accessibility
    let altText: String

    /// When the image was generated
    let createdAt: Date

    init(
        id: UUID = UUID(),
        imageType: ArticleImageType,
        imageData: String,
        generationPrompt: String,
        format: ImageOutputFormat = .png,
        size: ImageSize,
        position: Int? = nil,
        altText: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.imageType = imageType
        self.imageData = imageData
        self.generationPrompt = generationPrompt
        self.format = format
        self.size = size
        self.position = position
        self.altText = altText
        self.createdAt = createdAt
    }
}

/// Type of image in an article
enum ArticleImageType: String, Codable {
    /// Hero image displayed at the top of the article
    case hero

    /// Embedded image within the article content
    case embedded
}

/// Collection of images for an article
struct ArticleImageSet: Codable {
    /// The hero image for the article
    let heroImage: ArticleImage?

    /// Embedded images within the article content
    let embeddedImages: [ArticleImage]

    /// Total number of images
    var imageCount: Int {
        (heroImage != nil ? 1 : 0) + embeddedImages.count
    }

    init(heroImage: ArticleImage? = nil, embeddedImages: [ArticleImage] = []) {
        self.heroImage = heroImage
        self.embeddedImages = embeddedImages
    }
}
