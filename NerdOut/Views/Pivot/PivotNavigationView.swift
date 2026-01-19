import SwiftUI

struct PivotNavigationView: View {
    let pivots: [Pivot]
    let onPivotSelected: (Pivot) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundStyle(.secondary)
                Text("Continue Exploring")
                    .font(.headline)
            }
            .padding(.horizontal)

            if pivots.isEmpty {
                Text("No related topics available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(sortedPivots) { pivot in
                            PivotCardView(pivot: pivot)
                                .onTapGesture {
                                    onPivotSelected(pivot)
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
    }

    private var sortedPivots: [Pivot] {
        pivots.sorted { $0.relevanceScore > $1.relevanceScore }
    }
}

#Preview {
    PivotNavigationView(
        pivots: [
            Pivot(
                id: UUID(),
                sourceArticleId: UUID(),
                suggestedTopicTitle: "The Physics of Baseball",
                suggestedTopicDescription: "Explore how aerodynamics affects curveballs and home runs",
                category: .science,
                relevanceScore: 0.92,
                createdAt: Date()
            ),
            Pivot(
                id: UUID(),
                sourceArticleId: UUID(),
                suggestedTopicTitle: "Baseball's Greatest Moments",
                suggestedTopicDescription: "Historic games that changed the sport forever",
                category: .history,
                relevanceScore: 0.85,
                createdAt: Date()
            ),
            Pivot(
                id: UUID(),
                sourceArticleId: UUID(),
                suggestedTopicTitle: "Take Me Out to the Ball Game",
                suggestedTopicDescription: "The story behind baseball's iconic anthem",
                category: .music,
                relevanceScore: 0.78,
                createdAt: Date()
            )
        ],
        onPivotSelected: { pivot in
            print("Selected: \(pivot.suggestedTopicTitle)")
        }
    )
}
