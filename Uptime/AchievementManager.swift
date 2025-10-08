import Foundation
import UserNotifications
import Combine

struct Achievement: Codable, Identifiable {
    var id = UUID()
    let title: String
    let description: String
    let icon: String
    let threshold: TimeInterval
    let isUnlocked: Bool
    let unlockedDate: Date?
    
    static let achievements: [Achievement] = [
        Achievement(title: "First Steps", description: "Keep your system running for 1 hour", icon: "clock", threshold: 3600, isUnlocked: false, unlockedDate: nil),
        Achievement(title: "Getting Started", description: "Keep your system running for 6 hours", icon: "timer", threshold: 21600, isUnlocked: false, unlockedDate: nil),
        Achievement(title: "Day Walker", description: "Keep your system running for 24 hours", icon: "sun.max", threshold: 86400, isUnlocked: false, unlockedDate: nil),
        Achievement(title: "Weekend Warrior", description: "Keep your system running for 3 days", icon: "calendar", threshold: 259200, isUnlocked: false, unlockedDate: nil),
        Achievement(title: "Weekly Champion", description: "Keep your system running for 1 week", icon: "star", threshold: 604800, isUnlocked: false, unlockedDate: nil),
        Achievement(title: "Monthly Master", description: "Keep your system running for 1 month", icon: "crown", threshold: 2592000, isUnlocked: false, unlockedDate: nil),
        Achievement(title: "Uptime Legend", description: "Keep your system running for 6 months", icon: "trophy", threshold: 15552000, isUnlocked: false, unlockedDate: nil),
        Achievement(title: "The Eternal", description: "Keep your system running for 1 year", icon: "infinity", threshold: 31536000, isUnlocked: false, unlockedDate: nil)
    ]
}

class AchievementManager: ObservableObject {
    @Published var achievements: [Achievement] = []
    private let userDefaults = UserDefaults.standard
    private let achievementsKey = "unlockedAchievements"
    
    init() {
        // Initialize with default achievements first
        achievements = Achievement.achievements
        // Then load any saved progress
        loadAchievements()
    }
    
    func checkAchievements(for uptime: TimeInterval) {
        for i in 0..<achievements.count {
            if !achievements[i].isUnlocked && uptime >= achievements[i].threshold {
                unlockAchievement(at: i)
            }
        }
    }
    
    private func unlockAchievement(at index: Int) {
        guard index < achievements.count else { return }
        
        achievements[index] = Achievement(
            title: achievements[index].title,
            description: achievements[index].description,
            icon: achievements[index].icon,
            threshold: achievements[index].threshold,
            isUnlocked: true,
            unlockedDate: Date()
        )
        
        saveAchievements()
        sendAchievementNotification(achievements[index])
    }
    
    private func sendAchievementNotification(_ achievement: Achievement) {
        let content = UNMutableNotificationContent()
        content.title = "🏆 Achievement Unlocked!"
        content.body = "\(achievement.title): \(achievement.description)"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "achievement-\(achievement.id)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func loadAchievements() {
        if let data = userDefaults.data(forKey: achievementsKey),
           let savedAchievements = try? JSONDecoder().decode([Achievement].self, from: data) {
            
            // Merge saved achievements with default ones to handle new achievements
            var mergedAchievements: [Achievement] = []
            
            for defaultAchievement in Achievement.achievements {
                if let savedAchievement = savedAchievements.first(where: { $0.title == defaultAchievement.title }) {
                    mergedAchievements.append(savedAchievement)
                } else {
                    mergedAchievements.append(defaultAchievement)
                }
            }
            
            achievements = mergedAchievements
        }
    }
    
    private func saveAchievements() {
        if let data = try? JSONEncoder().encode(achievements) {
            userDefaults.set(data, forKey: achievementsKey)
        }
    }
}