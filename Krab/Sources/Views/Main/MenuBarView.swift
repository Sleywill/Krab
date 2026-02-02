import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsManager
    @StateObject private var weatherService = WeatherService.shared
    @StateObject private var calendarService = CalendarService.shared
    @StateObject private var pomodoroService = PomodoroService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("🦀 Krab")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Image(systemName: "arrow.up.forward.square")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help("Open main window")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.2))
            
            ScrollView {
                VStack(spacing: 12) {
                    // Quick Stats Row
                    HStack(spacing: 12) {
                        // Weather mini
                        if let weather = weatherService.currentWeather {
                            MiniStatCard(
                                icon: weather.icon,
                                value: weather.temperatureString,
                                label: weather.location
                            )
                        }
                        
                        // Pomodoro mini
                        MiniStatCard(
                            icon: "timer",
                            value: pomodoroService.timeString,
                            label: pomodoroService.state.displayName,
                            color: pomodoroService.state.color
                        )
                    }
                    
                    Divider()
                    
                    // Upcoming event
                    if let event = calendarService.getUpcomingEvent() {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Next Event")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(event.color)
                                    .frame(width: 4, height: 30)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.title)
                                        .font(.system(size: 12, weight: .medium))
                                        .lineLimit(1)
                                    
                                    Text(event.timeString)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Divider()
                    }
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Actions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            QuickActionMiniButton(icon: "mic.fill", label: "Voice") {
                                appState.startVoiceRecording()
                            }
                            
                            QuickActionMiniButton(icon: "note.text", label: "Note") {
                                // Quick note
                            }
                            
                            QuickActionMiniButton(icon: "timer", label: "Focus") {
                                if pomodoroService.state == .idle {
                                    pomodoroService.start()
                                } else {
                                    pomodoroService.pause()
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
            }
            
            Divider()
            
            // Footer
            HStack {
                Button {
                    NSApp.terminate(nil)
                } label: {
                    Text("Quit")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    if let url = URL(string: "x-apple.systempreferences:") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 280)
    }
}

struct MiniStatCard: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = .secondary
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

struct QuickActionMiniButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                
                Text(label)
                    .font(.system(size: 9))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MenuBarView()
        .environmentObject(AppState.shared)
        .environmentObject(SettingsManager.shared)
        .frame(width: 280, height: 400)
        .preferredColorScheme(.dark)
}
