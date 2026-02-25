
import SwiftUI
import Combine
import ShazamKit


class ShazamManager: NSObject, ObservableObject {
    @Published var isRecognizing = false
    @Published var lastResult: SHMatchedMediaItem?

    private var shazamSession: SHSession? // 改为可选，每次识别前重新创建
    private let audioEngine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()

    private var isTapInstalled = false

    // MARK: - Public API
    func startRecognition() {
        guard !isRecognizing else { return }
        
        // 1. 立即反馈 UI 状态
        self.isRecognizing = true
        self.lastResult = nil
        // 1. 创建全新的 SHSession，清除之前的指纹残余
        shazamSession = SHSession()
        shazamSession?.delegate = self

        audioSession.requestRecordPermission { [weak self] granted in
            guard granted, let self = self else { return }
            
            // 将耗时的音频操作移至后台队列，防止 UI Hang
            DispatchQueue.global(qos: .userInitiated).async {
                self.configureAudioSession()
                self.startEngineAndInstallTapIfNeeded()
                
//                DispatchQueue.main.async {
//                    self.isRecognizing = true
//                    
//                }
                
                self.scheduleAutoStop()
            }
        }
    }

    func stopRecognition() {
        // 移除 Tap 必须同步或在正确的队列，防止 crash
        if isTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isTapInstalled = false
        }

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        DispatchQueue.main.async {
            self.isRecognizing = false
            self.shazamSession = nil // 销毁 session
        }
    }

    private func configureAudioSession() {
        do {
            // 关键：.playAndRecord 时，一定要处理好 active 状态
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .allowBluetooth, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ 音频会话配置失败: \(error)")
        }
    }

    private func startEngineAndInstallTapIfNeeded() {
        // 1. 这里的 inputNode 访问是耗时的，已经在后台线程处理
        let inputNode = audioEngine.inputNode
        
        // 2. 采样率安全检查：确保使用 inputFormat
        // 很多直播流会改变硬件采样率，直接用 inputFormat 最稳妥
        let recordingFormat = inputNode.inputFormat(forBus: 0)

        // 3. 彻底清理旧的 Tap
        inputNode.removeTap(onBus: 0)
        
        // 4. 安装 Tap
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: recordingFormat) { [weak self] buffer, when in
            guard let self = self else { return }
            
            // 关键修复：忽略无效的初始时间戳，防止 Shazam 报错 101
            if when.sampleTime >= 0 {
                self.shazamSession?.matchStreamingBuffer(buffer, at: when)
            }
        }

        isTapInstalled = true
        
        do {
            audioEngine.prepare()
            try audioEngine.start()
            print("✅ Shazam 引擎启动成功")
        } catch {
            print("❌ 引擎启动失败: \(error)")
            // 如果失败，务必通知 UI 停止转圈
            DispatchQueue.main.async {
                self.stopRecognition()
            }
        }
    }
    

    private func scheduleAutoStop() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) { [weak self] in
            guard let self = self, self.isRecognizing else { return }
            self.stopRecognition()
        }
    }

    
 
}

// MARK: - SHSessionDelegate
extension ShazamManager: SHSessionDelegate {
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
