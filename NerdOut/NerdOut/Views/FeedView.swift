import SwiftUI

struct FeedView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Feed content will appear here")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Feed")
        }
    }
}

#Preview {
    FeedView()
}
