import SwiftUI
import SwiftData
import Combine

struct SpeedRoundView: View {
    @Environment(LanguageManager.self) private var lm
    @Environment(WordRepository.self) private var repository
    @State private var vm: SpeedRoundViewModel
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    private let timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(set: WordSet) {
        _vm = State(initialValue: SpeedRoundViewModel(set: set))
    }
    
    var body: some View {
        VStack {
            if !vm.isStarted {
                VStack(spacing: DesignSystem.Spacing.large) {
                    Text(vm.set.name).font(.largeTitle.bold()).foregroundColor(.white)
                    Text("\(lm.t("record")): \(vm.set.bestScore)").font(.title2).foregroundColor(.glassCyan)
                    Button(lm.t("start")) { 
                        vm.startGame()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isFocused = true }
                    }.buttonStyle(GlassButtonStyle())
                }.premiumGlass().padding()
            } else if vm.isFinished {
                VStack(spacing: DesignSystem.Spacing.medium) {
                    Text(lm.t("time_up")).vibrantTitle().padding()
                    if vm.showRecordBlast {
                        Text("🏆 \(lm.t("new_record"))!").font(.title.bold()).foregroundColor(.orange).transition(.scale)
                    }
                    Text("\(lm.t("score")): \(vm.correctCount)").font(.title).foregroundColor(.glassCyan).padding()
                    Button(lm.t("done")) { dismiss() }.buttonStyle(GlassButtonStyle())
                }.premiumGlass().padding()
            } else {
                HStack {
                    Spacer()
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.1), lineWidth: 6)
                        Circle().trim(from: 0, to: CGFloat(vm.timeLeft) / 60.0)
                            .stroke(
                                LinearGradient(colors: [.glassCyan, .blue], startPoint: .top, endPoint: .bottom),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: vm.timeLeft)
                        Text("\(vm.timeLeft)").font(.title2).foregroundColor(.white).bold()
                    }.frame(width: 70, height: 70)
                }.padding()
                
                Spacer()
                if let _ = vm.current {
                    Text(vm.prompt).font(.system(size: 64, weight: .bold, design: .rounded)).foregroundColor(.white).premiumGlass().padding()
                    
                    if vm.showWrongAnswer {
                        Text(vm.target).font(.title).foregroundColor(.red).padding()
                    } else {
                        TextField("...", text: $vm.answer)
                            .textFieldStyle(.plain)
                            .padding()
                            .premiumGlass()
                            .font(.title)
                            .frame(maxWidth: 600)
                            .padding(.horizontal, 40)
                            .focused($isFocused)
                            .onSubmit { checkAnswer() }
                    }
                }
                Spacer()
                Text("\(lm.t("score")): \(vm.correctCount)").foregroundColor(.white).font(.title3.bold()).padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(vm.feedbackColor.opacity(0.3).ignoresSafeArea())
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .onReceive(timerPublisher) { _ in
            vm.tick()
        }
        .onAppear {
            vm.setup(repository: repository)
        }
        .onDisappear { vm.saveSession() }
    }
    
    private func checkAnswer() {
        vm.checkAnswer(
            onSuccess: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    vm.feedbackColor = .clear
                    vm.nextWord()
                    isFocused = true
                }
            },
            onFailure: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    vm.showWrongAnswer = false
                    vm.feedbackColor = .clear
                    vm.answer = ""
                    vm.nextWord()
                    isFocused = true
                }
            }
        )
    }
}

