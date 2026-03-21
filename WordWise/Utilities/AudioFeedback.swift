import AppKit
class AudioFeedback {
    static let shared = AudioFeedback()
    func playCorrect() { NSSound(named: "Glass")?.play() }
    func playWrong() { NSSound(named: "Basso")?.play() }
}
