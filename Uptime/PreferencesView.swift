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
    
    var body: some View {
        VStack(spacing: 20) {
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Startup section
                    PreferenceSection(title: "Startup") {
                        Toggle("Launch at login", isOn: $launchAtLogin)
                            .onChange(of: launchAtLogin, perform: setLaunchAtLogin)
                    }
                    
                    // Display section
                    PreferenceSection(title: "Display Format") {
                        VStack(alignment: .leading, spacing: 12) {
                            // Time unit format
                            VStack(alignment: .leading, spacing: 6) {
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
                            Toggle("Show minutes in menubar", isOn: $showMinutesInMenubar)
                                .help("Include minutes in the compact menubar display")
                            
                            Toggle("Show arrow in menubar", isOn: $showArrow)
                                .help("Display the up arrow (↑) indicator in the menubar")
                            
                            Toggle("24-hour format for boot time", isOn: $use24HourFormat)
                                .help("Use 24-hour time format instead of AM/PM")
                        }
                    }
                    
                    // Update frequency section
                    PreferenceSection(title: "Update Frequency") {
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
                    
                    // Notifications section
                    PreferenceSection(title: "Notifications") {
                        Toggle("Milestone notifications", isOn: $milestoneNotifications)
                            .help("Get notified when reaching uptime milestones (1 day, 1 week, etc.)")
                        
                        Text("Receive notifications for: 1 day, 1 week, 1 month, 3 months, 6 months, 1 year")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    
                    // Preview section
                    PreferenceSection(title: "Preview") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current formatting:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                Text("Menubar:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text(formatPreviewMenubar())
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .fontDesign(.monospaced)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // Close button
            HStack {
                Spacer()
                Button("Close") {
                    NSApplication.shared.keyWindow?.close()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 450, height: 500)
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
            } else {
                // Fallback for older versions
                print("Launch at login requires macOS 13.0 or later")
            }
        } catch {
            print("Error setting launch at login: \(error.localizedDescription)")
        }
    }
    
    private func formatPreviewMenubar() -> String {
        let arrow = showArrow ? "↑" : ""
        let sampleUptime: TimeInterval = 356400 // 4 days, 3 hours, 0 minutes
        
        return formatTimeForDisplay(
            uptime: sampleUptime,
            format: timeUnitFormat,
            includeSeconds: false,
            includeMinutes: showMinutesInMenubar,
            isCompact: true,
            arrow: arrow
        )
    }
    
    private func formatPreviewPopover() -> String {
        let sampleUptime: TimeInterval = 356400 // 4 days, 3 hours, 0 minutes
        
        return formatTimeForDisplay(
            uptime: sampleUptime,
            format: timeUnitFormat,
            includeSeconds: false,
            includeMinutes: true,
            isCompact: false,
            arrow: ""
        )
    }
    
    private func formatTimeForDisplay(uptime: TimeInterval, format: TimeUnit, includeSeconds: Bool, includeMinutes: Bool, isCompact: Bool, arrow: String) -> String {
        let days = Int(uptime) / 86400
        let hours = (Int(uptime) % 86400) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        let seconds = Int(uptime) % 60
        
        let space = (isCompact && format == .compactFormat) ? "" : " "
        let prefix = arrow.isEmpty ? (isCompact ? " " : "") : (isCompact ? " \(arrow)" : "")
        
        switch format {
        case .automatic:
            if days > 0 {
                if includeSeconds {
                    return "\(prefix)\(days)d\(space)\(String(format: "%02d", hours))h\(space)\(includeMinutes ? "\(String(format: "%02d", minutes))m\(space)" : "")\(String(format: "%02d", seconds))s"
                } else {
                    return "\(prefix)\(days)d\(space)\(String(format: "%02d", hours))h\(space)\(includeMinutes ? "\(String(format: "%02d", minutes))m" : "")"
                }
            } else if hours > 0 {
                if includeSeconds {
                    return "\(prefix)\(String(format: "%02d", hours))h\(space)\(includeMinutes ? "\(String(format: "%02d", minutes))m\(space)" : "")\(String(format: "%02d", seconds))s"
                } else {
                    return "\(prefix)\(String(format: "%02d", hours))h\(space)\(includeMinutes ? "\(String(format: "%02d", minutes))m" : "")"
                }
            } else {
                if includeSeconds {
                    return "\(prefix)\(String(format: "%02d", minutes))m\(space)\(String(format: "%02d", seconds))s"
                } else {
                    return "\(prefix)\(String(format: "%02d", minutes))m"
                }
            }
            
        case .alwaysShowDays:
            if includeSeconds {
                return "\(prefix)\(days)d\(space)\(String(format: "%02d", hours))h\(space)\(includeMinutes ? "\(String(format: "%02d", minutes))m\(space)" : "")\(String(format: "%02d", seconds))s"
            } else {
                return "\(prefix)\(days)d\(space)\(String(format: "%02d", hours))h\(space)\(includeMinutes ? "\(String(format: "%02d", minutes))m" : "")"
            }
            
        case .alwaysShowHours:
            let totalHours = days * 24 + hours
            if includeSeconds {
                return "\(prefix)\(String(format: "%02d", totalHours))h\(space)\(includeMinutes ? "\(String(format: "%02d", minutes))m\(space)" : "")\(String(format: "%02d", seconds))s"
            } else {
                return "\(prefix)\(String(format: "%02d", totalHours))h\(space)\(includeMinutes ? "\(String(format: "%02d", minutes))m" : "")"
            }
            
        case .compactFormat:
            if days > 0 {
                if includeSeconds {
                    return "\(prefix)\(days)d\(String(format: "%02d", hours))h\(includeMinutes ? "\(String(format: "%02d", minutes))m" : "")\(String(format: "%02d", seconds))s"
                } else {
                    return "\(prefix)\(days)d\(String(format: "%02d", hours))h\(includeMinutes ? "\(String(format: "%02d", minutes))m" : "")"
                }
            } else if hours > 0 {
                if includeSeconds {
                    return "\(prefix)\(String(format: "%02d", hours))h\(includeMinutes ? "\(String(format: "%02d", minutes))m" : "")\(String(format: "%02d", seconds))s"
                } else {
                    return "\(prefix)\(String(format: "%02d", hours))h\(includeMinutes ? "\(String(format: "%02d", minutes))m" : "")"
                }
            } else {
                if includeSeconds {
                    return "\(prefix)\(String(format: "%02d", minutes))m\(String(format: "%02d", seconds))s"
                } else {
                    return "\(prefix)\(String(format: "%02d", minutes))m"
                }
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            content
        }
        .padding(.bottom, 8)
    }
}

#Preview {
    PreferencesView()
}