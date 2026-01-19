import SwiftUI

struct CreateView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Create new content")
                    .font(.headline)

                Text("Tap here to start creating")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Create")
        }
    }
}

#Preview {
    CreateView()
}
