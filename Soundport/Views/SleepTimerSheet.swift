//
//  SleepTimerSheet.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/3.
//
import SwiftUI
import Combine

struct SleepTimerSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var sleepManager = SleepTimerManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("开启后，播放将在计时结束时自动停止")) {
                    ForEach(sleepManager.timerOptions, id: \.self) { minutes in
                        Button(action: {
                            sleepManager.startTimer(minutes: minutes)
                            dismiss()
                        }) {
                            HStack {
                                Text("\(minutes) 分钟后")
                                    .foregroundColor(.primary)
                                Spacer()
                                if sleepManager.isActive && Int(sleepManager.timeRemaining / 60) == minutes {
                                    Image(systemName: "checkmark").foregroundColor(.purple)
                                }
                            }
                        }
                    }
                }
                
                if sleepManager.isActive {
                    Section {
                        Button("关闭定时器") {
                            sleepManager.stopTimer()
                            dismiss()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("睡眠定时")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium]) // 弹窗只占一半高度
    }
}
