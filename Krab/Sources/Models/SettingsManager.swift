import SwiftUI
import Combine

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    // MARK: - Appearance
    @AppStorage("theme") var theme: ThemeMode = .dark
    @AppStorage("accentColorHex") var accentColorHex: String = "#FF6B6B"
    @AppStorage("backgroundOpacity") var backgroundOpacity: Double = 0.85
    @AppStorage("blurRadius") var blurRadius: Double = 20
    @AppStorage("cornerRadius") var cornerRadius: Double = 16
    @AppStorage("fontSize") var fontSize: Double = 14
    @AppStorage("fontFamily") var fontFamily: String = "SF Pro"
    @AppStorage("showAnimations") var showAnimations: Bool = true
    @AppStorage("compactMode") var compactMode: Bool = false
    
    // MARK: - Widget Settings
    @AppStorage("widgetConfigs") var widgetConfigsData: Data = Data()
    @AppStorage("enabledWidgets") var enabledWidgetsData: Data = Data()
    
    // MARK: - Weather
    @AppStorage("weatherLocation") var weatherLocation: String = "auto"
    @AppStorage("weatherUnit") var weatherUnit: TemperatureUnit = .celsius
    @AppStorage("weatherRefreshInterval") var weatherRefreshInterval: TimeInterval = 1800
    
    // MARK: - Calendar
    @AppStorage("calendarDaysAhead") var calendarDaysAhead: Int = 7
    @AppStorage("showAllDayEvents") var showAllDayEvents: Bool = true
    @AppStorage("enabledCalendars") var enabledCalendarsData: Data = Data()
    
    // MARK: - Pomodoro
    @AppStorage("pomodoroWorkDuration") var pomodoroWorkDuration: TimeInterval = 25 * 60
    @AppStorage("pomodoroShortBreak") var pomodoroShortBreak: TimeInterval = 5 * 60
    @AppStorage("pomodoroLongBreak") var pomodoroLongBreak: TimeInterval = 15 * 60
    @AppStorage("pomodoroLongBreakInterval") var pomodoroLongBreakInterval: Int = 4
    @AppStorage("pomodoroAutoStart") var pomodoroAutoStart: Bool = false
    @AppStorage("pomodoroSound") var pomodoroSound: Bool = true
    
    // MARK: - AI Settings
    @AppStorage("aiEndpoint") var aiEndpoint: String = "http://localhost:3000/api/chat"
    @AppStorage("aiModel") var aiModel: String = "claude-3-sonnet"
    @AppStorage("aiSystemPrompt") var aiSystemPrompt: String = "You are a helpful assistant integrated into a macOS widget called Krab. Be concise and friendly."
    @AppStorage("aiMaxTokens") var aiMaxTokens: Int = 1000
    @AppStorage("enableVoiceResponses") var enableVoiceResponses: Bool = true
    
    // MARK: - Telegram
    @AppStorage("telegramBotToken") var telegramBotToken: String = ""
    @AppStorage("telegramChatId") var telegramChatId: String = ""
    @AppStorage("telegramPollingInterval") var telegramPollingInterval: TimeInterval = 5
    @AppStorage("telegramNotifications") var telegramNotifications: Bool = true
    
    // MARK: - Notifications
    @AppStorage("enableNotifications") var enableNotifications: Bool = true
    @AppStorage("notificationSound") var notificationSound: Bool = true
    @AppStorage("quietHoursStart") var quietHoursStart: Int = 23
    @AppStorage("quietHoursEnd") var quietHoursEnd: Int = 8
    
    // MARK: - Keyboard Shortcuts
    @AppStorage("globalHotkey") var globalHotkey: String = "⌥Space"
    @AppStorage("voiceHotkey") var voiceHotkey: String = "⌥V"
    @AppStorage("quickNoteHotkey") var quickNoteHotkey: String = "⌥N"
    
    // MARK: - Quick Actions
    @AppStorage("quickActionsData") var quickActionsData: Data = Data()
    
    // MARK: - Computed Properties
    var accentColor: Color {
        get { Color(hex: accentColorHex) ?? .red }
        set { accentColorHex = newValue.toHex() ?? "#FF6B6B" }
    }
    
    var widgetConfigs: [WidgetConfig] {
        get {
            guard let configs = try? JSONDecoder().decode([WidgetConfig].self, from: widgetConfigsData) else {
                return defaultWidgetConfigs
            }
            return configs
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                widgetConfigsData = data
            }
        }
    }
    
    var enabledWidgets: Set<WidgetType> {
        get {
            guard let widgets = try? JSONDecoder().decode(Set<WidgetType>.self, from: enabledWidgetsData) else {
                return Set(WidgetType.allCases)
            }
            return widgets
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                enabledWidgetsData = data
            }
        }
    }
    
    var quickActions: [QuickAction] {
        get {
            guard let actions = try? JSONDecoder().decode([QuickAction].self, from: quickActionsData) else {
                return defaultQuickActions
            }
            return actions
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                quickActionsData = data
            }
        }
    }
    
    // MARK: - Defaults
    private var defaultWidgetConfigs: [WidgetConfig] {
        [
            WidgetConfig(type: .weather, position: CGPoint(x: 0, y: 0)),
            WidgetConfig(type: .calendar, position: CGPoint(x: 1, y: 0)),
            WidgetConfig(type: .systemStats, position: CGPoint(x: 0, y: 1)),
            WidgetConfig(type: .pomodoro, position: CGPoint(x: 1, y: 1)),
            WidgetConfig(type: .music, position: CGPoint(x: 0, y: 2)),
            WidgetConfig(type: .notes, position: CGPoint(x: 1, y: 2)),
        ]
    }
    
    private var defaultQuickActions: [QuickAction] {
        [
            QuickAction(name: "Screenshot", icon: "camera.fill", command: "screencapture -ic"),
            QuickAction(name: "Terminal", icon: "terminal.fill", command: "open -a Terminal"),
            QuickAction(name: "Lock Screen", icon: "lock.fill", command: "pmset displaysleepnow"),
            QuickAction(name: "Toggle WiFi", icon: "wifi", command: "networksetup -setairportpower en0 toggle"),
        ]
    }
    
    // MARK: - Methods
    func resetToDefaults() {
        theme = .dark
        accentColorHex = "#FF6B6B"
        backgroundOpacity = 0.85
        blurRadius = 20
        cornerRadius = 16
        fontSize = 14
        showAnimations = true
        compactMode = false
        widgetConfigsData = Data()
        enabledWidgetsData = Data()
    }
    
    func isWidgetEnabled(_ type: WidgetType) -> Bool {
        enabledWidgets.contains(type)
    }
    
    func toggleWidget(_ type: WidgetType) {
        var widgets = enabledWidgets
        if widgets.contains(type) {
            widgets.remove(type)
        } else {
            widgets.insert(type)
        }
        enabledWidgets = widgets
    }
}

// MARK: - Supporting Types
enum ThemeMode: String, CaseIterable {
    case light, dark, auto
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .auto: return "System"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .auto: return nil
        }
    }
}

enum TemperatureUnit: String, CaseIterable {
    case celsius, fahrenheit
    
    var symbol: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }
}
