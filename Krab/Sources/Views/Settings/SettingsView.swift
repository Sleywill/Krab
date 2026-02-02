import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var selectedTab = SettingsTab.appearance
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 4) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    SettingsSidebarItem(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        selectedTab = tab
                    }
                }
                
                Spacer()
                
                // Version info
                VStack(alignment: .leading, spacing: 2) {
                    Text("Krab v1.0.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Link("GitHub", destination: URL(string: "https://github.com/Sleywil/Krab")!)
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .frame(width: 180)
            .padding(.top, 12)
            .background(Color.black.opacity(0.2))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch selectedTab {
                    case .appearance:
                        AppearanceSettingsView()
                    case .widgets:
                        WidgetsSettingsView()
                    case .ai:
                        AISettingsView()
                    case .telegram:
                        TelegramSettingsView()
                    case .notifications:
                        NotificationsSettingsView()
                    case .shortcuts:
                        ShortcutsSettingsView()
                    case .about:
                        AboutSettingsView()
                    }
                }
                .padding(24)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

enum SettingsTab: String, CaseIterable {
    case appearance = "Appearance"
    case widgets = "Widgets"
    case ai = "AI"
    case telegram = "Telegram"
    case notifications = "Notifications"
    case shortcuts = "Shortcuts"
    case about = "About"
    
    var icon: String {
        switch self {
        case .appearance: return "paintbrush.fill"
        case .widgets: return "square.grid.2x2.fill"
        case .ai: return "brain"
        case .telegram: return "paperplane.fill"
        case .notifications: return "bell.fill"
        case .shortcuts: return "keyboard"
        case .about: return "info.circle.fill"
        }
    }
}

struct SettingsSidebarItem: View {
    let tab: SettingsTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                
                Text(tab.rawValue)
                    .font(.system(size: 13))
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            )
            .foregroundColor(isSelected ? .accentColor : .primary)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }
}

// MARK: - Settings Section Views
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
        }
    }
}

struct AppearanceSettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Appearance")
                .font(.title2)
                .fontWeight(.bold)
            
            SettingsSection(title: "Theme") {
                Picker("Color Scheme", selection: $settings.theme) {
                    ForEach(ThemeMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                
                ColorPicker("Accent Color", selection: Binding(
                    get: { settings.accentColor },
                    set: { settings.accentColor = $0 }
                ))
            }
            
            SettingsSection(title: "Glass Effect") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Background Opacity: \(Int(settings.backgroundOpacity * 100))%")
                        .font(.caption)
                    Slider(value: $settings.backgroundOpacity, in: 0.3...1)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Blur Radius: \(Int(settings.blurRadius))")
                        .font(.caption)
                    Slider(value: $settings.blurRadius, in: 5...40)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Corner Radius: \(Int(settings.cornerRadius))")
                        .font(.caption)
                    Slider(value: $settings.cornerRadius, in: 4...32)
                }
            }
            
            SettingsSection(title: "Typography") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Font Size: \(Int(settings.fontSize))")
                        .font(.caption)
                    Slider(value: $settings.fontSize, in: 10...20)
                }
                
                Toggle("Show Animations", isOn: $settings.showAnimations)
                Toggle("Compact Mode", isOn: $settings.compactMode)
            }
            
            Button("Reset to Defaults") {
                settings.resetToDefaults()
            }
            .foregroundColor(.red)
        }
    }
}

struct WidgetsSettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Widgets")
                .font(.title2)
                .fontWeight(.bold)
            
            SettingsSection(title: "Visible Widgets") {
                ForEach(WidgetType.allCases) { widget in
                    Toggle(isOn: Binding(
                        get: { settings.isWidgetEnabled(widget) },
                        set: { _ in settings.toggleWidget(widget) }
                    )) {
                        HStack {
                            Image(systemName: widget.icon)
                                .frame(width: 20)
                            Text(widget.displayName)
                        }
                    }
                }
            }
            
            SettingsSection(title: "Weather") {
                TextField("Location (or 'auto')", text: $settings.weatherLocation)
                    .textFieldStyle(.roundedBorder)
                
                Picker("Temperature Unit", selection: $settings.weatherUnit) {
                    ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                        Text(unit.symbol).tag(unit)
                    }
                }
            }
            
            SettingsSection(title: "Pomodoro") {
                HStack {
                    Text("Work Duration")
                    Spacer()
                    Picker("", selection: $settings.pomodoroWorkDuration) {
                        Text("15 min").tag(TimeInterval(15 * 60))
                        Text("25 min").tag(TimeInterval(25 * 60))
                        Text("30 min").tag(TimeInterval(30 * 60))
                        Text("45 min").tag(TimeInterval(45 * 60))
                    }
                    .frame(width: 100)
                }
                
                Toggle("Auto-start breaks", isOn: $settings.pomodoroAutoStart)
                Toggle("Sound alerts", isOn: $settings.pomodoroSound)
            }
        }
    }
}

