import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsManager
    @State private var selectedTab: ViewState = .dashboard
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "#1a1a2e")!,
                    Color(hex: "#16213e")!
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HeaderView(selectedTab: $selectedTab)
                
                // Main content
                TabView(selection: $selectedTab) {
                    DashboardView()
                        .tag(ViewState.dashboard)
                    
                    AIChatView()
                        .tag(ViewState.chat)
                    
                    TelegramView()
                        .tag(ViewState.telegram)
                    
                    SettingsView()
                        .tag(ViewState.settings)
                }
                .tabViewStyle(.automatic)
            }
        }
        .preferredColorScheme(settings.theme.colorScheme)
        .onReceive(NotificationCenter.default.publisher(for: .globalHotkeyPressed)) { _ in
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

struct HeaderView: View {
    @Binding var selectedTab: ViewState
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Logo
            HStack(spacing: 8) {
                Text("🦀")
                    .font(.title)
                
                Text("Krab")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.krabGradient)
            }
            
            Spacer()
            
            // Navigation tabs
            HStack(spacing: 4) {
                ForEach(ViewState.allCases, id: \.self) { tab in
                    TabButton(
                        title: tab.rawValue,
                        icon: iconFor(tab),
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(.krabSpring) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(4)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Spacer()
            
            // Status indicators
            HStack(spacing: 12) {
                StatusIndicator(
                    icon: "bolt.fill",
                    color: AIService.shared.isConnected ? .green : .gray,
                    tooltip: AIService.shared.isConnected ? "AI Connected" : "AI Disconnected"
                )
                
                StatusIndicator(
                    icon: "paperplane.fill",
                    color: TelegramService.shared.isConnected ? .blue : .gray,
                    tooltip: TelegramService.shared.isConnected ? "Telegram Connected" : "Telegram Disconnected"
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial.opacity(0.5))
    }
    
    private func iconFor(_ tab: ViewState) -> String {
        switch tab {
        case .dashboard: return "square.grid.2x2.fill"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .telegram: return "paperplane.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                
                if isSelected {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .padding(.horizontal, isSelected ? 12 : 8)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                    AnyShapeStyle(Color.krabGradient) :
                    AnyShapeStyle(Color.clear)
            )
            .foregroundColor(isSelected ? .white : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct StatusIndicator: View {
    let icon: String
    let color: Color
    let tooltip: String
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 12))
            .foregroundColor(color)
            .help(tooltip)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
        .environmentObject(SettingsManager.shared)
        .frame(width: 900, height: 600)
}
