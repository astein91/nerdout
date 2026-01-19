import SwiftUI

struct FeedView: View {
    let topics: [Topic]

    init(topics: [Topic] = Topic.sampleTopics) {
        self.topics = topics
    }

    var body: some View {
        NavigationStack {
            List(topics) { topic in
                TopicRow(topic: topic)
            }
            .listStyle(.plain)
            .navigationTitle("Feed")
        }
    }
}

struct TopicRow: View {
    let topic: Topic

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(topic.title)
                .font(.headline)

            Text(topic.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 12) {
                ProgressView(value: topic.readingProgress)
                    .tint(progressColor)

                Text(topic.progressDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var progressColor: Color {
        switch topic.readingProgress {
        case 1.0:
            return .green
        case 0.5...:
            return .blue
        case 0.01...:
            return .orange
        default:
            return .gray
        }
    }
}

#Preview {
    FeedView()
}
