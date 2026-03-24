import SwiftUI; import SwiftData

struct StudySessionView: View {
    @Environment(LanguageManager.self) private var lm
    @Environment(WordRepository.self) private var repository
    @State private var vm: StudySessionViewModel
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    init(set: WordSet) {
        _vm = State(initialValue: StudySessionViewModel(set: set))
    }
    
    var body: some View {
        VStack {
            Spacer()
            if let _ = vm.current {
                Text(vm.prompt)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .premiumGlass()
                    .padding()
                
                TextField("...", text: $vm.answer)
                    .textFieldStyle(.plain)
                    .padding()
                    .premiumGlass()
                    .font(.title)
                    .frame(maxWidth: 600)
                    .padding(.horizontal, 40)
                    .focused($isFocused)
                    .onSubmit { checkAnswer() }
                    .disabled(vm.feedback != .clear)
                
                if vm.feedback == .red {
                    Text(vm.target)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.glassCyan)
                        .padding(.top, 10)
                        .transition(.scale.combined(with: .opacity))
                }
            } else { 
                VStack(spacing: 20) {
                    Text(lm.t("done")).font(.largeTitle).foregroundColor(.white)
                    Button(lm.t("finish")) { dismiss() }.buttonStyle(GlassButtonStyle())
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(vm.feedback.opacity(0.3).ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: vm.feedback)
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .onAppear { 
            vm.setup(repository: repository)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
        .onDisappear { vm.saveSession() }
    }
    
    private func checkAnswer() {
        vm.checkAnswer(
            onSuccess: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    vm.feedback = .clear
                    vm.answer = ""
                    vm.nextWord()
                    isFocused = true
                }
            },
            onFailure: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    vm.feedback = .clear
                    vm.answer = ""
                    vm.nextWord()
                    isFocused = true
                }
            }
        )
    }
}