struct AISettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("AI Settings")
                .font(.title2)
                .fontWeight(.bold)
            
            SettingsSection(title: "Connection") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("API Endpoint")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("http://localhost:3000/api/chat", text: $settings.aiEndpoint)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Model")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("claude-3-sonnet", text: $settings.aiModel)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            SettingsSection(title: "Behavior") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("System Prompt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $settings.aiSystemPrompt)
                        .frame(height: 80)
                        .font(.system(size: 12))
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Stepper("Max Tokens: \(settings.aiMaxTokens)", value: $settings.aiMaxTokens, in: 100...4000, step: 100)
                
                Toggle("Voice Responses", isOn: $settings.enableVoiceResponses)
            }
        }
    }
}

struct TelegramSettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Telegram")
                .font(.title2)
                .fontWeight(.bold)
            
            SettingsSection(title: "Bot Configuration") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bot Token")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    SecureField("Your bot token", text: $settings.telegramBotToken)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chat ID")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Chat ID to send messages to", text: $settings.telegramChatId)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            SettingsSection(title: "Preferences") {
                Toggle("Enable Notifications", isOn: $settings.telegramNotifications)
                
                HStack {
                    Text("Polling Interval")
                    Spacer()
                    Picker("", selection: $settings.telegramPollingInterval) {
                        Text("1 sec").tag(TimeInterval(1))
                        Text("5 sec").tag(TimeInterval(5))
                        Text("10 sec").tag(TimeInterval(10))
                        Text("30 sec").tag(TimeInterval(30))
                    }
                    .frame(width: 100)
                }
            }
        }
    }
}

struct NotificationsSettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Notifications")
                .font(.title2)
                .fontWeight(.bold)
            
            SettingsSection(title: "General") {
                Toggle("Enable Notifications", isOn: $settings.enableNotifications)
                Toggle("Notification Sound", isOn: $settings.notificationSound)
            }
            
            SettingsSection(title: "Quiet Hours") {
                HStack {
                    Text("Start")
                    Spacer()
                    Picker("", selection: $settings.quietHoursStart) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text("\(hour):00").tag(hour)
                        }
                    }
                    .frame(width: 80)
                }
                
                HStack {
                    Text("End")
                    Spacer()
                    Picker("", selection: $settings.quietHoursEnd) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text("\(hour):00").tag(hour)
                        }
                    }
                    .frame(width: 80)
                }
            }
        }
    }
}

struct ShortcutsSettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Keyboard Shortcuts")
                .font(.title2)
                .fontWeight(.bold)
            
            SettingsSection(title: "Global Shortcuts") {
                HStack {
                    Text("Show/Hide Krab")
                    Spacer()
                    Text(settings.globalHotkey)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                HStack {
                    Text("Voice Command")
                    Spacer()
                    Text(settings.voiceHotkey)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                HStack {
                    Text("Quick Note")
                    Spacer()
                    Text(settings.quickNoteHotkey)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Logo
            VStack(spacing: 12) {
                Text("🦀")
                    .font(.system(size: 64))
                
                Text("Krab")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.krabGradient)
                
                Text("Your AI assistant, always visible")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Made with ❤️ by the community")
                    .font(.subheadline)
                
                Link("⭐ Star on GitHub", destination: URL(string: "https://github.com/Sleywil/Krab")!)
                Link("🐛 Report a Bug", destination: URL(string: "https://github.com/Sleywil/Krab/issues")!)
                Link("💡 Request a Feature", destination: URL(string: "https://github.com/Sleywil/Krab/issues")!)
            }
            
            Divider()
            
            VStack(spacing: 8) {
                Text("Open Source")
                    .font(.headline)
                
                Text("Krab is licensed under the MIT License.\nFeel free to use, modify, and distribute!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager.shared)
        .frame(width: 700, height: 500)
        .preferredColorScheme(.dark)
}
