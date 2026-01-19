import SwiftUI

struct ClarifyingFlowView: View {
    let userInput: String
    let onComplete: (ClarifyingSession) -> Void
    let onCancel: () -> Void

    @State private var session: ClarifyingSession?
    @State private var currentQuestionIndex = 0
    @State private var currentAnswer = ""
    @State private var isLoading = true
    @State private var error: Error?

    private let clarifyingService: ClarifyingService

    init(
        userInput: String,
        apiKey: String,
        onComplete: @escaping (ClarifyingSession) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.userInput = userInput
        self.clarifyingService = ClarifyingService(apiKey: apiKey)
        self.onComplete = onComplete
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if isLoading {
                loadingView
            } else if let error = error {
                errorView(error)
            } else if let session = session {
                questionView(session)
            }
        }
        .task {
            await loadQuestions()
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Let's clarify your interests")
                .font(.title2)
                .fontWeight(.semibold)

            if let session = session, !isLoading {
                ProgressView(value: Double(currentQuestionIndex), total: Double(session.questions.count))
                    .tint(.blue)
                    .padding(.horizontal, 32)

                Text("Question \(currentQuestionIndex + 1) of \(session.questions.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Generating questions based on your interests...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
        .padding()
    }

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)

            Text("Something went wrong")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)

                Button("Try Again") {
                    Task { await loadQuestions() }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 8)
        }
        .frame(maxHeight: .infinity)
        .padding()
    }

    private func questionView(_ session: ClarifyingSession) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(session.questions[currentQuestionIndex].text)
                        .font(.title3)
                        .fontWeight(.medium)
                        .fixedSize(horizontal: false, vertical: true)

                    TextField("Your answer", text: $currentAnswer, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...6)
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(24)
            }

            Divider()

            HStack {
                if currentQuestionIndex > 0 {
                    Button("Back") {
                        goToPreviousQuestion()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Cancel") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                if currentQuestionIndex < session.questions.count - 1 {
                    Button("Next") {
                        goToNextQuestion()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } else {
                    Button("Complete") {
                        completeSession()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
        }
    }

    private func loadQuestions() async {
        isLoading = true
        error = nil

        do {
            let questions = try await clarifyingService.generateClarifyingQuestions(for: userInput)
            session = ClarifyingSession(userInput: userInput, questions: questions)
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    private func goToNextQuestion() {
        guard var updatedSession = session else { return }
        updatedSession.questions[currentQuestionIndex].answer = currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        session = updatedSession

        currentQuestionIndex += 1
        currentAnswer = session?.questions[currentQuestionIndex].answer ?? ""
    }

    private func goToPreviousQuestion() {
        guard var updatedSession = session else { return }
        updatedSession.questions[currentQuestionIndex].answer = currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        session = updatedSession

        currentQuestionIndex -= 1
        currentAnswer = session?.questions[currentQuestionIndex].answer ?? ""
    }

    private func completeSession() {
        guard var updatedSession = session else { return }
        updatedSession.questions[currentQuestionIndex].answer = currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        onComplete(updatedSession)
    }
}

#Preview {
    ClarifyingFlowView(
        userInput: "I want to learn about machine learning",
        apiKey: "test-key",
        onComplete: { session in
            print("Completed: \(session)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}
