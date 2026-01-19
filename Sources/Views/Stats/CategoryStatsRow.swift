import SwiftUI

struct CategoryStatsRow: View {
    let stats: CategoryStats

    var body: some View {
        HStack(spacing: 16) {
            categoryIcon
            categoryInfo
            Spacer()
            progressBadge
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    private var categoryIcon: some View {
        Image(systemName: stats.category.iconName)
            .font(.title2)
            .foregroundStyle(categoryColor)
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(categoryColor.opacity(0.15))
            )
    }

    private var categoryInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(stats.category.rawValue)
                .font(.headline)

            ProgressView(value: stats.progress)
                .tint(categoryColor)

            Text("\(stats.articlesRead) of \(stats.totalArticles) articles")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var progressBadge: some View {
        Text("\(stats.progressPercentage)%")
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(categoryColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(categoryColor.opacity(0.15))
            )
    }

    private var categoryColor: Color {
        switch stats.category.color {
        case "orange": return .orange
        case "purple": return .purple
        case "blue": return .blue
        case "brown": return .brown
        case "green": return .green
        default: return .gray
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(CategoryStats.sampleData) { stats in
            CategoryStatsRow(stats: stats)
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
