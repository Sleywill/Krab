import SwiftUI

struct TelegramView: View {
    @StateObject private var telegramService = TelegramService.shared
    @EnvironmentObject var settings: SettingsManager
    @State private var inputText = ""
    @State private var isRecordingVoice = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if !telegramService.isConnected {
                // Connection setup
                TelegramSetupView()
            } else {
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(telegramService.messages) { message in
                                TelegramMessageRow(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: telegramService.messages.count) { _, _ in
                        if let firstId = telegramService.messages.first?.id {
                            withAnimation {
                                proxy.scrollTo(firstId, anchor: .top)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Input area
                HStack(spacing: 12) {
                    // Voice note button
                    Button {
                        toggleVoiceRecording()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(isRecordingVoice ? Color.red : Color.gray.opacity(0.2))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: isRecordingVoice ? "waveform" : "mic.fill")
                                .font(.system(size: 14))
                                .foregroundColor(isRecordingVoice ? .white : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // Text input
                    HStack {
                        TextField("Message...", text: $inputText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(1...5)
                            .focused($isInputFocused)
                            .onSubmit {
                                sendMessage()
                            }
                        
                        Button {
                            sendMessage()
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        .disabled(inputText.isEmpty || telegramService.isSending)
                        .opacity(inputText.isEmpty ? 0.3 : 1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.1))
                    )
                }
                .padding()
            }
        }
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        let text = inputText
        inputText = ""
        
        Task {
            do {
                try await telegramService.sendMessage(text)
            } catch {
                // Show error
                print("Failed to send message: \(error)")
            }
        }
    }
    
    private func toggleVoiceRecording() {
        if isRecordingVoice {
            // Stop and send
            if let url = VoiceService.shared.stopRecordingVoiceNote() {
                Task {
                    try? await telegramService.sendVoiceNote(url)
                }
            }
        } else {
            // Start recording
            do {
                _ = try VoiceService.shared.startRecordingVoiceNote()
            } catch {
                print("Failed to start recording: \(error)")
            }
        }
        isRecordingVoice.toggle()
    }
}

struct TelegramSetupView: View {
    @EnvironmentObject var settings: SettingsManager
    @StateObject private var telegramService = TelegramService.shared
    @State private var botToken = ""
    @State private var chatId = ""
    @State private var isConnecting = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                Text("Connect Telegram")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Enter your bot token and chat ID to receive and send messages")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bot Token")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    SecureField("123456:ABC-DEF...", text: $botToken)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chat ID")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("-100123456789", text: $chatId)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .frame(maxWidth: 300)
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Button {
                connect()
            } label: {
                HStack {
                    if isConnecting {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                    Text(isConnecting ? "Connecting..." : "Connect")
                }
                .frame(maxWidth: 200)
            }
            .buttonStyle(.borderedProminent)
            .disabled(botToken.isEmpty || chatId.isEmpty || isConnecting)
            
            // Help link
            Link(destination: URL(string: "https://core.telegram.org/bots#how-do-i-create-a-bot")!) {
                Text("How to create a Telegram bot?")
                    .font(.caption)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            botToken = settings.telegramBotToken
            chatId = settings.telegramChatId
        }
    }
    
    private func connect() {
        isConnecting = true
        errorMessage = nil
        
        settings.telegramBotToken = botToken
        settings.telegramChatId = chatId
        
        Task {
            do {
                try await telegramService.connect()
            } catch {
                errorMessage = error.localizedDescription
            }
            isConnecting = false
        }
    }
}

struct TelegramMessageRow: View {
    let message: TelegramMessage
    
    var body: some View {
        HStack {
            if message.isOutgoing { Spacer(minLength: 60) }
            
            VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 4) {
                if !message.isOutgoing {
                    Text(message.senderName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                HStack(spacing: 8) {
                    if message.hasVoice {
                        Image(systemName: "waveform")
                            .foregroundColor(.secondary)
                    }
                    
                    Text(message.text)
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(message.isOutgoing ? Color.blue : Color.gray.opacity(0.2))
                )
                .foregroundColor(message.isOutgoing ? .white : .primary)
                
                Text(message.date.timeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !message.isOutgoing { Spacer(minLength: 60) }
        }
    }
}

#Preview {
    TelegramView()
        .environmentObject(SettingsManager.shared)
        .frame(width: 400, height: 500)
        .preferredColorScheme(.dark)
}
