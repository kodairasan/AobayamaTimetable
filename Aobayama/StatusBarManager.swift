//
//  StatusBarManager.swift
//  Aobayama
//
//  Created by 小平航大 on 2025/11/06.
//

import SwiftUI
import AppKit
import Combine

class StatusBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var timer: Timer?
    private var timetableManager = TimetableManager()
    @Published var nextTrainTime: (minutes: Int, seconds: Int)? = nil
    @Published var nextTrains: [TrainInfo] = []
    
    init() {
        setupStatusBar()
        updateNextTrainTime()
        startTimer()
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            updateStatusBarTitle()
            
            // メニューを設定
            let menu = NSMenu()
            
            let menuView = NSHostingView(rootView: MenuView().environmentObject(self))
            menuView.frame = NSRect(x: 0, y: 0, width: 240, height: 170)
            
            let menuItem = NSMenuItem()
            menuItem.view = menuView
            menu.addItem(menuItem)
            
            menu.addItem(NSMenuItem.separator())
            
            let quitItem = NSMenuItem(title: "アプリを終了", action: #selector(quitApp), keyEquivalent: "q")
            quitItem.target = self
            menu.addItem(quitItem)
            
            statusItem?.menu = menu
        }
    }
    
    private func updateStatusBarTitle() {
        guard let button = statusItem?.button else { return }
        
        // SF Symbolsアイコンを設定
        if let iconImage = NSImage(systemSymbolName: "tram.fill", accessibilityDescription: nil) {
            iconImage.isTemplate = true
            iconImage.size = NSSize(width: 16, height: 16)
            button.image = iconImage
        }
        
        // テキストを設定
        if let time = nextTrainTime {
            button.title = "\(time.minutes):\(String(format: "%02d", time.seconds))"
        } else {
            button.title = "青葉山"
        }
    }
    
    private func updateNextTrainTime() {
        nextTrainTime = timetableManager.getNextTrainTime()
        nextTrains = timetableManager.getNextTrains(count: 3)
        updateStatusBarTitle()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateNextTrainTime()
            }
        }
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    deinit {
        timer?.invalidate()
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }
}

