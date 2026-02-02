import Foundation
import Combine

@MainActor
class TelegramService: ObservableObject {
    static let shared = TelegramService()
    
    @Published var isConnected = false
    @Published var messages: [TelegramMessage] = []
    @Published var error: Error?
    @Published var isSending = false
    
    private var pollingTask: Task<Void, Never>?
    private var lastUpdateId: Int = 0
    
    enum TelegramError: LocalizedError {
        case notConfigured
        case invalidToken
        case networkError(Error)
        case apiError(String)
        
        var errorDescription: String? {
            switch self {
            case .notConfigured: return "Telegram bot token not configured"
            case .invalidToken: return "Invalid Telegram bot token"
            case .networkError(let error): return "Network error: \(error.localizedDescription)"
            case .apiError(let message): return "Telegram API error: \(message)"
            }
        }
    }
    
    // MARK: - Connection
    func connect() async throws {
        let settings = SettingsManager.shared
        
        guard !settings.telegramBotToken.isEmpty else {
            throw TelegramError.notConfigured
        }
        
        // Test connection with getMe
        let url = URL(string: "https://api.telegram.org/bot\(settings.telegramBotToken)/getMe")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(TelegramResponse<TelegramUser>.self, from: data)
            
            if response.ok {
                isConnected = true
                startPolling()
            } else {
                throw TelegramError.apiError(response.description ?? "Unknown error")
            }
        } catch let error as TelegramError {
            throw error
        } catch {
            throw TelegramError.networkError(error)
        }
    }
    
    func disconnect() {
        pollingTask?.cancel()
        pollingTask = nil
        isConnected = false
    }
    
    // MARK: - Polling
    private func startPolling() {
        pollingTask?.cancel()
        
        pollingTask = Task {
            while !Task.isCancelled && isConnected {
                await fetchUpdates()
                try? await Task.sleep(nanoseconds: UInt64(SettingsManager.shared.telegramPollingInterval * 1_000_000_000))
            }
        }
    }
    
    private func fetchUpdates() async {
        let settings = SettingsManager.shared
        
        guard !settings.telegramBotToken.isEmpty else { return }
        
        var urlComponents = URLComponents(string: "https://api.telegram.org/bot\(settings.telegramBotToken)/getUpdates")!
        urlComponents.queryItems = [
            URLQueryItem(name: "offset", value: String(lastUpdateId + 1)),
            URLQueryItem(name: "timeout", value: "30"),
            URLQueryItem(name: "allowed_updates", value: "[\"message\"]")
        ]
        
        guard let url = urlComponents.url else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(TelegramResponse<[TelegramUpdate]>.self, from: data)
            
            if response.ok, let updates = response.result {
                for update in updates {
                    lastUpdateId = max(lastUpdateId, update.update_id)
                    
                    if let message = update.message {
                        let telegramMessage = TelegramMessage(
                            id: message.message_id,
                            chatId: message.chat.id,
                            chatTitle: message.chat.title ?? message.chat.first_name ?? "Chat",
                            senderName: message.from?.first_name ?? "Unknown",
                            text: message.text ?? "[Media]",
                            date: Date(timeIntervalSince1970: TimeInterval(message.date)),
                            isOutgoing: false,
                            hasVoice: message.voice != nil,
                            isRead: false
                        )
                        
                        if !messages.contains(where: { $0.id == telegramMessage.id }) {
                            messages.insert(telegramMessage, at: 0)
                            
                            // Keep only last 100 messages
                            if messages.count > 100 {
                                messages = Array(messages.prefix(100))
                            }
                            
                            // Show notification if enabled
                            if SettingsManager.shared.telegramNotifications {
                                NotificationManager.shared.showNotification(
                                    title: telegramMessage.senderName,
                                    body: telegramMessage.text
                                )
                            }
                        }
                    }
                }
            }
        } catch {
            self.error = TelegramError.networkError(error)
        }
    }
    
    // MARK: - Send Messages
    func sendMessage(_ text: String, chatId: Int64? = nil) async throws {
        let settings = SettingsManager.shared
        
        guard !settings.telegramBotToken.isEmpty else {
            throw TelegramError.notConfigured
        }
        
        let targetChatId = chatId ?? Int64(settings.telegramChatId) ?? 0
        guard targetChatId != 0 else {
            throw TelegramError.notConfigured
        }
        
        isSending = true
        defer { isSending = false }
        
        let url = URL(string: "https://api.telegram.org/bot\(settings.telegramBotToken)/sendMessage")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "chat_id": targetChatId,
            "text": text,
            "parse_mode": "Markdown"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TelegramResponse<TelegramMessageResult>.self, from: data)
        
        if !response.ok {
            throw TelegramError.apiError(response.description ?? "Unknown error")
        }
        
        // Add to local messages
        let sentMessage = TelegramMessage(
            id: response.result?.message_id ?? Int.random(in: 1...Int.max),
            chatId: targetChatId,
            chatTitle: "You",
            senderName: "You",
            text: text,
            date: Date(),
            isOutgoing: true,
            hasVoice: false,
            isRead: true
        )
        
        messages.insert(sentMessage, at: 0)
    }
    
    func sendVoiceNote(_ audioURL: URL, chatId: Int64? = nil) async throws {
        let settings = SettingsManager.shared
        
        guard !settings.telegramBotToken.isEmpty else {
            throw TelegramError.notConfigured
        }
        
        let targetChatId = chatId ?? Int64(settings.telegramChatId) ?? 0
        guard targetChatId != 0 else {
            throw TelegramError.notConfigured
        }
        
        isSending = true
        defer { isSending = false }
        
        let url = URL(string: "https://api.telegram.org/bot\(settings.telegramBotToken)/sendVoice")!
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add chat_id
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"chat_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(targetChatId)\r\n".data(using: .utf8)!)
        
        // Add voice file
        let audioData = try Data(contentsOf: audioURL)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"voice\"; filename=\"voice.ogg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/ogg\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TelegramResponse<TelegramMessageResult>.self, from: data)
        
        if !response.ok {
            throw TelegramError.apiError(response.description ?? "Unknown error")
        }
    }
}

// MARK: - Telegram API Models
private struct TelegramResponse<T: Codable>: Codable {
    let ok: Bool
    let result: T?
    let description: String?
}

private struct TelegramUser: Codable {
    let id: Int64
    let first_name: String
    let username: String?
}

private struct TelegramUpdate: Codable {
    let update_id: Int
    let message: TelegramAPIMessage?
}

private struct TelegramAPIMessage: Codable {
    let message_id: Int
    let from: TelegramUser?
    let chat: TelegramChat
    let date: Int
    let text: String?
    let voice: TelegramVoice?
}

private struct TelegramChat: Codable {
    let id: Int64
    let type: String
    let title: String?
    let first_name: String?
}

private struct TelegramVoice: Codable {
    let file_id: String
    let duration: Int
}

private struct TelegramMessageResult: Codable {
    let message_id: Int
}
