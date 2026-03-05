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
import SDWebImage
import SDWebImageSVGCoder

class AudioPlayerManager: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    static let shared = AudioPlayerManager()
    
    // MARK: - 属性声明
    private var player: AVPlayer? = nil
    @Published var isPlaying = false
    @Published var isBuffering = false
    @Published var currentStation: Station? = nil
    @Published var allRegions: [Region] = []
    
    private var statusObserver: NSKeyValueObservation?
    private let lastStationKey = "AppLastPlayedStation"
    
    // 获取扁平化的所有电台列表
    private var flatStations: [Station] {
        allRegions.flatMap { $0.stations }
    }
    
    init() {
        setupRemoteCommandCenter()
        setupAudioInterruptObserver()
        configureAudioSession()
    }
    
    // MARK: - 核心播放控制
    func play(station: Station) {
        if currentStation?.id == station.id && player != nil {
            toggle()
            return
        }
        
        currentStation = station
        
        // 💾 保存到本地
        if let encoded = try? JSONEncoder().encode(station) {
            UserDefaults.standard.set(encoded, forKey: lastStationKey)
        }
        
        guard let url = URL(string: station.streamUrl) else { return }
        
        configureAudioSession()
        
        let playerItem = AVPlayerItem(url: url)
        setupMetadataObserver(playerItem: playerItem)
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }
        
        setupStatusObserver()
        player?.play()
        self.isPlaying = true
        self.isBuffering = true
        
        // --- 核心同步：先显示文字，再异步加载 SVG/图片到锁屏 ---
        self.syncLockScreenInfo(for: station)
    }
    
    // 在 AudioPlayerManager 中监听
    func setupMetadataObserver(playerItem: AVPlayerItem) {
        playerItem.publisher(for: \.timedMetadata)
            .sink { metadata in
                for item in metadata ?? [] {
                    if let value = item.value as? String {
                        print("🎵 当前正在播放: \(value)")
                       
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func restoreLastStation() {
        if let data = UserDefaults.standard.data(forKey: lastStationKey),
           let savedStation = try? JSONDecoder().decode(Station.self, from: data) {
            self.currentStation = savedStation
        }
    }
    
    func toggle() {
        guard let player = player else {
            if let current = currentStation {
                play(station: current)
            }
            return
        }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
        
        // 状态切换时更新锁屏信息
        if let current = currentStation {
            self.syncLockScreenInfo(for: current)
        }
    }
    
    func stop() {
        player?.pause()
        isPlaying = false
    }
    
    // MARK: - 切歌逻辑
    func next() {
        let stations = self.flatStations
        guard !stations.isEmpty else { return }
        
        guard let current = currentStation,
              let currentIndex = stations.firstIndex(where: { $0.id == current.id }) else {
            if let first = stations.first { play(station: first) }
            return
        }
        
        let nextIndex = (currentIndex + 1) % stations.count
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
        self.play(station: stations[prevIndex])
    }
    
    // MARK: - 监听与配置
    private func setupStatusObserver() {
        statusObserver?.invalidate()
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
                @unknown default: break
                }
            }
        }
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ 音频会话配置失败: \(error)")
        }
    }

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
}

// MARK: - 锁屏控制与图片处理
extension AudioPlayerManager {
    
    private func setupRemoteCommandCenter() {
        let center = MPRemoteCommandCenter.shared()
        
        center.playCommand.addTarget { [weak self] _ in self?.toggle(); return .success }
        center.pauseCommand.addTarget { [weak self] _ in self?.toggle(); return .success }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in self?.toggle(); return .success }
        
        center.nextTrackCommand.isEnabled = true
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.next()
            return .success
        }
        
        center.previousTrackCommand.isEnabled = true
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.previous()
            return .success
        }
    }
    
    /// 统一同步入口：整合了原本的 updateNowPlayingInfo 和 updateNowPlaying
    func syncLockScreenInfo(for station: Station) {
        // 1. 立即更新文字，防止延迟
        self.updateLockScreenNow(station: station, img: nil)
        
        // 2. 异步处理图片 (SDWebImage 自动处理 SVG 渲染)
        guard let url = safeURL(from: station.logoUrl) else { return }
        
        SDWebImageManager.shared.loadImage(
            with: url,
            options: [.highPriority, .retryFailed],
            progress: nil
        ) { [weak self] (image, data, error, cacheType, finished, imageURL) in
            if let downloadedImage = image {
                DispatchQueue.main.async {
                    self?.updateLockScreenNow(station: station, img: downloadedImage)
                }
            }
        }
    }
    
    /// 最终更新锁屏中心的方法
    private func updateLockScreenNow(station: Station, img: UIImage?) {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = station.name
        info[MPMediaItemPropertyArtist] = station.frequency
        info[MPNowPlayingInfoPropertyIsLiveStream] = true
        
        // 处理封面图
        if let image = img {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: CGSize(width: 512, height: 512)) { _ in
                return image
            }
        } else if let placeholder = UIImage(named: "diantai") ?? UIImage(systemName: "radio.fill") {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: placeholder.size) { _ in
                return placeholder
            }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func safeURL(from string: String) -> URL? {
        guard !string.isEmpty else { return nil }
        if let url = URL(string: string), url.scheme != nil { return url }
        return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed).flatMap { URL(string: $0) }
    }
}
