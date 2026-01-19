import Foundation
import SwiftUI

/// ViewModel for managing article reading state and progress tracking
@MainActor
final class ArticleReaderViewModel: ObservableObject {
    // MARK: - Published State

    /// The article being displayed
    @Published private(set) var article: Article

    /// Loading state for async operations
    @Published private(set) var isLoading = false

    /// Error message if something goes wrong
    @Published private(set) var errorMessage: String?

    /// Reading progress (0.0 to 1.0)
    @Published var readingProgress: Double = 0

    /// Whether the article has been marked as read
    @Published private(set) var isMarkedAsRead = false

    /// Time when reading started (for tracking read duration)
    private var readingStartTime: Date?

    // MARK: - Initialization

    init(article: Article) {
        self.article = article
    }

    // MARK: - Reading Progress

    /// Called when the user starts reading the article
    func startReading() {
        readingStartTime = Date()
    }

    /// Called when scroll position changes to update reading progress
    /// - Parameter progress: The current scroll progress (0.0 to 1.0)
    func updateReadingProgress(_ progress: Double) {
        readingProgress = min(max(progress, 0), 1)

        // Auto-mark as read when user reaches 80% of content
        if progress >= 0.8 && !isMarkedAsRead {
            markAsRead()
        }
    }

    /// Explicitly marks the article as read
    func markAsRead() {
        guard !isMarkedAsRead else { return }

        isMarkedAsRead = true

        // Calculate read duration
        let readDuration: TimeInterval
        if let startTime = readingStartTime {
            readDuration = Date().timeIntervalSince(startTime)
        } else {
            readDuration = 0
        }

        // Log completion (would integrate with ProgressTrackingService)
        Task {
            await recordArticleCompletion(readDuration: readDuration)
        }
    }

    /// Called when the user exits the article view
    func endReading() {
        // Only record if they read a meaningful amount
        if readingProgress >= 0.2 && !isMarkedAsRead {
            // Record partial read (would integrate with analytics)
        }
    }

    // MARK: - Private Helpers

    private func recordArticleCompletion(readDuration: TimeInterval) async {
        // Integration point for ProgressTrackingService
        // This would call the progress tracking service to record the read
        // await progressTrackingService.recordArticleRead(
        //     articleId: article.id,
        //     topicId: article.topicId,
        //     readDuration: readDuration
        // )
    }
}

// MARK: - Article Metadata

extension ArticleReaderViewModel {
    /// Formatted reading time display
    var readingTimeText: String {
        if article.estimatedReadingTime == 1 {
            return "1 min read"
        }
        return "\(article.estimatedReadingTime) min read"
    }

    /// Formatted word count display
    var wordCountText: String {
        "\(article.wordCount) words"
    }

    /// Check if article has a hero image
    var hasHeroImage: Bool {
        article.heroImage != nil
    }

    /// Number of embedded images
    var embeddedImageCount: Int {
        article.embeddedImages.count
    }
}
