
import SwiftUI
import Combine
import ShazamKit


class ShazamManager: NSObject, ObservableObject, SHSessionDelegate {
    @Published var isRecognizing = false
    @Published var lastResult: SHMatchedMediaItem?

    private let shazamSession = SHSession()
    private let audioEngine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()

    private var isTapInstalled = false

    override init() {
        super.init()
        shazamSession.delegate = self
    }

    // MARK: - Public API
    func startRecognition() {
        guard !isRecognizing else { return }

        audioSession.requestRecordPermission { [weak self] granted in
            guard granted, let self = self else { return }
            DispatchQueue.main.async {
                self.configureAudioSession()
                self.startEngineAndInstallTapIfNeeded()
                self.isRecognizing = true
                self.scheduleAutoStop()
            }
        }
    }

    func stopRecognition() {
        guard isRecognizing else { return }

        if isTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isTapInstalled = false
        }

        audioEngine.stop()
        isRecognizing = false
    }

    // MARK: - Audio Setup
    private func configureAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord,
                                         mode: .default,
                                         options: [.mixWithOthers, .defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("AudioSession error: \(error.localizedDescription)")
        }
    }

    private func startEngineAndInstallTapIfNeeded() {
        guard !audioEngine.isRunning else { return }
        guard !isTapInstalled else { return }

        let inputNode = audioEngine.inputNode   // ⭐️ 强制初始化 graph
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0,
                             bufferSize: 2048,
                             format: format) { [weak self] buffer, when in
            guard let self = self else { return }
            self.shazamSession.matchStreamingBuffer(buffer, at: when)
        }

        isTapInstalled = true

        audioEngine.prepare()   // ⭐️ 必须在 tap 之后
        do {
            try audioEngine.start()
        } catch {
            print("AudioEngine start error: \(error.localizedDescription)")
        }
    }

    private func scheduleAutoStop() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) { [weak self] in
            guard let self = self, self.isRecognizing else { return }
            self.stopRecognition()
        }
    }

    // MARK: - SHSessionDelegate
    func session(_ session: SHSession, didFind match: SHMatch) {
        guard let item = match.mediaItems.first else { return }

        DispatchQueue.main.async {
            self.lastResult = item
            print("✅ Found: \(item.title ?? "")")
            self.stopRecognition()
        }
    }

    func session(_ session: SHSession,
                 didNotFindMatchFor signature: SHSignature,
                 error: Error?) {
        DispatchQueue.main.async {
            print("ℹ️ No match found")
            self.stopRecognition()
        }
    }
}
