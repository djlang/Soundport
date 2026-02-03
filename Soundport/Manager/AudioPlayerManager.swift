//
//  AudioPlayerManager.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/2.
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine

class AudioPlayerManager: ObservableObject {
    static let shared = AudioPlayerManager()
    
    // 1. 先声明并给初始值
    private var player: AVPlayer? = nil
    @Published var isPlaying = false
    @Published var isBuffering = false // 新增：是否正在缓冲
    @Published var currentStation: Station? = nil
    
    @Published var allRegions: [Region] = []
    
    // 监听播放器状态的观察者
    private var statusObserver: NSKeyValueObservation?
    
    // 获取扁平化的所有电台列表，方便计算索引
    private var flatStations: [Station] {
        allRegions.flatMap { $0.stations }
    }
    
    
    init() {
        // 2. 此时所有属性都有了初值，可以安全调用 self 的方法
        setupRemoteCommandCenter()
        setupAudioInterruptObserver()
    }
    
    func play(station: Station) {
        if currentStation?.id == station.id && player != nil {
            toggle()
            return
        }
        
        currentStation = station
        guard let url = URL(string: station.streamUrl) else { return }
        
        configureAudioSession()
        
        let playerItem = AVPlayerItem(url: url)
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }
        
        // --- 核心：添加状态监听 ---
        setupStatusObserver()
        
        player?.play()
        self.isPlaying = true
        // 开始播放时先设定为正在缓冲
        self.isBuffering = true
        updateNowPlayingInfo(station: station)
    }
    
    func toggle() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    // 下一个
    // MARK: - 逻辑修复版
    func next() {
        // 1. 确保列表不为空
        let stations = self.flatStations
        guard !stations.isEmpty else {
            print("⚠️ [Player] 列表为空，无法切换")
            return
        }
        
        // 2. 找到当前索引
        guard let current = currentStation,
              let currentIndex = stations.firstIndex(where: { $0.id == current.id }) else {
            // 如果找不到当前电台（比如刚启动），直接播第一个
            if let first = stations.first { play(station: first) }
            return
        }
        
        // 3. 计算并播放
        let nextIndex = (currentIndex + 1) % stations.count
        print("🚀 [Player] 准备切换至下一个: \(stations[nextIndex].name)")
        self.play(station: stations[nextIndex])
    }

    func previous() {
        let stations = self.flatStations
        guard !stations.isEmpty else { return }
        
        guard let current = currentStation,
              let currentIndex = stations.firstIndex(where: { $0.id == current.id }) else {
            if let last = stations.last { play(station: last) }
            return
        }
        
        let prevIndex = (currentIndex - 1 + stations.count) % stations.count
        print("🚀 [Player] 准备切换至上一个: \(stations[prevIndex].name)")
        self.play(station: stations[prevIndex])
    }
    
    private func setupStatusObserver() {
        // 移除旧的监听
        statusObserver?.invalidate()
        
        // 监听 timeControlStatus
        statusObserver = player?.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            DispatchQueue.main.async {
                switch player.timeControlStatus {
                case .waitingToPlayAtSpecifiedRate:
                    self?.isBuffering = true
                case .playing:
                    self?.isBuffering = false
                    self?.isPlaying = true
                case .paused:
                    self?.isBuffering = false
                    self?.isPlaying = false
                @unknown default:
                    break
                }
            }
        }
    }
    

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ 音频会话配置失败: \(error)")
        }
    }

    // 监听电话打入等中断
    private func setupAudioInterruptObserver() {
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
            
            if type == .began {
                self?.isPlaying = false
            } else if type == .ended {
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        self?.player?.play()
                        self?.isPlaying = true
                    }
                }
            }
        }
    }
    
    
    // 在 play 方法中加入锁屏控制的下一首/上一首支持
    private func setupRemoteCommandCenter() {
        let center = MPRemoteCommandCenter.shared()
        
        center.playCommand.addTarget { [weak self] _ in self?.toggle(); return .success }
        center.pauseCommand.addTarget { [weak self] _ in self?.toggle(); return .success }
        
        // 响应锁屏和耳机的“下一曲”
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.next()
            return .success
        }
        
        // 响应锁屏和耳机的“上一曲”
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.previous()
            return .success
        }
        
       
    }
    

 
    private func updateNowPlayingInfo(station: Station) {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = station.name
        info[MPMediaItemPropertyArtist] = station.frequency
        info[MPNowPlayingInfoPropertyIsLiveStream] = true
        
        info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: CGSize(width: 512, height: 512)) { _ in
            return UIImage(systemName: "radio.fill") ?? UIImage()
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

extension AudioPlayerManager {
   
    func updateNowPlaying(station: Station) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = station.name
        nowPlayingInfo[MPMediaItemPropertyArtist] = station.frequency
        
        // 设置封面
        if let url = URL(string: station.logoUrl), let data = try? Data(contentsOf: url) {
            if let image = UIImage(data: data) {
                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
 
}
