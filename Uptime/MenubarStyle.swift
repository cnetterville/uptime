import Foundation

enum MenubarStyle: String, CaseIterable, Codable, Identifiable {
    case compact = "compact"
    case normal = "normal"
    case detailed = "detailed"
    case minimal = "minimal"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .compact: return "Compact"
        case .normal: return "Normal"
        case .detailed: return "Detailed"
        case .minimal: return "Minimal"
        }
    }
    
    var description: String {
        switch self {
        case .compact: return "↑ 1d 2h 34m"
        case .normal: return "↑ 1d 2h 34m"
        case .detailed: return "↑ 1d 2h 34m 56s"
        case .minimal: return "↑ 1d 2h"
        }
    }
}