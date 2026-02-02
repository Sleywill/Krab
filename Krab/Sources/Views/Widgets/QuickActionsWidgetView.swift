import SwiftUI

struct QuickActionsWidgetView: View {
    @EnvironmentObject var settings: SettingsManager
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        WidgetCard(title: "Quick Actions", icon: "bolt.fill", color: .orange) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(settings.quickActions) { action in
                    QuickActionButton(action: action)
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let action: QuickAction
    @State private var isPressed = false
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            QuickActionsService.shared.executeAction(action)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: action.icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: action.color) ?? .blue)
                
                Text(action.name)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
            )
            .scaleEffect(isPressed ? 0.95 : 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuickActionsWidgetView()
        .environmentObject(SettingsManager.shared)
        .frame(width: 220)
        .padding()
        .preferredColorScheme(.dark)
}
