//
//  SleepTimerManager.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/3.
//

import Foundation
import Combine

class SleepTimerManager: ObservableObject {
    static let shared = SleepTimerManager()
    
    @Published var timeRemaining: TimeInterval = 0
    @Published var isActive: Bool = false
    
    private var timer: Timer?
    private let playerManager = AudioPlayerManager.shared
    
    // 可选的定时选项（分钟）
    let timerOptions: [Int] = [15, 30, 45, 60, 90]
    
    // 开启定时
    func startTimer(minutes: Int) {
        // 先清理旧的
        stopTimer()
        
        timeRemaining = TimeInterval(minutes * 60)
        isActive = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.timeReachedZero()
            }
        }
    }
    
    // 停止/重置定时
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        timeRemaining = 0
        isActive = false
    }
    
    private func timeReachedZero() {
        stopTimer()
        // 关键：停止播放
        playerManager.stop()
        print("🌙 睡眠时间到，已自动停止播放")
        
    }
    
    // 格式化剩余时间显示 (如 12:05)
    var formattedRemainingTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
