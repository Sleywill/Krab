import SwiftUI

struct AIChatView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsManager
    @StateObject private var voiceService = VoiceService.shared
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(appState.chatMessages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                        
                        if appState.isTyping {
                            TypingIndicator()
                                .id("typing")
                        }
                    }
                    .padding()
                }
                .onChange(of: appState.chatMessages.count) { _, _ in
                    withAnimation {
                        if let lastId = appState.chatMessages.last?.id {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: appState.isTyping) { _, isTyping in
                    if isTyping {
                        withAnimation {
                            proxy.scrollTo("typing", anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input area
            HStack(spacing: 12) {
                // Voice button
                Button {
                    if appState.isRecording {
                        Task {
                            await appState.stopVoiceRecording()
                        }
                    } else {
                        appState.startVoiceRecording()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(appState.isRecording ? Color.red : Color.gray.opacity(0.2))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: appState.isRecording ? "waveform" : "mic.fill")
                            .font(.system(size: 14))
                            .foregroundColor(appState.isRecording ? .white : .secondary)
                    }
                }
                .buttonStyle(.plain)
                .animation(.easeInOut, value: appState.isRecording)
                
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
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.krabGradient)
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.isEmpty || appState.isTyping)
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
        .overlay(alignment: .topTrailing) {
            // Clear chat button
            if !appState.chatMessages.isEmpty {
                Button {
                    withAnimation {
                        appState.clearChat()
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding()
            }
        }
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        let text = inputText
        inputText = ""
        
        Task {
            await appState.sendMessage(text)
            
            // Speak response if enabled
            if settings.enableVoiceResponses, let response = appState.chatMessages.last, response.role == .assistant {
                voiceService.speak(response.content)
            }
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var isUser: Bool {
        message.role == .user
    }
    
    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 13))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isUser ? AnyShapeStyle(Color.krabGradient) : AnyShapeStyle(Color.gray.opacity(0.2)))
                    )
                    .foregroundColor(isUser ? .white : .primary)
                
                Text(message.timestamp.timeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !isUser { Spacer(minLength: 60) }
        }
    }
}

struct TypingIndicator: View {
    @State private var animating = false
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .offset(y: animating ? -4 : 4)
                        .animation(
                            .easeInOut(duration: 0.4)
                            .repeatForever()
                            .delay(Double(index) * 0.15),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.2))
            )
            
            Spacer()
        }
        .onAppear {
            animating = true
        }
    }
}

#Preview {
    AIChatView()
        .environmentObject(AppState.shared)
        .environmentObject(SettingsManager.shared)
        .frame(width: 400, height: 500)
        .preferredColorScheme(.dark)
}
