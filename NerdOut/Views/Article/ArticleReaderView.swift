import SwiftUI
import UIKit

/// Instant Article style reader view with hero image, embedded images, and clean typography
/// Designed for iOS 17+ with full-width hero image, serif typography, and embedded image support
struct ArticleReaderView: View {
    let article: Article

    @Environment(\.dismiss) private var dismiss
    @State private var scrollOffset: CGFloat = 0

    private let maxContentWidth: CGFloat = 680

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Hero image section
                    heroImageSection(geometry: geometry)

                    // Article content section
                    articleContent
                        .padding(.horizontal, contentPadding(for: geometry))
                        .padding(.top, 32)
                        .padding(.bottom, 48)
                        .frame(maxWidth: maxContentWidth)
                        .frame(maxWidth: .infinity)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Hero Image Section

    @ViewBuilder
    private func heroImageSection(geometry: GeometryProxy) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Hero image with parallax effect
            if let heroImage = article.heroImage {
                heroImageView(heroImage, geometry: geometry)
            } else {
                // Placeholder gradient when no hero image
                placeholderHeroGradient(geometry: geometry)
            }

            // Title overlay
            heroTitleOverlay(geometry: geometry)
        }
        .frame(height: heroImageHeight(for: geometry))
    }

    @ViewBuilder
    private func heroImageView(_ image: ArticleImage, geometry: GeometryProxy) -> some View {
        Group {
            if let imageData = image.imageData,
               let uiImage = decodeBase64Image(imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let imageURL = image.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        placeholderHeroGradient(geometry: geometry)
                            .overlay {
                                ProgressView()
                                    .tint(.white)
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderHeroGradient(geometry: geometry)
                    @unknown default:
                        placeholderHeroGradient(geometry: geometry)
                    }
                }
            } else {
                placeholderHeroGradient(geometry: geometry)
            }
        }
        .frame(width: geometry.size.width)
        .clipped()
        .accessibilityLabel(image.altText)
    }

    @ViewBuilder
    private func placeholderHeroGradient(geometry: GeometryProxy) -> some View {
        LinearGradient(
            colors: [.blue.opacity(0.8), .purple.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(width: geometry.size.width)
    }

    @ViewBuilder
    private func heroTitleOverlay(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Reading time badge
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.caption)
                Text("\(article.estimatedReadingTime) min read")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial.opacity(0.8), in: Capsule())

            // Title
            Text(article.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal, contentPadding(for: geometry))
        .padding(.bottom, 32)
        .frame(maxWidth: maxContentWidth, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Article Content

    @ViewBuilder
    private var articleContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Parse content into paragraphs and interleave with embedded images
            let paragraphs = parseParagraphs(from: article.content)

            ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, paragraph in
                // Render paragraph
                paragraphView(paragraph)

                // Check for embedded image after this paragraph
                if let embeddedImage = embeddedImage(afterParagraph: index) {
                    embeddedImageView(embeddedImage)
                        .padding(.vertical, 8)
                }
            }
        }
    }

    @ViewBuilder
    private func paragraphView(_ text: String) -> some View {
        Text(attributedText(from: text))
            .font(.body)
            .fontDesign(.serif)
            .lineSpacing(8)
            .foregroundStyle(.primary)
    }

    @ViewBuilder
    private func embeddedImageView(_ image: ArticleImage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let imageData = image.imageData,
                   let uiImage = decodeBase64Image(imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else if let imageURL = image.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .aspectRatio(16/9, contentMode: .fit)
                                .overlay { ProgressView() }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .aspectRatio(16/9, contentMode: .fit)
                                .overlay {
                                    Image(systemName: "photo")
                                        .foregroundStyle(.secondary)
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel(image.altText)

            // Caption
            if let caption = image.caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Helpers

    private func heroImageHeight(for geometry: GeometryProxy) -> CGFloat {
        min(geometry.size.height * 0.45, 400)
    }

    private func contentPadding(for geometry: GeometryProxy) -> CGFloat {
        let baseWidth = geometry.size.width
        if baseWidth > maxContentWidth + 48 {
            return (baseWidth - maxContentWidth) / 2
        }
        return 24
    }

    private func parseParagraphs(from content: String) -> [String] {
        content
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func embeddedImage(afterParagraph index: Int) -> ArticleImage? {
        article.embeddedImages.first { $0.position == index }
    }

    private func decodeBase64Image(_ base64String: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        return UIImage(data: data)
    }

    /// Converts markdown-like text to AttributedString with basic formatting
    private func attributedText(from text: String) -> AttributedString {
        var result = AttributedString(text)

        // Handle bold text (**text** or __text__)
        if let boldRange = text.range(of: #"\*\*(.+?)\*\*"#, options: .regularExpression) {
            let boldText = String(text[boldRange])
            let cleanText = boldText.replacingOccurrences(of: "**", with: "")
            if let attrRange = result.range(of: boldText) {
                result.replaceSubrange(attrRange, with: AttributedString(cleanText))
                if let newRange = result.range(of: cleanText) {
                    result[newRange].inlinePresentationIntent = .stronglyEmphasized
                }
            }
        }

        // Handle italic text (*text* or _text_)
        if let italicRange = text.range(of: #"\*(.+?)\*"#, options: .regularExpression) {
            let italicText = String(text[italicRange])
            let cleanText = italicText.replacingOccurrences(of: "*", with: "")
            if let attrRange = result.range(of: italicText) {
                result.replaceSubrange(attrRange, with: AttributedString(cleanText))
                if let newRange = result.range(of: cleanText) {
                    result[newRange].inlinePresentationIntent = .emphasized
                }
            }
        }

        return result
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ArticleReaderView(
            article: Article(
                topicId: UUID(),
                title: "The Hidden Mathematics of Music",
                content: """
                Music and mathematics share a deep, ancient connection that has fascinated scholars for millennia. From the precise ratios of musical intervals discovered by Pythagoras to the complex algorithms powering modern music production, numbers form the invisible scaffold upon which all music rests.

                The relationship between sound and number begins with the physics of vibration. When a string vibrates, it produces not just one frequency but a series of overtones, each a mathematical multiple of the fundamental tone. This harmonic series is the basis for why certain note combinations sound pleasing together while others clash.

                **The Pythagorean Discovery**

                Around 500 BCE, Pythagoras made a revolutionary observation: the most consonant musical intervals correspond to simple numerical ratios. An octave is a 2:1 ratio, a perfect fifth is 3:2, and a perfect fourth is 4:3. This discovery linked the abstract world of mathematics to the sensory experience of sound.

                Modern music theory builds upon these ancient insights. Time signatures, note values, and rhythmic patterns all rely on mathematical subdivision. A piece in 4/4 time divides each measure into four equal beats, while syncopation creates interest by emphasizing unexpected subdivisions.

                The digital age has only deepened this connection. Digital audio converts sound waves into discrete numerical samples, while synthesizers use mathematical functions to generate tones. Machine learning algorithms now compose music by analyzing patterns in millions of existing pieces.

                Perhaps most remarkably, our brains appear hardwired to appreciate mathematical relationships in music. Studies show that listeners prefer music with moderate complexity—neither too predictable nor too chaotic—suggesting an innate appreciation for mathematical balance in sound.
                """,
                heroImage: nil,
                embeddedImages: []
            )
        )
    }
}
