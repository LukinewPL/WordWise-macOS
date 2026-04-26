import SwiftUI

struct TestQuestionView: View {
    @Environment(LanguageManager.self) private var lm
    @AppStorage("animationSpeed") private var animationSpeed: Double = 1.0
    @Bindable var vm: TestViewModel
    let openAnswerFocus: FocusState<Bool>.Binding
    let onExitRequested: () -> Void
    let onRequestFocus: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let containerHeight = proxy.size.height

            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    Button(action: onExitRequested) {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("\(vm.currentIdx + 1) / \(max(1, vm.queue.count))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white.opacity(0.75))

                    Spacer()

                    TestStatChip(icon: "bolt.fill", label: "\(lm.t("score")): \(vm.score)")
                }

                TestProgressTrack(currentIndex: vm.currentIdx, totalCount: vm.queue.count)

                if vm.current != nil {
                    VStack(spacing: 0) {
                        Text(vm.prompt)
                            .font(.system(size: vm.isMultipleChoice ? 48 : 62, weight: .medium, design: .default))
                            .minimumScaleFactor(0.32)
                            .lineLimit(2)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, vm.isMultipleChoice ? 20 : 34)
                    .padding(.horizontal, vm.isMultipleChoice ? 14 : 24)
                    .glassPanel(cornerRadius: vm.isMultipleChoice ? 20 : 28, edgeHighlight: Color.white.opacity(0.16))
                    .padding(.top, 2)

                    if vm.isMultipleChoice {
                        VStack(spacing: optionSpacing(for: containerHeight)) {
                            ForEach(Array(vm.mcOptions.enumerated()), id: \.offset) { index, option in
                                Button(action: { _ = vm.submitMultipleChoiceOption(at: index) }) {
                                    HStack(spacing: 12) {
                                        Text("\(index + 1).")
                                            .font(.system(size: 38, weight: .bold, design: .default))
                                            .foregroundColor(.white.opacity(0.68))
                                            .frame(width: 62, alignment: .leading)

                                        Text(option)
                                            .font(.system(size: 36, weight: .semibold, design: .default))
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                            .minimumScaleFactor(0.55)
                                        Spacer(minLength: 0)
                                    }
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(
                                        maxWidth: .infinity,
                                        minHeight: optionHeight(for: containerHeight),
                                        maxHeight: optionHeight(for: containerHeight)
                                    )
                                    .background(optionBackground(for: option))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .scaleEffect(vm.selectedOption == option ? 1.02 : 1)
                                .animation(animationSpeed > 0 ? .spring(response: 0.28, dampingFraction: 0.82) : nil, value: vm.selectedOption)
                                .disabled(vm.selectedOption != nil)
                                .keyboardShortcut(keyEquivalent(for: index), modifiers: [])
                            }
                        }
                        .frame(maxWidth: 920, maxHeight: .infinity, alignment: .top)
                    } else {
                        Spacer(minLength: openAnswerTopOffset(for: containerHeight))

                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.glassSky.opacity(0.32), lineWidth: 1)
                                )
                                .frame(width: 52, height: 52)
                                .overlay {
                                    Image(systemName: "keyboard.fill")
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(Color.glassTeal)
                                }

                            Rectangle()
                                .fill(Color.white.opacity(0.16))
                                .frame(width: 1, height: 34)

                            TextField(
                                "",
                                text: $vm.answer,
                                prompt: Text(lm.t("enter_answer"))
                                    .foregroundStyle(.white.opacity(0.5))
                            )
                                .textFieldStyle(.plain)
                                .font(.title)
                                .foregroundColor(.white)
                                .focused(openAnswerFocus)
                                .onSubmit { vm.submitOpen() }
                                .disabled(vm.selectedOption != nil)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 76)
                        .glassPanel(cornerRadius: 22)
                        .frame(maxWidth: 700)
                        .padding(.bottom, 8)

                        if vm.showCorrectAnswer {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(vm.target)
                                    .font(.title3.weight(.semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                            }
                            .padding(.horizontal, 22)
                            .frame(height: 76)
                            .glassPanel(cornerRadius: 22, edgeHighlight: Color.red.opacity(0.35))
                            .frame(maxWidth: 700)
                            .padding(.top, 4)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            .animation(.easeInOut(duration: 0.2), value: vm.showCorrectAnswer)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 10)
        }
        .onAppear(perform: onRequestFocus)
    }

    private func optionBackground(for option: String) -> LinearGradient {
        if let selected = vm.selectedOption {
            if option == vm.target {
                return DesignSystem.Feedback.successGradient
            }
            if option == selected {
                return DesignSystem.Feedback.failureGradient
            }
        }

        return LinearGradient(
            colors: [Color.white.opacity(0.11), Color.white.opacity(0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func keyEquivalent(for index: Int) -> KeyEquivalent {
        let number = min(max(index + 1, 1), 9)
        return KeyEquivalent(Character(String(number)))
    }

    private func optionHeight(for containerHeight: CGFloat) -> CGFloat {
        let scaled = (containerHeight - 460) / 4
        return min(max(scaled, 106), 148)
    }

    private func optionSpacing(for containerHeight: CGFloat) -> CGFloat {
        min(max((containerHeight - 640) / 28, 10), 18)
    }

    private func openAnswerTopOffset(for containerHeight: CGFloat) -> CGFloat {
        min(max((containerHeight - 640) / 6, 28), 88)
    }
}

private struct TestProgressTrack: View {
    let currentIndex: Int
    let totalCount: Int

    var body: some View {
        GeometryReader { proxy in
            let total = max(1, totalCount)
            let progress = CGFloat(currentIndex + 1) / CGFloat(total)
            let filled = max(8, proxy.size.width * progress)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.glassMint, Color.glassSky.opacity(0.75)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: filled)
                    .shadow(color: Color.glassTeal.opacity(0.35), radius: 8, x: 0, y: 2)
            }
        }
        .frame(height: 6)
        .animation(.easeInOut(duration: 0.26), value: currentIndex)
    }
}
