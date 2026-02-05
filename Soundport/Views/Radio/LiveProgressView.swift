//
//  LiveProgressView.swift
//  Soundport
//
//  Created by dengjinlang on 2026/2/3.
//

import SwiftUI
import Combine

struct LiveProgressView: View {
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // 当前时间
                Text(timeString(from: currentTime))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                
                // 进度条：计算当前时间占全天的比例
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(Color.blue)
                            .frame(width: geo.size.width * timePercentage(), height: 4)
                    }
                }
                .frame(height: 4)
                
                // 结束时间固定显示 23:59
                Text("23:59")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .onReceive(timer) { input in
            currentTime = input
        }
    }
    
    // 格式化时间
    func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // 计算当前时间占一天（00:00 - 23:59）的百分比
    func timePercentage() -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let totalMinutes = CGFloat(hour * 60 + minute)
        return totalMinutes / (24 * 60)
    }
}
