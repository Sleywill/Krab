import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    
    // MARK: - Published Properties
    @Published var currentView: ViewState = .dashboard
    @Published var showAbout = false
    @Published var isRecording = false
    @Published var isProcessingVoice = false
    @Published var lastVoiceTranscript: String = ""
    @Published var aiResponse: String = ""
    @Published var isConnectedToAI = false
    @Published var showSettings = false
    
    // MARK: - Widget States
    @Published var weatherData: WeatherData?
    @Published var calendarEvents: [CalendarEvent] = []
    @Published var reminders: [ReminderItem] = []
    @Published var notes: [QuickNote] = []
    @Published var systemStats: SystemStats?
    @Published var nowPlaying: NowPlayingInfo?
    @Published var pomodoroState: PomodoroState = .idle
    @Published var pomodoroTimeRemaining: TimeInterval = 25 * 60
    
    // MARK: - Telegram
    @Published var telegramMessages: [TelegramMessage] = []
    @Published var telegramConnected = false
    
    // MARK: - AI Chat
    @Published var chatMessages: [ChatMessage] = []
    @Published var isTyping = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Weather updates
        WeatherService.shared.$currentWeather
            .assign(to: &$weatherData)
        
        // Calendar updates
        CalendarService.shared.$events
            .assign(to: &$calendarEvents)
        
        // System stats updates
        SystemStatsService.shared.$stats
            .assign(to: &$systemStats)
        
        // Now playing updates
        NowPlayingService.shared.$nowPlaying
            .assign(to: &$nowPlaying)
    }
    
    // MARK: - Actions
    func sendMessage(_ text: String) async {
        let userMessage = ChatMessage(role: .user, content: text)
        chatMessages.append(userMessage)
        isTyping = true
        
        do {
            let response = try await AIService.shared.sendMessage(text, context: chatMessages)
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            chatMessages.append(assistantMessage)
            aiResponse = response
        } catch {
            let errorMessage = ChatMessage(role: .assistant, content: "Error: \(error.localizedDescription)")
            chatMessages.append(errorMessage)
        }
        
        isTyping = false
    }
    
    func startVoiceRecording() {
        isRecording = true
        VoiceService.shared.startRecording()
    }
    
    func stopVoiceRecording() async {
        isRecording = false
        isProcessingVoice = true
        
        do {
            let transcript = try await VoiceService.shared.stopRecordingAndTranscribe()
            lastVoiceTranscript = transcript
            await sendMessage(transcript)
        } catch {
            lastVoiceTranscript = "Error: \(error.localizedDescription)"
        }
        
        isProcessingVoice = false
    }
    
    func speakResponse(_ text: String) {
        VoiceService.shared.speak(text)
    }
    
    func clearChat() {
        chatMessages.removeAll()
    }
}

enum ViewState: String, CaseIterable {
    case dashboard = "Dashboard"
    case chat = "AI Chat"
    case telegram = "Telegram"
    case settings = "Settings"
}
