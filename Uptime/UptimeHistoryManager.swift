//
//  UptimeHistoryManager.swift
//  Uptime
//
//  Created by Curtis Netterville on 10/6/25.
//

import Foundation
import Combine

struct UptimeSession: Codable, Identifiable {
    let id = UUID()
    let bootDate: Date
    let endDate: Date?
    let duration: TimeInterval
    let isCurrentSession: Bool
    
    var formattedDuration: String {
        let days = Int(duration) / 86400
        let hours = (Int(duration) % 86400) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if days > 0 {
            return String(format: "%dd %02dh %02dm", days, hours, minutes)
        } else if hours > 0 {
            return String(format: "%02dh %02dm", hours, minutes)
        } else {
            return String(format: "%02dm", minutes)
        }
    }
    
    var formattedBootDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: bootDate)
    }
    
    var formattedEndDate: String {
        guard let endDate = endDate else { return "Current session" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: endDate)
    }
}

class UptimeHistoryManager: ObservableObject {
    @Published var sessions: [UptimeSession] = []
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "uptimeSessions"
    private var currentSessionBootDate: Date?
    
    var longestSession: UptimeSession? {
        sessions.max(by: { $0.duration < $1.duration })
    }
    
    var averageSessionDuration: TimeInterval {
        guard !sessions.isEmpty else { return 0 }
        let totalDuration = sessions.reduce(0) { $0 + $1.duration }
        return totalDuration / Double(sessions.count)
    }
    
    var totalUptime: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }
    
    init() {
        loadSessions()
    }
    
    func trackCurrentSession(bootDate: Date, currentUptime: TimeInterval) {
        // Check if this is a new boot (different boot date)
        if let lastBootDate = currentSessionBootDate, 
           abs(lastBootDate.timeIntervalSince(bootDate)) > 60 { // 1 minute tolerance
            // Previous session ended, save it
            let previousSession = UptimeSession(
                bootDate: lastBootDate,
                endDate: Date(),
                duration: Date().timeIntervalSince(lastBootDate),
                isCurrentSession: false
            )
            addSession(previousSession)
        }
        
        // Update current session
        currentSessionBootDate = bootDate
        updateCurrentSession(bootDate: bootDate, uptime: currentUptime)
    }
    
    private func updateCurrentSession(bootDate: Date, uptime: TimeInterval) {
        // Remove any existing current session
        sessions.removeAll { $0.isCurrentSession }
        
        // Add updated current session
        let currentSession = UptimeSession(
            bootDate: bootDate,
            endDate: nil,
            duration: uptime,
            isCurrentSession: true
        )
        
        sessions.append(currentSession)
        saveSessions()
    }
    
    private func addSession(_ session: UptimeSession) {
        sessions.append(session)
        
        // Keep only the last 50 sessions to prevent unbounded growth
        if sessions.count > 50 {
            sessions = Array(sessions.suffix(50))
        }
        
        saveSessions()
    }
    
    private func loadSessions() {
        if let data = userDefaults.data(forKey: sessionsKey),
           let decodedSessions = try? JSONDecoder().decode([UptimeSession].self, from: data) {
            sessions = decodedSessions
        }
    }
    
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            userDefaults.set(encoded, forKey: sessionsKey)
        }
    }
    
    func clearHistory() {
        sessions.removeAll { !$0.isCurrentSession }
        saveSessions()
    }
    
    func exportHistory() -> String {
        var csv = "Boot Date,End Date,Duration (seconds),Duration (formatted),Status\n"
        
        for session in sessions.sorted(by: { $0.bootDate > $1.bootDate }) {
            let endDateString = session.endDate?.ISO8601Format() ?? "Current"
            let status = session.isCurrentSession ? "Current" : "Completed"
            
            csv += "\(session.bootDate.ISO8601Format()),\(endDateString),\(session.duration),\(session.formattedDuration),\(status)\n"
        }
        
        return csv
    }
}