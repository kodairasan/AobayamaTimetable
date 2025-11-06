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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let time = statusBarManager.nextTrainTime {
                VStack(alignment: .leading, spacing: 4) {
                    Text("青葉山駅 → 荒井方面")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("次の電車まで")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(time.minutes)分\(time.seconds)秒")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
            } else {
                Text("時刻表を読み込めませんでした")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .frame(width: 200)
        .padding(.vertical, 8)
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView()
            .environmentObject(StatusBarManager())
    }
}
