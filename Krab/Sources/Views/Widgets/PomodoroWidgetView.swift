import SwiftUI

struct PomodoroWidgetView: View {
    @StateObject private var pomodoroService = PomodoroService.shared
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        WidgetCard(title: "Pomodoro", icon: "timer", color: pomodoroService.state.color) {
            VStack(spacing: 16) {
                // Timer display
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: pomodoroService.progress)
                        .stroke(
                            pomodoroService.state.color,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: pomodoroService.progress)
                    
                    // Time display
                    VStack(spacing: 2) {
                        Text(pomodoroService.timeString)
                            .font(.system(size: 28, weight: .light, design: .monospaced))
                        
                        Text(pomodoroService.state.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 100, height: 100)
                
                // Controls
                HStack(spacing: 16) {
                    // Stop button
                    Button {
                        pomodoroService.stop()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(PomodoroButtonStyle(color: .red))
                    .opacity(pomodoroService.state == .idle ? 0.3 : 1)
                    .disabled(pomodoroService.state == .idle)
                    
                    // Play/Pause button
                    Button {
                        if pomodoroService.state == .working ||
                           pomodoroService.state == .shortBreak ||
                           pomodoroService.state == .longBreak {
                            pomodoroService.pause()
                        } else {
                            pomodoroService.start()
                        }
                    } label: {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(PomodoroButtonStyle(color: .green, isLarge: true))
                    
                    // Skip button
                    Button {
                        pomodoroService.skip()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(PomodoroButtonStyle(color: .blue))
                    .opacity(pomodoroService.state == .idle ? 0.3 : 1)
                    .disabled(pomodoroService.state == .idle)
                }
                
                // Session count
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index < pomodoroService.completedPomodoros % 4 ? Color.krabRed : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("\(pomodoroService.completedPomodoros) pomodoros")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var isRunning: Bool {
        pomodoroService.state == .working ||
        pomodoroService.state == .shortBreak ||
        pomodoroService.state == .longBreak
    }
}

struct PomodoroButtonStyle: ButtonStyle {
    let color: Color
    var isLarge: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .frame(width: isLarge ? 44 : 32, height: isLarge ? 44 : 32)
            .background(
                Circle()
                    .fill(color)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    PomodoroWidgetView()
        .environmentObject(SettingsManager.shared)
        .frame(width: 200)
        .padding()
        .preferredColorScheme(.dark)
}
