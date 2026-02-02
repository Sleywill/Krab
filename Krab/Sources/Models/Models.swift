import Foundation
import SwiftUI

// MARK: - Weather
struct WeatherData: Codable, Equatable {
    let temperature: Double
    let condition: WeatherCondition
    let humidity: Int
    let windSpeed: Double
    let location: String
    let high: Double
    let low: Double
    let feelsLike: Double
    let uvIndex: Int
    let updatedAt: Date
    
    var temperatureString: String {
        String(format: "%.0f°", temperature)
    }
    
    var icon: String {
        condition.icon
    }
}

enum WeatherCondition: String, Codable {
    case sunny, cloudy, partlyCloudy, rainy, stormy, snowy, foggy, windy
    
    var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .rainy: return "cloud.rain.fill"
        case .stormy: return "cloud.bolt.rain.fill"
        case .snowy: return "cloud.snow.fill"
        case .foggy: return "cloud.fog.fill"
        case .windy: return "wind"
        }
    }
    
    var color: Color {
        switch self {
        case .sunny: return .yellow
        case .cloudy: return .gray
        case .partlyCloudy: return .orange
        case .rainy: return .blue
        case .stormy: return .purple
        case .snowy: return .cyan
        case .foggy: return .secondary
        case .windy: return .teal
        }
    }
}

// MARK: - Calendar
struct CalendarEvent: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let isAllDay: Bool
    let calendarColor: String
    
    var color: Color {
        Color(hex: calendarColor) ?? .accentColor
    }
    
    var timeString: String {
        if isAllDay {
            return "All day"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }
    
    var isNow: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }
}

// MARK: - Reminders
struct ReminderItem: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var notes: String?
    var dueDate: Date?
    var isCompleted: Bool
    var priority: Int
    var listName: String
    
    var priorityColor: Color {
        switch priority {
        case 1: return .red
        case 5: return .orange
        case 9: return .blue
        default: return .secondary
        }
    }
}

// MARK: - Quick Notes
struct QuickNote: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var color: String
    
    init(content: String = "", isPinned: Bool = false, color: String = "blue") {
        self.id = UUID()
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isPinned = isPinned
        self.color = color
    }
}

// MARK: - System Stats
struct SystemStats: Equatable {
    let cpuUsage: Double
    let memoryUsage: Double
    let memoryUsed: UInt64
    let memoryTotal: UInt64
    let batteryLevel: Int
    let isCharging: Bool
    let diskUsed: UInt64
    let diskTotal: UInt64
    let uptime: TimeInterval
    
    var memoryString: String {
        let used = Double(memoryUsed) / 1_073_741_824 // GB
        let total = Double(memoryTotal) / 1_073_741_824
        return String(format: "%.1f / %.1f GB", used, total)
    }
    
    var diskString: String {
        let used = Double(diskUsed) / 1_073_741_824
        let total = Double(diskTotal) / 1_073_741_824
        return String(format: "%.0f / %.0f GB", used, total)
    }
    
    var uptimeString: String {
        let hours = Int(uptime) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Now Playing
struct NowPlayingInfo: Equatable {
    let title: String
    let artist: String
    let album: String
    let artworkData: Data?
    let duration: TimeInterval
    let elapsedTime: TimeInterval
    let isPlaying: Bool
    let appName: String
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return elapsedTime / duration
    }
    
    var timeString: String {
        let elapsed = formatTime(elapsedTime)
        let total = formatTime(duration)
        return "\(elapsed) / \(total)"
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Pomodoro
enum PomodoroState: String, Codable {
    case idle
    case working
    case shortBreak
    case longBreak
    case paused
    
    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .working: return "Focus Time"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        case .paused: return "Paused"
        }
    }
    
    var color: Color {
        switch self {
        case .idle: return .secondary
        case .working: return .red
        case .shortBreak: return .green
        case .longBreak: return .blue
        case .paused: return .orange
        }
    }
}

// MARK: - Chat
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: ChatRole
    let content: String
    let timestamp = Date()
}

enum ChatRole: String, Codable {
    case user
    case assistant
    case system
}

// MARK: - Telegram
struct TelegramMessage: Identifiable, Codable, Equatable {
    let id: Int
    let chatId: Int64
    let chatTitle: String
    let senderName: String
    let text: String
    let date: Date
    let isOutgoing: Bool
    let hasVoice: Bool
    let isRead: Bool
}

// MARK: - Widget Configuration
struct WidgetConfig: Codable, Identifiable, Equatable {
    let id: UUID
    var type: WidgetType
    var position: CGPoint
    var size: CGSize
    var isVisible: Bool
    var refreshInterval: TimeInterval
    var customSettings: [String: String]
    
    init(type: WidgetType, position: CGPoint = .zero, size: CGSize = CGSize(width: 200, height: 150)) {
        self.id = UUID()
        self.type = type
        self.position = position
        self.size = size
        self.isVisible = true
        self.refreshInterval = 60
        self.customSettings = [:]
    }
}

enum WidgetType: String, Codable, CaseIterable, Identifiable {
    case weather
    case calendar
    case reminders
    case notes
    case music
    case systemStats
    case pomodoro
    case quickActions
    case aiChat
    case telegram
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .weather: return "Weather"
        case .calendar: return "Calendar"
        case .reminders: return "Reminders"
        case .notes: return "Quick Notes"
        case .music: return "Now Playing"
        case .systemStats: return "System Stats"
        case .pomodoro: return "Pomodoro"
        case .quickActions: return "Quick Actions"
        case .aiChat: return "AI Chat"
        case .telegram: return "Telegram"
        }
    }
    
    var icon: String {
        switch self {
        case .weather: return "cloud.sun.fill"
        case .calendar: return "calendar"
        case .reminders: return "checklist"
        case .notes: return "note.text"
        case .music: return "music.note"
        case .systemStats: return "cpu"
        case .pomodoro: return "timer"
        case .quickActions: return "bolt.fill"
        case .aiChat: return "bubble.left.and.bubble.right.fill"
        case .telegram: return "paperplane.fill"
        }
    }
    
    var defaultSize: CGSize {
        switch self {
        case .weather: return CGSize(width: 180, height: 200)
        case .calendar: return CGSize(width: 280, height: 300)
        case .reminders: return CGSize(width: 250, height: 280)
        case .notes: return CGSize(width: 220, height: 200)
        case .music: return CGSize(width: 280, height: 120)
        case .systemStats: return CGSize(width: 200, height: 250)
        case .pomodoro: return CGSize(width: 180, height: 180)
        case .quickActions: return CGSize(width: 200, height: 150)
        case .aiChat: return CGSize(width: 350, height: 400)
        case .telegram: return CGSize(width: 300, height: 350)
        }
    }
}

// MARK: - Quick Actions
struct QuickAction: Identifiable, Codable {
    let id: UUID
    var name: String
    var icon: String
    var command: String
    var color: String
    
    init(name: String, icon: String, command: String, color: String = "blue") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.command = command
        self.color = color
    }
}
