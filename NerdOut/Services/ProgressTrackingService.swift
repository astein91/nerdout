import Foundation

enum ProgressTrackingError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case serverError(String)
    case notAuthenticated
    case encodingError
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let message):
            return message
        case .notAuthenticated:
            return "User not authenticated"
        case .encodingError:
            return "Failed to encode request data"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        }
    }
}

/// Service for tracking reading progress and syncing with Supabase backend
actor ProgressTrackingService {
    static let shared = ProgressTrackingService()

    private let urlSession: URLSession
    private var cachedStats: [CategoryStats] = []
    private var cachedSummary: UserProgressSummary?
    private var pendingProgress: [ReadingProgress] = []

    private var supabaseURL: String {
        ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
    }

    private var supabaseAnonKey: String {
        ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
    }

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.urlSession = URLSession(configuration: config)
    }

    // MARK: - Public API

    /// Record that an article was read
    func recordArticleRead(
        userId: String,
        articleId: String,
        topicId: String,
        category: Category,
        durationSeconds: Int? = nil
    ) async throws {
        let progress = ReadingProgress(
            userId: userId,
            articleId: articleId,
            topicId: topicId,
            category: category,
            readDurationSeconds: durationSeconds
        )

        do {
            try await persistProgress(progress)
            await updateLocalCache(with: progress)
        } catch {
            pendingProgress.append(progress)
            throw error
        }
    }

    /// Get category statistics for the current user
    func getCategoryStats(userId: String, accessToken: String) async throws -> [CategoryStats] {
        let stats = try await fetchCategoryStats(userId: userId, accessToken: accessToken)
        cachedStats = stats
        return stats
    }

    /// Get user progress summary
    func getProgressSummary(userId: String, accessToken: String) async throws -> UserProgressSummary {
        let progressRecords = try await fetchAllProgress(userId: userId, accessToken: accessToken)

        let now = Date()
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now

        var categoryBreakdown: [Category: Int] = [:]
        var articlesThisWeek = 0
        var lastRead: Date?

        for record in progressRecords {
            categoryBreakdown[record.category, default: 0] += 1

            if record.readAt >= weekAgo {
                articlesThisWeek += 1
            }

            if lastRead == nil || record.readAt > lastRead! {
                lastRead = record.readAt
            }
        }

        let summary = UserProgressSummary(
            userId: userId,
            totalArticlesRead: progressRecords.count,
            articlesReadThisWeek: articlesThisWeek,
            categoryBreakdown: categoryBreakdown,
            lastReadAt: lastRead
        )

        cachedSummary = summary
        return summary
    }

    /// Sync any pending offline progress to the backend
    func syncPendingProgress(accessToken: String) async throws {
        guard !pendingProgress.isEmpty else { return }

        var failedSyncs: [ReadingProgress] = []

        for progress in pendingProgress {
            do {
                try await persistProgress(progress, accessToken: accessToken)
            } catch {
                failedSyncs.append(progress)
            }
        }

        pendingProgress = failedSyncs

        if !failedSyncs.isEmpty {
            throw ProgressTrackingError.serverError("Failed to sync \(failedSyncs.count) progress records")
        }
    }

    /// Check if an article has been read
    func hasArticleBeenRead(
        userId: String,
        articleId: String,
        accessToken: String
    ) async throws -> Bool {
        let url = try buildURL(
            path: "/rest/v1/reading_progress",
            queryItems: [
                URLQueryItem(name: "user_id", value: "eq.\(userId)"),
                URLQueryItem(name: "article_id", value: "eq.\(articleId)"),
                URLQueryItem(name: "select", value: "id"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addHeaders(to: &request, accessToken: accessToken)

        let (data, response) = try await performRequest(request)
        try validateResponse(response, data: data)

        let records = try JSONDecoder().decode([ProgressResponse].self, from: data)
        return !records.isEmpty
    }

    /// Get cached stats without network request
    func getCachedStats() -> [CategoryStats] {
        return cachedStats
    }

    /// Get cached summary without network request
    func getCachedSummary() -> UserProgressSummary? {
        return cachedSummary
    }

    /// Clear local cache
    func clearCache() {
        cachedStats = []
        cachedSummary = nil
    }

    // MARK: - Private Methods

    private func persistProgress(_ progress: ReadingProgress, accessToken: String? = nil) async throws {
        let token = accessToken ?? getStoredAccessToken()
        guard let validToken = token else {
            throw ProgressTrackingError.notAuthenticated
        }

        let url = try buildURL(path: "/rest/v1/reading_progress")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("return=representation", forHTTPHeaderField: "Prefer")
        addHeaders(to: &request, accessToken: validToken)

        let createRequest = CreateProgressRequest(from: progress)
        request.httpBody = try JSONEncoder().encode(createRequest)

        let (data, response) = try await performRequest(request)
        try validateResponse(response, data: data)
    }

    private func fetchCategoryStats(userId: String, accessToken: String) async throws -> [CategoryStats] {
        // Fetch counts per category using Supabase RPC or grouping
        let url = try buildURL(
            path: "/rest/v1/rpc/get_category_stats",
            queryItems: [
                URLQueryItem(name: "p_user_id", value: userId)
            ]
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        addHeaders(to: &request, accessToken: accessToken)

        let body = ["p_user_id": userId]
        request.httpBody = try JSONEncoder().encode(body)

        do {
            let (data, response) = try await performRequest(request)
            try validateResponse(response, data: data)

            let statsResponse = try JSONDecoder().decode([CategoryStatsResponse].self, from: data)
            return statsResponse.compactMap { stat -> CategoryStats? in
                guard let category = Category(rawValue: stat.category) else { return nil }
                return CategoryStats(
                    category: category,
                    articlesRead: stat.count,
                    totalArticles: 0 // Will be filled by caller with total available articles
                )
            }
        } catch {
            // Fallback: fetch all and aggregate client-side
            return try await fetchAndAggregateStats(userId: userId, accessToken: accessToken)
        }
    }

    private func fetchAndAggregateStats(userId: String, accessToken: String) async throws -> [CategoryStats] {
        let progressRecords = try await fetchAllProgress(userId: userId, accessToken: accessToken)

        var categoryCounts: [Category: Int] = [:]
        for record in progressRecords {
            categoryCounts[record.category, default: 0] += 1
        }

        return Category.allCases.map { category in
            CategoryStats(
                category: category,
                articlesRead: categoryCounts[category] ?? 0,
                totalArticles: 0
            )
        }
    }

    private func fetchAllProgress(userId: String, accessToken: String) async throws -> [ReadingProgress] {
        let url = try buildURL(
            path: "/rest/v1/reading_progress",
            queryItems: [
                URLQueryItem(name: "user_id", value: "eq.\(userId)"),
                URLQueryItem(name: "order", value: "read_at.desc")
            ]
        )

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addHeaders(to: &request, accessToken: accessToken)

        let (data, response) = try await performRequest(request)
        try validateResponse(response, data: data)

        let progressResponses = try JSONDecoder().decode([ProgressResponse].self, from: data)
        return progressResponses.compactMap { $0.toReadingProgress() }
    }

    private func updateLocalCache(with progress: ReadingProgress) {
        // Update cached stats
        if let index = cachedStats.firstIndex(where: { $0.category == progress.category }) {
            let existing = cachedStats[index]
            cachedStats[index] = CategoryStats(
                id: existing.id,
                category: existing.category,
                articlesRead: existing.articlesRead + 1,
                totalArticles: existing.totalArticles
            )
        }

        // Update cached summary
        if var summary = cachedSummary, summary.userId == progress.userId {
            var breakdown = summary.categoryBreakdown
            breakdown[progress.category, default: 0] += 1

            let calendar = Calendar.current
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let wasThisWeek = progress.readAt >= weekAgo

            cachedSummary = UserProgressSummary(
                userId: summary.userId,
                totalArticlesRead: summary.totalArticlesRead + 1,
                articlesReadThisWeek: summary.articlesReadThisWeek + (wasThisWeek ? 1 : 0),
                categoryBreakdown: breakdown,
                lastReadAt: progress.readAt
            )
        }
    }

    private func getStoredAccessToken() -> String? {
        // This would integrate with KeychainService in the real app
        // For now, check environment or return nil
        return ProcessInfo.processInfo.environment["SUPABASE_ACCESS_TOKEN"]
    }

    // MARK: - Network Helpers

    private func buildURL(path: String, queryItems: [URLQueryItem]? = nil) throws -> URL {
        guard !supabaseURL.isEmpty else {
            throw ProgressTrackingError.invalidURL
        }

        var components = URLComponents(string: supabaseURL + path)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw ProgressTrackingError.invalidURL
        }

        return url
    }

    private func addHeaders(to request: inout URLRequest, accessToken: String) {
        request.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await urlSession.data(for: request)
        } catch {
            throw ProgressTrackingError.networkError(error)
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProgressTrackingError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: data, encoding: .utf8) {
                throw ProgressTrackingError.serverError(errorString)
            }
            throw ProgressTrackingError.serverError("Server returned status code \(httpResponse.statusCode)")
        }
    }
}
