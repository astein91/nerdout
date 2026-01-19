import SwiftUI

/// Main view for the level-setting flow that gauges user familiarity with a topic
struct LevelSettingView: View {
    @StateObject private var viewModel: LevelSettingViewModel
    let onComplete: (LevelSettingResult) -> Void
    let onCancel: () -> Void

    init(
        topicDescription: String,
        onComplete: @escaping (LevelSettingResult) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: LevelSettingViewModel(topicDescription: topicDescription))
        self.onComplete = onComplete
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                content
            }
            .navigationTitle("Quick Questions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
        .task {
            await viewModel.loadQuestions()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingView
        case .active:
            questionView
        case .completed:
            completedView
        case .error:
            errorView
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Preparing questions...")
                .foregroundStyle(.secondary)
        }
    }

    private var questionView: some View {
        VStack(spacing: 0) {
            progressBar

            if let question = viewModel.currentQuestion {
                QuestionCard(
                    question: question,
                    questionNumber: viewModel.currentQuestionIndex + 1,
                    totalQuestions: viewModel.questions.count,
                    onAnswer: { level in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.answerCurrentQuestion(with: level)
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(question.id)
            }

            Spacer()
        }
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(.systemGray5))

                Rectangle()
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * viewModel.progress)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
            }
        }
        .frame(height: 4)
    }

    private var completedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("All done!")
                    .font(.title2.bold())

                if let result = viewModel.result {
                    Text("You're at the \(result.sophisticationLevel.displayText.lowercased()) level")
                        .foregroundStyle(.secondary)
                }
            }

            if let result = viewModel.result {
                Button {
                    onComplete(result)
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
            }

            Spacer()
        }
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text(viewModel.errorMessage ?? "Something went wrong")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Try Again") {
                Task {
                    await viewModel.loadQuestions()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    LevelSettingView(
        topicDescription: "Learning about machine learning and AI",
        onComplete: { _ in },
        onCancel: { }
    )
}
