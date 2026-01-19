import SwiftUI

/// Card displaying a single level-setting question with answer options
struct QuestionCard: View {
    let question: LevelSettingQuestion
    let questionNumber: Int
    let totalQuestions: Int
    let onAnswer: (FamiliarityLevel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            questionHeader
            questionText
            answerOptions
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }

    private var questionHeader: some View {
        Text("Question \(questionNumber) of \(totalQuestions)")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private var questionText: some View {
        Text(question.text)
            .font(.title3.weight(.medium))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var answerOptions: some View {
        VStack(spacing: 12) {
            ForEach(question.questionType.responseOptions) { level in
                AnswerButton(
                    title: level.displayText,
                    action: { onAnswer(level) }
                )
            }
        }
    }
}

/// Individual answer button with tap feedback
struct AnswerButton: View {
    let title: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .foregroundStyle(.primary)
    }
}

/// Button style with scale animation on press
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        QuestionCard(
            question: LevelSettingQuestion(
                text: "Have you heard of neural networks before?",
                questionType: .heardOf,
                concept: "neural networks"
            ),
            questionNumber: 1,
            totalQuestions: 4,
            onAnswer: { _ in }
        )
    }
}
