import SwiftUI

struct StatsView: View {
    let categoryStats: [CategoryStats]

    var totalArticlesRead: Int {
        categoryStats.reduce(0) { $0 + $1.articlesRead }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    categoryListSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Stats")
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("\(totalArticlesRead)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Articles Read")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }

    private var categoryListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By Category")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 12) {
                ForEach(categoryStats) { stats in
                    CategoryStatsRow(stats: stats)
                }
            }
        }
    }
}

#Preview {
    StatsView(categoryStats: CategoryStats.sampleData)
}
