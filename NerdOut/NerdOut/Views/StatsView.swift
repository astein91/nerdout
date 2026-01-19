import SwiftUI

struct StatsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Overview") {
                    HStack {
                        Text("Total Items")
                        Spacer()
                        Text("0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("This Week")
                        Spacer()
                        Text("0")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Activity") {
                    Text("No activity yet")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Stats")
        }
    }
}

#Preview {
    StatsView()
}
