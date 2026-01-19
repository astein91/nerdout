import Foundation
import Observation

@Observable
final class ClarifyingFlowViewModel {
    private(set) var session: ClarifyingSession?
    private(set) var isLoading = false
    private(set) var error: Error?

    var currentQuestionIndex = 0
    var currentAnswer = ""

    private let clarifyingService: ClarifyingService
    private let userInput: String

    init(userInput: String, apiKey: String) {
        self.userInput = userInput
        self.clarifyingService = ClarifyingService(apiKey: apiKey)
    }

    var currentQuestion: ClarifyingQuestion? {
        guard let session = session,
              currentQuestionIndex < session.questions.count else {
            return nil
        }
        return session.questions[currentQuestionIndex]
    }

    var questionCount: Int {
        session?.questions.count ?? 0
    }

    var isFirstQuestion: Bool {
        currentQuestionIndex == 0
    }

    var isLastQuestion: Bool {
        guard let session = session else { return false }
        return currentQuestionIndex == session.questions.count - 1
    }

    var canProceed: Bool {
        !currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var progress: Double {
        guard questionCount > 0 else { return 0 }
        return Double(currentQuestionIndex) / Double(questionCount)
    }

    @MainActor
    func loadQuestions() async {
        isLoading = true
        error = nil

        do {
            let questions = try await clarifyingService.generateClarifyingQuestions(for: userInput)
            session = ClarifyingSession(userInput: userInput, questions: questions)
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func saveCurrentAnswer() {
        guard var updatedSession = session else { return }
        updatedSession.questions[currentQuestionIndex].answer = currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        session = updatedSession
    }

    func goToNextQuestion() {
        saveCurrentAnswer()
        currentQuestionIndex += 1
        currentAnswer = session?.questions[currentQuestionIndex].answer ?? ""
    }

    func goToPreviousQuestion() {
        saveCurrentAnswer()
        currentQuestionIndex -= 1
        currentAnswer = session?.questions[currentQuestionIndex].answer ?? ""
    }

    func completeSession() -> ClarifyingSession? {
        saveCurrentAnswer()
        return session
    }
}
