//
//  TimeUnit.swift
//  Uptime
//
//  Created by Curtis Netterville on 10/6/25.
//

import Foundation

enum TimeUnit: String, CaseIterable, Codable, Identifiable {
    case automatic = "automatic"
    case alwaysShowDays = "alwaysShowDays"
    case alwaysShowHours = "alwaysShowHours"
    case compactFormat = "compactFormat"
    
    var id: String { 
        return self.rawValue 
    }
    
    var displayName: String {
        switch self {
        case .automatic:
            return "Automatic (smart formatting)"
        case .alwaysShowDays:
            return "Always show days"
        case .alwaysShowHours:
            return "Always show hours"
        case .compactFormat:
            return "Compact format"
        }
    }
    
    var description: String {
        switch self {
        case .automatic:
            return "Show the most relevant units"
        case .alwaysShowDays:
            return "0d 12h 34m 56s"
        case .alwaysShowHours:
            return "12h 34m 56s"
        case .compactFormat:
            return "12h34m56s"
        }
    }
}