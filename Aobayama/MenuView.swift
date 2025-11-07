//
//  MenuView.swift
//  Aobayama
//
//  Created by 小平航大 on 2025/11/06.
//
import SwiftUI
import AppKit
import Combine

struct MenuView: View {
    @EnvironmentObject var statusBarManager: StatusBarManager
    
    // 残り時間に応じた色を計算
    private func colorForTime(minutes: Int, seconds: Int) -> Color {
        let totalSeconds = minutes * 60 + seconds
        
        if totalSeconds <= 300 { // 5分以下
            return .red
        } else if totalSeconds <= 600 { // 10分以下
            return .orange
        } else {
            return .blue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !statusBarManager.nextTrains.isEmpty {
                // ヘッダー
                HStack(spacing: 4) {
                    Image(systemName: "tram.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("青葉山駅 → 荒井方面")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 8)
                
                Divider()
                
                // 電車リスト
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(statusBarManager.nextTrains.enumerated()), id: \.offset) { index, train in
                        TrainRowView(train: train, index: index)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 10)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("時刻表を読み込めませんでした")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .frame(width: 240)
    }
}

struct TrainRowView: View {
    let train: TrainInfo
    let index: Int
    
    private var isFirst: Bool {
        index == 0
    }
    
    // 残り時間に応じた色を計算
    private func colorForTime(minutes: Int, seconds: Int) -> Color {
        let totalSeconds = minutes * 60 + seconds
        
        if totalSeconds <= 300 { // 5分以下
            return .red
        } else if totalSeconds <= 600 { // 10分以下
            return .orange
        } else {
            return .blue
        }
    }
    
    private var trainNumber: String {
        switch index {
        case 0: return "①"
        case 1: return "②"
        case 2: return "③"
        default: return "\(index + 1)"
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // 電車番号（1本目、2本目、3本目）
            Text(trainNumber)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            // 発車時刻
            VStack(alignment: .leading, spacing: 2) {
                Text("\(String(format: "%02d", train.hour)):\(String(format: "%02d", train.minute))")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary)
            }
            .frame(width: 60, alignment: .leading)
            
            Spacer()
            
            // 残り時間
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                if train.minutesUntil > 0 {
                    Text("\(train.minutesUntil)")
                        .font(.system(size: isFirst ? 20 : 16, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                        .foregroundColor(colorForTime(minutes: train.minutesUntil, seconds: train.secondsUntil))
                        .animation(.easeInOut(duration: 0.3), value: train.minutesUntil)
                    
                    Text("分")
                        .font(.system(size: isFirst ? 14 : 12))
                        .foregroundColor(.secondary)
                }
                
                Text("\(String(format: "%02d", train.secondsUntil))")
                    .font(.system(size: isFirst ? 18 : 14, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText())
                    .foregroundColor(colorForTime(minutes: train.minutesUntil, seconds: train.secondsUntil))
                    .animation(.easeInOut(duration: 0.3), value: train.secondsUntil)
                
                Text("秒")
                    .font(.system(size: isFirst ? 14 : 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, isFirst ? 5 : 3)
        .padding(.horizontal, 4)
        .background(isFirst ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView()
            .environmentObject(StatusBarManager())
    }
}
