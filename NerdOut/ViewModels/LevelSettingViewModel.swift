import Foundation
import SwiftUI

/// Manages state for the level-setting flow
@MainActor
final class LevelSettingViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var questions: [LevelSettingQuestion] = []
    @Published private(set) var currentQuestionIndex: Int = 0
    @Published private(set) var answers: [LevelSettingAnswer] = []
    @Published private(set) var state: FlowState = .idle
    @Published var errorMessage: String?

    // MARK: - Properties

    let topicDescription: String
    private let service: LevelSettingService

    var currentQuestion: LevelSettingQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(questions.count)
    }

    var isComplete: Bool {
        currentQuestionIndex >= questions.count && !questions.isEmpty
    }

    var result: LevelSettingResult? {
        guard isComplete else { return nil }
        return LevelSettingResult(
            topicDescription: topicDescription,
            answers: answers
        )
    }

    // MARK: - Initialization

    init(topicDescription: String, service: LevelSettingService = LevelSettingService()) {
        self.topicDescription = topicDescription
        self.service = service
    }

    // MARK: - Actions

    func loadQuestions() async {
        state = .loading
        errorMessage = nil

        do {
            let generatedQuestions = try await service.generateQuestions(for: topicDescription)
            guard !generatedQuestions.isEmpty else {
                throw LevelSettingError.noQuestionsGenerated
            }
            questions = generatedQuestions
            state = .active
        } catch {
            errorMessage = error.localizedDescription
            state = .error
        }
    }

    func answerCurrentQuestion(with level: FamiliarityLevel) {
        guard let question = currentQuestion else { return }

        let answer = LevelSettingAnswer(
            questionId: question.id,
            concept: question.concept,
            familiarityLevel: level
        )
        answers.append(answer)
        currentQuestionIndex += 1

        if isComplete {
            state = .completed
        }
    }

    func reset() {
        questions = []
        currentQuestionIndex = 0
        answers = []
        state = .idle
        errorMessage = nil
    }

    // MARK: - Flow State

    enum FlowState: Equatable {
        case idle
        case loading
        case active
        case completed
        case error
    }
}

// MARK: - Preview Support

extension LevelSettingViewModel {
    static var preview: LevelSettingViewModel {
        let vm = LevelSettingViewModel(topicDescription: "Learning Swift programming")
        vm.questions = [
            LevelSettingQuestion(
                text: "Have you heard of variables and constants?",
                questionType: .heardOf,
                concept: "variables and constants"
            ),
            LevelSettingQuestion(
                text: "How familiar are you with object-oriented programming?",
                questionType: .familiarWith,
                concept: "object-oriented programming"
            ),
            LevelSettingQuestion(
                text: "Have you ever written code in any programming language?",
                questionType: .usedBefore,
                concept: "programming"
            ),
            LevelSettingQuestion(
                text: "How comfortable do you feel with command line interfaces?",
                questionType: .comfortable,
                concept: "command line interfaces"
            )
        ]
        vm.state = .active
        return vm
    }
}
