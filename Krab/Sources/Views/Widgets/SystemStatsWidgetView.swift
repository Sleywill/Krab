import SwiftUI

struct SystemStatsWidgetView: View {
    @StateObject private var statsService = SystemStatsService.shared
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        WidgetCard(title: "System", icon: "cpu", color: .purple) {
            if let stats = statsService.stats {
                VStack(spacing: 16) {
                    // CPU and Memory gauges
                    HStack(spacing: 20) {
                        CircularGauge(
                            value: stats.cpuUsage / 100,
                            label: "CPU",
                            valueText: String(format: "%.0f%%", stats.cpuUsage),
                            color: gaugeColor(for: stats.cpuUsage)
                        )
                        
                        CircularGauge(
                            value: stats.memoryUsage / 100,
                            label: "RAM",
                            valueText: String(format: "%.0f%%", stats.memoryUsage),
                            color: gaugeColor(for: stats.memoryUsage)
                        )
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Additional stats
                    VStack(spacing: 8) {
                        StatsRow(
                            icon: "internaldrive",
                            label: "Disk",
                            value: stats.diskString
                        )
                        
                        StatsRow(
                            icon: "battery.100",
                            label: "Battery",
                            value: "\(stats.batteryLevel)%",
                            trailing: stats.isCharging ? "⚡" : nil
                        )
                        
                        StatsRow(
                            icon: "clock",
                            label: "Uptime",
                            value: stats.uptimeString
                        )
                    }
                }
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading stats...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .onAppear {
            statsService.startMonitoring()
        }
    }
    
    private func gaugeColor(for value: Double) -> Color {
        switch value {
        case 0..<50: return .green
        case 50..<75: return .yellow
        case 75..<90: return .orange
        default: return .red
        }
    }
}

struct CircularGauge: View {
    let value: Double
    let label: String
    let valueText: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: min(value, 1.0))
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: value)
                
                // Value text
                Text(valueText)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .frame(width: 60, height: 60)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct StatsRow: View {
    let icon: String
    let label: String
    let value: String
    var trailing: String? = nil
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 12, weight: .medium))
                
                if let trailing = trailing {
                    Text(trailing)
                        .font(.system(size: 12))
                }
            }
        }
    }
}

#Preview {
    SystemStatsWidgetView()
        .environmentObject(SettingsManager.shared)
        .frame(width: 220)
        .padding()
        .preferredColorScheme(.dark)
}
