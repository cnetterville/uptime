//
//  UptimeApp.swift
//  Uptime
//
//  Created by Curtis Netterville on 10/6/25.
//

import SwiftUI
import Combine

@main
struct UptimeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem?
    var preferencesWindow: NSWindow?
    var preferencesWindowController: NSWindowController?
    var historyWindow: NSWindow?
    var historyWindowController: NSWindowController?
    var aboutWindow: NSWindow?
    var aboutWindowController: NSWindowController?
    private var uptimeManager = UptimeManager()
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        // Ensure proper cleanup
        cancellables.removeAll()
        uptimeManager.stopUpdating()
        print("AppDelegate deallocated")
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the dock icon since this is a menubar-only app
        NSApp.setActivationPolicy(.accessory)
        
        // Set default preferences if not set
        registerDefaults()
        
        // Create the status item with fixed length to prevent jitter
        statusItem = NSStatusBar.system.statusItem(withLength: 100)
        
        if let button = statusItem?.button {
            // Set initial title with monospaced font
            button.title = uptimeManager.compactUptime
            button.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        }
        
        // Start the uptime manager
        uptimeManager.startUpdating()
        
        // Subscribe to uptime changes to update the menubar (throttled to reduce jitter)
        // Using weak self to prevent retain cycle
        uptimeManager.$uptimeSeconds
            .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                self?.updateStatusBarTitle()
            }
            .store(in: &cancellables)
        
        // Set up the context menu
        setupContextMenu()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up resources before app terminates
        uptimeManager.stopUpdating()
        cancellables.removeAll()
    }
    
    private func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            "launchAtLogin": false,
            "updateFrequency": 1.0,
            "showArrow": true,
            "milestoneNotifications": true,
            "timeUnitFormat": TimeUnit.automatic.rawValue,
            "showMinutesInMenubar": true,
            "use24HourFormat": false
        ])
    }
    
    private func setupContextMenu() {
        let menu = NSMenu()
        
        let aboutItem = NSMenuItem(title: "About Uptime", action: #selector(openAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let historyItem = NSMenuItem(title: "Uptime History...", action: #selector(openHistory), keyEquivalent: "h")
        historyItem.target = self
        menu.addItem(historyItem)
        
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit Uptime", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    private func updateStatusBarTitle() {
        statusItem?.button?.title = uptimeManager.compactUptime
    }
    
    @objc func openHistory() {
        if historyWindowController == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Uptime History"
            window.contentViewController = NSHostingController(rootView: UptimeHistoryView(historyManager: uptimeManager.getHistoryManager()))
            window.center()
            
            historyWindowController = NSWindowController(window: window)
            historyWindow = window
            
            // Handle window closing
            window.delegate = self
        }
        
        historyWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func openPreferences() {
        if preferencesWindowController == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 500),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Uptime Preferences"
            window.contentViewController = NSHostingController(rootView: PreferencesView())
            window.center()
            
            preferencesWindowController = NSWindowController(window: window)
            preferencesWindow = window
            
            // Handle window closing
            window.delegate = self
        }
        
        preferencesWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func openAbout() {
        if aboutWindowController == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 350, height: 450),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "About Uptime"
            window.contentViewController = NSHostingController(rootView: AboutView())
            window.center()
            
            aboutWindowController = NSWindowController(window: window)
            aboutWindow = window
            
            // Handle window closing
            window.delegate = self
        }
        
        aboutWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow == preferencesWindow {
            preferencesWindowController = nil
            preferencesWindow = nil
        } else if notification.object as? NSWindow == historyWindow {
            historyWindowController = nil
            historyWindow = nil
        } else if notification.object as? NSWindow == aboutWindow {
            aboutWindowController = nil
            aboutWindow = nil
        }
    }
}