//
//  AobayamaApp.swift
//  Aobayama
//
//  Created by 小平航大 on 2025/11/06.
//

import SwiftUI
import Combine

@main
struct AobayamaApp: App {
    @StateObject private var statusBarManager = StatusBarManager()
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
