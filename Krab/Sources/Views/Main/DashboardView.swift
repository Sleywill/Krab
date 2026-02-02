import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsManager
    
    let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 350), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                if settings.isWidgetEnabled(.weather) {
                    WeatherWidgetView()
                        .transition(.scale.combined(with: .opacity))
                }
                
                if settings.isWidgetEnabled(.calendar) {
                    CalendarWidgetView()
                        .transition(.scale.combined(with: .opacity))
                }
                
                if settings.isWidgetEnabled(.systemStats) {
                    SystemStatsWidgetView()
                        .transition(.scale.combined(with: .opacity))
                }
                
                if settings.isWidgetEnabled(.pomodoro) {
                    PomodoroWidgetView()
                        .transition(.scale.combined(with: .opacity))
                }
                
                if settings.isWidgetEnabled(.music) {
                    MusicWidgetView()
                        .transition(.scale.combined(with: .opacity))
                }
                
                if settings.isWidgetEnabled(.notes) {
                    NotesWidgetView()
                        .transition(.scale.combined(with: .opacity))
                }
                
                if settings.isWidgetEnabled(.reminders) {
                    RemindersWidgetView()
                        .transition(.scale.combined(with: .opacity))
                }
                
                if settings.isWidgetEnabled(.quickActions) {
                    QuickActionsWidgetView()
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(20)
            .animation(.krabSpring, value: settings.enabledWidgets)
        }
    }
}

// MARK: - Widget Card Container
struct WidgetCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content
    
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Content
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: settings.cornerRadius)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: settings.cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState.shared)
        .environmentObject(SettingsManager.shared)
        .frame(width: 900, height: 600)
        .preferredColorScheme(.dark)
}
