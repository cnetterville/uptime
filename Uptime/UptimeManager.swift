import Foundation
import SwiftUI
import Combine

class UptimeManager: ObservableObject {
    @Published var uptimeSeconds: TimeInterval = 0
    @Published var bootDate: Date = Date()
    
    private var timer: Timer?
    
    var formattedUptime: String {
        let days = Int(uptimeSeconds) / 86400
        let hours = (Int(uptimeSeconds) % 86400) / 3600
        let minutes = (Int(uptimeSeconds) % 3600) / 60
        let seconds = Int(uptimeSeconds) % 60
        
        if days > 0 {
            return String(format: "%dd %02dh %02dm %02ds", days, hours, minutes, seconds)
        } else if hours > 0 {
            return String(format: "%02dh %02dm %02ds", hours, minutes, seconds)
        } else {
            return String(format: "%02dm %02ds", minutes, seconds)
        }
    }
    
    var compactUptime: String {
        let days = Int(uptimeSeconds) / 86400
        let hours = (Int(uptimeSeconds) % 86400) / 3600
        let minutes = (Int(uptimeSeconds) % 3600) / 60
        
        if days > 0 {
            return String(format: " ↑%dd %dh %dm", days, hours, minutes)
        } else if hours > 0 {
            return String(format: " ↑%dh %dm", hours, minutes)
        } else {
            return String(format: " ↑%dm", minutes)
        }
    }
    
    var bootTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: bootDate)
    }
    
    var uptimeProgress: Double {
        // Create a visual progress that cycles every 24 hours
        let hourProgress = (uptimeSeconds.truncatingRemainder(dividingBy: 86400)) / 86400
        return hourProgress
    }
    
    init() {
        updateUptime()
    }
    
    func startUpdating() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateUptime()
        }
    }
    
    func stopUpdating() {
        timer?.invalidate()
        timer = nil
    }
    
    func refresh() {
        updateUptime()
    }
    
    private func updateUptime() {
        var boottime = timeval()
        var size = MemoryLayout<timeval>.size
        
        if sysctlbyname("kern.boottime", &boottime, &size, nil, 0) == 0 {
            bootDate = Date(timeIntervalSince1970: TimeInterval(boottime.tv_sec))
            uptimeSeconds = Date().timeIntervalSince(bootDate)
        }
    }
}