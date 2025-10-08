//
//  PreferencesView.swift
//  Uptime
//
//  Created by Curtis Netterville on 10/6/25.
//

import SwiftUI
import ServiceManagement

struct PreferencesView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("updateFrequency") private var updateFrequency = 1.0
    @AppStorage("showArrow") private var showArrow = true
    @AppStorage("milestoneNotifications") private var milestoneNotifications = true
    @AppStorage("timeUnitFormat") private var timeUnitFormat: TimeUnit = .automatic
    @AppStorage("showMinutesInMenubar") private var showMinutesInMenubar = true
    @AppStorage("use24HourFormat") private var use24HourFormat = false
    @AppStorage("menubarStyle") private var menubarStyle: MenubarStyle = .compact
    @AppStorage("showSystemStats") private var showSystemStats = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Image(systemName: "gear")
                        .font(.title2)
                        .foregroundStyle(.primary)
                    
                    Text("Preferences")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Divider()
                    .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 20) {
                    // Startup section
                    PreferenceSection(title: "Startup") {
                        Toggle("Launch at login", isOn: $launchAtLogin)
                            .onChange(of: launchAtLogin, perform: setLaunchAtLogin)
                    }
                    
                    // Display section
                    PreferenceSection(title: "Display Format") {
                        VStack(alignment: .leading, spacing: 16) {
                            // Time unit format
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Time Format")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Picker("Time Format", selection: $timeUnitFormat) {
                                    ForEach(TimeUnit.allCases) { unit in
                                        VStack(alignment: .leading) {
                                            Text(unit.displayName)
                                            Text(unit.description)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .tag(unit)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            Divider()
                            
                            // Show/hide options
                            VStack(spacing: 12) {
                                Toggle("Show minutes in menubar", isOn: $showMinutesInMenubar)
                                    .help("Include minutes in the compact menubar display")
                                
                                Toggle("Show arrow in menubar", isOn: $showArrow)
                                    .help("Display the up arrow (↑) indicator in the menubar")
                                
                                Toggle("24-hour format for boot time", isOn: $use24HourFormat)
                                    .help("Use 24-hour time format instead of AM/PM")
                            }
                        }
                    }
                    
                    // Update frequency section
                    PreferenceSection(title: "Update Frequency") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Update every:")
                                Picker("Update Frequency", selection: $updateFrequency) {
                                    Text("1 second").tag(1.0)
                                    Text("5 seconds").tag(5.0)
                                    Text("30 seconds").tag(30.0)
                                    Text("1 minute").tag(60.0)
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            Text("Lower frequencies save battery but reduce accuracy")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    // Notifications section
                    PreferenceSection(title: "Notifications") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Milestone notifications", isOn: $milestoneNotifications)
                                .help("Get notified when reaching uptime milestones (1 day, 1 week, etc.)")
                            
                            Text("Receive notifications for: 1 day, 1 week, 1 month, 3 months, 6 months, 1 year")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    // Appearance section
                    PreferenceSection(title: "Appearance") {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Menubar Style")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Picker("Menubar Style", selection: $menubarStyle) {
                                    ForEach(MenubarStyle.allCases) { style in
                                        VStack(alignment: .leading) {
                                            Text(style.displayName)
                                            Text(style.description)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .tag(style)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            Divider()
                            
                            Toggle("Show system stats in popover", isOn: $showSystemStats)
                                .help("Display CPU, memory, and disk usage in the popover")
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 20)
                
                // Close button
                HStack {
                    Spacer()
                    Button("Close") {
                        NSApplication.shared.keyWindow?.close()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(width: 480, height: 580)
        .background(.ultraThinMaterial)
    }
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if #available(macOS 13.0, *) {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                print("Launch at login \(enabled ? "enabled" : "disabled")")
            } else {
                // Enhanced fallback for older versions
                let helperBundleIdentifier = "com.curtisnet.Uptime.LaunchHelper"
                if SMLoginItemSetEnabled(helperBundleIdentifier as CFString, enabled) {
                    print("Launch at login \(enabled ? "enabled" : "disabled") via SMLoginItemSetEnabled")
                } else {
                    print("Failed to set launch at login")
                }
            }
        } catch {
            print("Error setting launch at login: \(error.localizedDescription)")
            // Reset the toggle if it failed
            DispatchQueue.main.async {
                launchAtLogin = !enabled
            }
        }
    }
}

struct PreferenceSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    PreferencesView()
}