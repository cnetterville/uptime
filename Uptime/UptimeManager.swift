import Foundation
import SwiftUI
import Combine
import UserNotifications

class UptimeManager: ObservableObject {
    @Published var uptimeSeconds: TimeInterval = 0
    @Published var bootDate: Date = Date()
    
    private var timer: Timer?
    private var lastMilestoneNotified: TimeInterval = 0
    private var historyManager = UptimeHistoryManager()
    
    // Milestones in seconds
    private let milestones: [TimeInterval] = [
        86400,      // 1 day
        604800,     // 1 week
        2592000,    // 1 month (30 days)
        7776000,    // 3 months
        15552000,   // 6 months
        31536000    // 1 year
    ]
    
    var formattedUptime: String {
        let timeFormat = TimeUnit(rawValue: UserDefaults.standard.string(forKey: "timeUnitFormat") ?? "automatic") ?? .automatic
        
        return formatTime(
            uptime: uptimeSeconds,
            format: timeFormat,
            includeSeconds: false,
            includeMinutes: true,
            isCompact: false,
            forceSpaces: false
        )
    }
    
    var detailedUptime: String {
        let timeFormat = TimeUnit(rawValue: UserDefaults.standard.string(forKey: "timeUnitFormat") ?? "automatic") ?? .automatic
        
        return formatTime(
            uptime: uptimeSeconds,
            format: timeFormat,
            includeSeconds: true,
            includeMinutes: true,
            isCompact: false,
            forceSpaces: false
        )
    }
    
    var compactUptime: String {
        let showArrow = UserDefaults.standard.object(forKey: "showArrow") as? Bool ?? true
        let showMinutes = UserDefaults.standard.object(forKey: "showMinutesInMenubar") as? Bool ?? true
        let timeFormat = TimeUnit(rawValue: UserDefaults.standard.string(forKey: "timeUnitFormat") ?? "automatic") ?? .automatic
        let menubarStyle = MenubarStyle(rawValue: UserDefaults.standard.string(forKey: "menubarStyle") ?? "compact") ?? .compact
        let arrow = showArrow ? "↑" : ""
        
        // Apply menubar style settings
        let (includeSeconds, includeMinutes, useSpaces) = getStyleSettings(for: menubarStyle, showMinutes: showMinutes)
        
        return formatTime(
            uptime: uptimeSeconds,
            format: timeFormat,
            includeSeconds: includeSeconds,
            includeMinutes: includeMinutes,
            isCompact: true,
            arrow: arrow,
            forceSpaces: useSpaces
        )
    }
    
    private func getStyleSettings(for style: MenubarStyle, showMinutes: Bool) -> (includeSeconds: Bool, includeMinutes: Bool, useSpaces: Bool) {
        switch style {
        case .compact:
            return (false, showMinutes, false)
        case .normal:
            return (false, showMinutes, true)
        case .detailed:
            return (true, true, false)
        case .minimal:
            return (false, false, false)
        }
    }
    
    var bootTime: String {
        let use24Hour = UserDefaults.standard.object(forKey: "use24HourFormat") as? Bool ?? false
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        if use24Hour {
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "M/d/yy, HH:mm"
        }
        
        return formatter.string(from: bootDate)
    }
    
    var uptimeProgress: Double {
        // Create a visual progress that cycles every 24 hours
        let hourProgress = (uptimeSeconds.truncatingRemainder(dividingBy: 86400)) / 86400
        return hourProgress
    }
    
    var longestUptimeSession: String {
        guard let longest = historyManager.longestSession else { return "N/A" }
        return longest.formattedDuration
    }
    
    init() {
        updateUptime()
        requestNotificationPermission()
    }
    
    deinit {
        // Ensure proper cleanup with more detailed logging
        print("UptimeManager: Starting cleanup...")
        stopUpdating()
        historyManager.saveCurrentSession() // Ensure current session is saved
        print("UptimeManager: Cleanup completed")
    }
    
    func startUpdating() {
        // Stop any existing timer first
        stopUpdating()
        
        let frequency = UserDefaults.standard.double(forKey: "updateFrequency")
        let interval = max(frequency, 0.5) // Minimum 0.5 seconds to prevent excessive updates
        
        // Use weak self to prevent retain cycle
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateUptime()
        }
        
        // Add to run loop with higher priority for better accuracy
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
        
        print("UptimeManager: Started updating every \(interval) seconds")
    }
    
    func stopUpdating() {
        timer?.invalidate()
        timer = nil
    }
    
    func refresh() {
        updateUptime()
    }
    
    func getHistoryManager() -> UptimeHistoryManager {
        return historyManager
    }
    
    private func updateUptime() {
        var boottime = timeval()
        var size = MemoryLayout<timeval>.size
        
        guard sysctlbyname("kern.boottime", &boottime, &size, nil, 0) == 0 else {
            print("Error: Failed to retrieve system boot time")
            return
        }
        
        bootDate = Date(timeIntervalSince1970: TimeInterval(boottime.tv_sec))
        uptimeSeconds = Date().timeIntervalSince(bootDate)
        
        // Track this session in history
        historyManager.trackCurrentSession(bootDate: bootDate, currentUptime: uptimeSeconds)
        
        // Check for milestones
        checkMilestones()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
            if granted {
                print("Notification permission granted")
            }
        }
    }
    
    private func checkMilestones() {
        let notificationsEnabled = UserDefaults.standard.object(forKey: "milestoneNotifications") as? Bool ?? true
        guard notificationsEnabled else { return }
        
        for milestone in milestones {
            if uptimeSeconds >= milestone && lastMilestoneNotified < milestone {
                sendMilestoneNotification(for: milestone)
                lastMilestoneNotified = milestone
                break // Only send one notification at a time
            }
        }
    }
    
    private func sendMilestoneNotification(for milestone: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Uptime Milestone Reached! 🎉"
        content.body = "Your system has been running for \(formatMilestone(milestone))"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "milestone-\(milestone)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func formatMilestone(_ seconds: TimeInterval) -> String {
        let days = Int(seconds) / 86400
        
        if days >= 365 {
            return "1 year"
        } else if days >= 180 {
            return "6 months"
        } else if days >= 90 {
            return "3 months"
        } else if days >= 30 {
            return "1 month"
        } else if days >= 7 {
            return "1 week"
        } else {
            return "1 day"
        }
    }
    
    private func formatTime(uptime: TimeInterval, format: TimeUnit, includeSeconds: Bool, includeMinutes: Bool, isCompact: Bool, arrow: String = "", forceSpaces: Bool = false) -> String {
        let days = Int(uptime) / 86400
        let hours = (Int(uptime) % 86400) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        let seconds = Int(uptime) % 60
        
        // Determine spacing based on style
        let space: String
        if forceSpaces {
            space = " "
        } else {
            space = (isCompact || format == .compactFormat) ? "" : " "
        }
        
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
            // CompactFormat always uses no spaces regardless of forceSpaces
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