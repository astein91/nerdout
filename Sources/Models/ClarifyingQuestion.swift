import Foundation

struct ClarifyingQuestion: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    var answer: String?

    init(id: UUID = UUID(), text: String, answer: String? = nil) {
        self.id = id
        self.text = text
        self.answer = answer
    }
}

struct ClarifyingSession: Identifiable, Codable {
    let id: UUID
    let userInput: String
    var questions: [ClarifyingQuestion]
    let createdAt: Date

    init(id: UUID = UUID(), userInput: String, questions: [ClarifyingQuestion] = [], createdAt: Date = Date()) {
        self.id = id
        self.userInput = userInput
        self.questions = questions
        self.createdAt = createdAt
    }

    var isComplete: Bool {
        !questions.isEmpty && questions.allSatisfy { $0.answer != nil && !$0.answer!.isEmpty }
    }

    var answeredQuestions: [(question: String, answer: String)] {
        questions.compactMap { q in
            guard let answer = q.answer, !answer.isEmpty else { return nil }
            return (question: q.text, answer: answer)
        }
    }
}

struct ClarifyingResponse: Codable {
    let questions: [String]
}
