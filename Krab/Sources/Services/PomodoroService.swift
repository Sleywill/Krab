import Foundation
import Combine
import UserNotifications
import AppKit

@MainActor
class PomodoroService: ObservableObject {
    static let shared = PomodoroService()
    
    @Published var state: PomodoroState = .idle
    @Published var timeRemaining: TimeInterval = 25 * 60
    @Published var completedPomodoros: Int = 0
    @Published var totalFocusTime: TimeInterval = 0
    
    private var timer: Timer?
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0
    
    var progress: Double {
        let total = currentDuration
        guard total > 0 else { return 0 }
        return 1 - (timeRemaining / total)
    }
    
    var currentDuration: TimeInterval {
        let settings = SettingsManager.shared
        switch state {
        case .idle, .paused:
            return settings.pomodoroWorkDuration
        case .working:
            return settings.pomodoroWorkDuration
        case .shortBreak:
            return settings.pomodoroShortBreak
        case .longBreak:
            return settings.pomodoroLongBreak
        }
    }
    
    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Controls
    func start() {
        let settings = SettingsManager.shared
        
        if state == .paused {
            // Resume from paused state
            state = .working
        } else {
            // Start new pomodoro
            state = .working
            timeRemaining = settings.pomodoroWorkDuration
        }
        
        startTime = Date()
        startTimer()
    }
    
    func pause() {
        guard state == .working || state == .shortBreak || state == .longBreak else { return }
        
        timer?.invalidate()
        timer = nil
        pausedTime = timeRemaining
        state = .paused
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        state = .idle
        timeRemaining = SettingsManager.shared.pomodoroWorkDuration
        pausedTime = 0
        startTime = nil
    }
    
    func skip() {
        timer?.invalidate()
        timer = nil
        
        switch state {
        case .working:
            startBreak()
        case .shortBreak, .longBreak:
            startPomodoro()
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    private func tick() {
        guard timeRemaining > 0 else {
            handleCompletion()
            return
        }
        
        timeRemaining -= 1
        
        if state == .working {
            totalFocusTime += 1
        }
    }
    
    private func handleCompletion() {
        timer?.invalidate()
        timer = nil
        
        let settings = SettingsManager.shared
        
        switch state {
        case .working:
            completedPomodoros += 1
            
            if settings.pomodoroSound {
                NSSound.beep()
            }
            
            NotificationManager.shared.showNotification(
                title: "🍅 Pomodoro Complete!",
                body: "Time for a break. You've completed \(completedPomodoros) pomodoros today."
            )
            
            if settings.pomodoroAutoStart {
                startBreak()
            } else {
                state = .idle
                timeRemaining = settings.pomodoroWorkDuration
            }
            
        case .shortBreak, .longBreak:
            if settings.pomodoroSound {
                NSSound.beep()
            }
            
            NotificationManager.shared.showNotification(
                title: "⏰ Break Over!",
                body: "Ready to focus again?"
            )
            
            if settings.pomodoroAutoStart {
                startPomodoro()
            } else {
                state = .idle
                timeRemaining = settings.pomodoroWorkDuration
            }
            
        default:
            break
        }
    }
    
    private func startBreak() {
        let settings = SettingsManager.shared
        
        // Long break every N pomodoros
        if completedPomodoros > 0 && completedPomodoros % settings.pomodoroLongBreakInterval == 0 {
            state = .longBreak
            timeRemaining = settings.pomodoroLongBreak
        } else {
            state = .shortBreak
            timeRemaining = settings.pomodoroShortBreak
        }
        
        startTime = Date()
        startTimer()
    }
    
    private func startPomodoro() {
        let settings = SettingsManager.shared
        state = .working
        timeRemaining = settings.pomodoroWorkDuration
        startTime = Date()
        startTimer()
    }
    
    // MARK: - Statistics
    func resetDaily() {
        completedPomodoros = 0
        totalFocusTime = 0
    }
}
