import SwiftUI

struct PivotCardView: View {
    let pivot: Pivot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: pivot.category.iconName)
                    .font(.caption)
                    .foregroundStyle(categoryColor)
                Text(pivot.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(categoryColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Text(pivot.suggestedTopicTitle)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text(pivot.suggestedTopicDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            RelevanceIndicator(score: pivot.relevanceScore)
        }
        .padding(12)
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(categoryColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var categoryColor: Color {
        switch pivot.category {
        case .sports: return .orange
        case .music: return .purple
        case .science: return .blue
        case .history: return .brown
        case .literature: return .green
        }
    }
}

struct RelevanceIndicator: View {
    let score: Double

    var body: some View {
        HStack(spacing: 4) {
            Text("Relevance")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.quaternary)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(scoreColor)
                        .frame(width: geometry.size.width * score)
                }
            }
            .frame(height: 4)
        }
    }

    private var scoreColor: Color {
        if score >= 0.8 {
            return .green
        } else if score >= 0.5 {
            return .yellow
        } else {
            return .orange
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PivotCardView(
            pivot: Pivot(
                id: UUID(),
                sourceArticleId: UUID(),
                suggestedTopicTitle: "The Physics of Baseball",
                suggestedTopicDescription: "Explore how aerodynamics affects curveballs and home runs in professional baseball",
                category: .science,
                relevanceScore: 0.92,
                createdAt: Date()
            )
        )

        PivotCardView(
            pivot: Pivot(
                id: UUID(),
                sourceArticleId: UUID(),
                suggestedTopicTitle: "Baseball's Greatest Moments",
                suggestedTopicDescription: "Historic games that changed the sport forever",
                category: .history,
                relevanceScore: 0.65,
                createdAt: Date()
            )
        )
    }
    .padding()
}
