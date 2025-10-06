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

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    private var uptimeManager = UptimeManager()
    private var cancellable: AnyCancellable?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the dock icon since this is a menubar-only app
        NSApp.setActivationPolicy(.accessory)
        
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.action = #selector(statusBarButtonClicked)
            button.target = self
            
            // Set initial title with monospaced font
            button.title = uptimeManager.compactUptime
            button.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        }
        
        // Start the uptime manager
        uptimeManager.startUpdating()
        
        // Subscribe to uptime changes to update the menubar (throttled to reduce jitter)
        cancellable = uptimeManager.$uptimeSeconds
            .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                self?.updateStatusBarTitle()
            }
        
        // Create the popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 340, height: 200)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: UptimeMenuView())
    }
    
    private func updateStatusBarTitle() {
        statusItem?.button?.title = uptimeManager.compactUptime
    }
    
    @objc func statusBarButtonClicked() {
        guard let button = statusItem?.button else { return }
        
        if popover?.isShown == true {
            popover?.performClose(nil)
        } else {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
}