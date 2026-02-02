import Foundation
import Combine

@MainActor
class AIService: ObservableObject {
    static let shared = AIService()
    
    @Published var isConnected = false
    @Published var error: Error?
    
    enum AIError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case noData
        
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid API endpoint URL"
            case .networkError(let error): return "Network error: \(error.localizedDescription)"
            case .invalidResponse: return "Invalid response from AI service"
            case .noData: return "No response data received"
            }
        }
    }
    
    private var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        return URLSession(configuration: config)
    }()
    
    func checkConnection() async -> Bool {
        let settings = SettingsManager.shared
        guard let url = URL(string: settings.aiEndpoint) else {
            isConnected = false
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5
        
        do {
            let (_, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                isConnected = (200...499).contains(httpResponse.statusCode)
                return isConnected
            }
        } catch {
            isConnected = false
        }
        
        return false
    }
    
    func sendMessage(_ message: String, context: [ChatMessage] = []) async throws -> String {
        let settings = SettingsManager.shared
        
        guard let url = URL(string: settings.aiEndpoint) else {
            throw AIError.invalidURL
        }
        
        // Build message history
        var messages: [[String: String]] = []
        
        // Add system prompt
        if !settings.aiSystemPrompt.isEmpty {
            messages.append([
                "role": "system",
                "content": settings.aiSystemPrompt
            ])
        }
        
        // Add context messages
        for msg in context.suffix(10) {
            messages.append([
                "role": msg.role.rawValue,
                "content": msg.content
            ])
        }
        
        // Build request body (OpenAI-compatible format)
        let requestBody: [String: Any] = [
            "model": settings.aiModel,
            "messages": messages,
            "max_tokens": settings.aiMaxTokens,
            "temperature": 0.7,
            "stream": false
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                if let errorString = String(data: data, encoding: .utf8) {
                    throw AIError.networkError(NSError(domain: "AI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorString]))
                }
                throw AIError.invalidResponse
            }
            
            // Parse OpenAI-compatible response
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                isConnected = true
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Try alternative response formats
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Claude API format
                if let content = json["content"] as? [[String: Any]],
                   let firstContent = content.first,
                   let text = firstContent["text"] as? String {
                    isConnected = true
                    return text.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                // Simple response format
                if let response = json["response"] as? String {
                    isConnected = true
                    return response.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                // Text field
                if let text = json["text"] as? String {
                    isConnected = true
                    return text.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            throw AIError.invalidResponse
            
        } catch let error as AIError {
            self.error = error
            throw error
        } catch {
            self.error = AIError.networkError(error)
            throw AIError.networkError(error)
        }
    }
    
    func sendMessageStreaming(_ message: String, context: [ChatMessage] = []) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let response = try await sendMessage(message, context: context)
                    // Simulate streaming by yielding word by word
                    let words = response.split(separator: " ")
                    for word in words {
                        continuation.yield(String(word) + " ")
                        try await Task.sleep(nanoseconds: 20_000_000) // 20ms delay
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - OpenClaw Integration
extension AIService {
    func connectToOpenClaw() async throws -> Bool {
        // Try to connect to local OpenClaw instance
        let openClawEndpoint = "http://localhost:3000/api/chat"
        let settings = SettingsManager.shared
        
        // Temporarily set endpoint
        let originalEndpoint = settings.aiEndpoint
        settings.aiEndpoint = openClawEndpoint
        
        let connected = await checkConnection()
        
        if !connected {
            settings.aiEndpoint = originalEndpoint
        }
        
        return connected
    }
}
