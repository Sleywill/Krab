import Foundation
import SwiftUI
import AppKit
import Carbon

// MARK: - NotificationManager
@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    func requestPermissions() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }
    
    func showNotification(title: String, body: String, sound: Bool = true) {
        let settings = SettingsManager.shared
        
        guard settings.enableNotifications else { return }
        
        // Check quiet hours
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= settings.quietHoursStart || hour < settings.quietHoursEnd {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        if sound && settings.notificationSound {
            content.sound = .default
        }
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - PermissionsManager
@MainActor
class PermissionsManager: ObservableObject {
    static let shared = PermissionsManager()
    
    @Published var calendarAuthorized = false
    @Published var microphoneAuthorized = false
    @Published var speechAuthorized = false
    @Published var notificationsAuthorized = false
    
    func requestAllPermissions() {
        Task {
            await CalendarService.shared.requestAccess()
            calendarAuthorized = CalendarService.shared.isAuthorized
            
            let voicePermissions = await VoiceService.shared.requestPermissions()
            microphoneAuthorized = voicePermissions
            speechAuthorized = voicePermissions
            
            notificationsAuthorized = await NotificationManager.shared.requestPermissions()
        }
    }
    
    func checkPermissions() {
        calendarAuthorized = CalendarService.shared.isAuthorized
    }
}

// MARK: - HotkeyManager
class HotkeyManager {
    static let shared = HotkeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    
    func registerGlobalHotkey() {
        // Register Option+Space as global hotkey
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let handler: EventHandlerUPP = { _, event, _ -> OSStatus in
            NotificationCenter.default.post(name: .globalHotkeyPressed, object: nil)
            return noErr
        }
        
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, nil)
        
        var hotKeyID = EventHotKeyID(signature: OSType(0x4B524142), id: 1) // "KRAB"
        
        RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
    
    func unregisterGlobalHotkey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
        }
    }
}

extension Notification.Name {
    static let globalHotkeyPressed = Notification.Name("globalHotkeyPressed")
}

// MARK: - Color Extensions
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let length = hexSanitized.count
        
        if length == 6 {
            self.init(
                red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgb & 0x0000FF) / 255.0
            )
        } else if length == 8 {
            self.init(
                red: Double((rgb & 0xFF000000) >> 24) / 255.0,
                green: Double((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: Double((rgb & 0x0000FF00) >> 8) / 255.0,
                opacity: Double(rgb & 0x000000FF) / 255.0
            )
        } else {
            return nil
        }
    }
    
    func toHex() -> String? {
        guard let components = NSColor(self).cgColor.components else {
            return nil
        }
        
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    static let krabRed = Color(hex: "#FF6B6B")!
    static let krabOrange = Color(hex: "#FF8E53")!
    static let krabGradientStart = Color(hex: "#FF6B6B")!
    static let krabGradientEnd = Color(hex: "#FF8E53")!
    
    static var krabGradient: LinearGradient {
        LinearGradient(
            colors: [.krabRed, .krabOrange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - View Extensions
extension View {
    func glassBackground(
        opacity: Double = 0.15,
        cornerRadius: Double = 16,
        blur: Double = 20
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(opacity * 5)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(opacity))
            )
    }
    
    func cardStyle(cornerRadius: Double = 16) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
    
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Date Extensions
extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    var relativeString: String {
        if isToday {
            return "Today"
        } else if isTomorrow {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: self)
        }
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    var dateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - Animation Extensions
extension Animation {
    static let krabSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let krabBouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
    static let krabSmooth = Animation.easeInOut(duration: 0.3)
}

// MARK: - Quick Actions
@MainActor
class QuickActionsService: ObservableObject {
    static let shared = QuickActionsService()
    
    func executeAction(_ action: QuickAction) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-c", action.command]
        
        do {
            try task.run()
        } catch {
            print("Failed to execute action: \(error)")
        }
    }
}
