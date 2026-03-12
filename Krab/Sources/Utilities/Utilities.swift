import Foundation
import SwiftUI
import AppKit
import Carbon
import UserNotifications

// MARK: - NotificationManager

/// Manages local user notifications for Krab, respecting quiet hours and user preferences.
@MainActor
class NotificationManager: ObservableObject {
    /// The shared singleton instance.
    static let shared = NotificationManager()

    /// Requests notification authorization from the system.
    ///
    /// - Returns: `true` if the user granted permission, `false` otherwise.
    func requestPermissions() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    /// Posts a local notification, subject to quiet hours and notification settings.
    ///
    /// - Parameters:
    ///   - title: The notification title.
    ///   - body: The notification body text.
    ///   - sound: Whether to play the default sound. Defaults to `true`.
    func showNotification(title: String, body: String, sound: Bool = true) {
        let settings = SettingsManager.shared

        guard settings.enableNotifications else { return }

        // Suppress during quiet hours
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

/// Centrally manages and publishes the authorization state for all permissions
/// required by Krab (calendar, microphone, speech, notifications).
@MainActor
class PermissionsManager: ObservableObject {
    /// The shared singleton instance.
    static let shared = PermissionsManager()

    /// Whether calendar access has been granted.
    @Published var calendarAuthorized = false

    /// Whether microphone access has been granted.
    @Published var microphoneAuthorized = false

    /// Whether speech recognition access has been granted.
    @Published var speechAuthorized = false

    /// Whether notification permission has been granted.
    @Published var notificationsAuthorized = false

    /// Requests all required permissions concurrently and updates published state.
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

    /// Refreshes published permission state from current system authorization without
    /// prompting the user.
    func checkPermissions() {
        calendarAuthorized = CalendarService.shared.isAuthorized
    }
}

// MARK: - HotkeyManager

/// Registers and manages the global keyboard shortcut (⌥ Space) that shows/hides Krab.
class HotkeyManager {
    /// The shared singleton instance.
    static let shared = HotkeyManager()

    private var hotKeyRef: EventHotKeyRef?

    /// Installs a Carbon event handler and registers ⌥ Space as a system-wide hotkey.
    ///
    /// When triggered, posts a `.globalHotkeyPressed` notification on `NotificationCenter.default`.
    func registerGlobalHotkey() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handler: EventHandlerUPP = { _, _, _ -> OSStatus in
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

    /// Unregisters the global hotkey, releasing the Carbon event handler.
    func unregisterGlobalHotkey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
        }
    }
}

extension Notification.Name {
    /// Posted when the global ⌥ Space hotkey is pressed.
    static let globalHotkeyPressed = Notification.Name("globalHotkeyPressed")
}

// MARK: - Color Extensions

extension Color {
    /// Creates a `Color` from a hex string.
    ///
    /// Accepts 6-character (RGB) or 8-character (RGBA) hex strings, with or without a `#` prefix.
    ///
    /// ```swift
    /// let red = Color(hex: "#FF6B6B")
    /// let semiTransparent = Color(hex: "FF6B6B80")
    /// ```
    ///
    /// - Parameter hex: The hex color string.
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

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

    /// Returns the color as an uppercase hex string (e.g. `"#FF6B6B"`), or `nil` if conversion fails.
    func toHex() -> String? {
        guard let components = NSColor(self).cgColor.components else { return nil }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    /// Krab's primary red accent color (`#FF6B6B`).
    static let krabRed = Color(hex: "#FF6B6B")!

    /// Krab's secondary orange accent color (`#FF8E53`).
    static let krabOrange = Color(hex: "#FF8E53")!

    /// The start color of the Krab gradient (same as `krabRed`).
    static let krabGradientStart = Color(hex: "#FF6B6B")!

    /// The end color of the Krab gradient (same as `krabOrange`).
    static let krabGradientEnd = Color(hex: "#FF8E53")!

    /// The standard Krab linear gradient, flowing from top-leading to bottom-trailing.
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
    /// Applies Krab's glass morphism background — a blurred, translucent layer with a white tint.
    ///
    /// - Parameters:
    ///   - opacity: White overlay opacity (0–1). Defaults to `0.15`.
    ///   - cornerRadius: Corner radius of the background shape. Defaults to `16`.
    ///   - blur: Blur intensity (unused directly; material blur is system-controlled). Defaults to `20`.
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

    /// Applies a card-style background using the system's ultra-thin material with a subtle white border.
    ///
    /// - Parameter cornerRadius: Corner radius of the card. Defaults to `16`.
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

    /// Conditionally applies a view transformation.
    ///
    /// Useful for applying modifiers only when a condition is met, without wrapping in `if` blocks.
    ///
    /// ```swift
    /// Text("Hello")
    ///     .if(isBold) { $0.bold() }
    /// ```
    ///
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: A closure that transforms the view if the condition is `true`.
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
    /// Returns `true` if the date falls on today in the current calendar.
    var isToday: Bool { Calendar.current.isDateInToday(self) }

    /// Returns `true` if the date falls on tomorrow in the current calendar.
    var isTomorrow: Bool { Calendar.current.isDateInTomorrow(self) }

    /// A human-readable relative label: `"Today"`, `"Tomorrow"`, or the full weekday name.
    var relativeString: String {
        if isToday { return "Today" }
        if isTomorrow { return "Tomorrow" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }

    /// The time formatted using the user's locale short time style (e.g. `"2:30 PM"`).
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// The date and time formatted using medium date + short time styles (e.g. `"Mar 12, 2026 at 2:30 PM"`).
    var dateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - Animation Extensions

extension Animation {
    /// A responsive spring with moderate damping — good for panels and drawers.
    static let krabSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)

    /// A bouncier spring — good for buttons and pop-in elements.
    static let krabBouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)

    /// A smooth ease-in-out curve over 0.3 seconds — good for opacity and color transitions.
    static let krabSmooth = Animation.easeInOut(duration: 0.3)
}

// MARK: - QuickActionsService

/// Executes user-defined shell commands from the Quick Actions widget.
@MainActor
class QuickActionsService: ObservableObject {
    /// The shared singleton instance.
    static let shared = QuickActionsService()

    /// Runs the shell command associated with a `QuickAction` using `/bin/zsh`.
    ///
    /// - Parameter action: The action whose `command` string will be executed.
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
