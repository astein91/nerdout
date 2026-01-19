import SwiftUI

struct CreateView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Create something new")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Create")
        }
    }
}

#Preview {
    CreateView()
}
