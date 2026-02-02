import Foundation
import AVFoundation
import Speech
import Combine

@MainActor
class VoiceService: NSObject, ObservableObject {
    static let shared = VoiceService()
    
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var isSpeaking = false
    @Published var transcription: String = ""
    @Published var error: Error?
    @Published var audioLevel: Float = 0
    
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private let synthesizer = AVSpeechSynthesizer()
    
    private var levelTimer: Timer?
    
    override init() {
        super.init()
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        synthesizer.delegate = self
    }
    
    // MARK: - Permissions
    func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        
        let micStatus = await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
        
        return speechStatus && micStatus
    }
    
    // MARK: - Recording
    func startRecording() {
        guard !isRecording else { return }
        
        transcription = ""
        error = nil
        
        // Setup audio session
        do {
            audioEngine = AVAudioEngine()
            guard let audioEngine = audioEngine else { return }
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            // Create recognition request
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            recognitionRequest?.shouldReportPartialResults = true
            
            // Start recognition task
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
                Task { @MainActor in
                    if let result = result {
                        self?.transcription = result.bestTranscription.formattedString
                    }
                    
                    if let error = error {
                        self?.error = error
                    }
                }
            }
            
            // Install tap on input node
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
                
                // Calculate audio level
                let channelData = buffer.floatChannelData?[0]
                let channelDataCount = Int(buffer.frameLength)
                
                var sum: Float = 0
                for i in 0..<channelDataCount {
                    sum += channelData?[i] ?? 0
                }
                let average = sum / Float(channelDataCount)
                let level = abs(average) * 1000
                
                Task { @MainActor in
                    self?.audioLevel = min(level, 1.0)
                }
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            isRecording = true
            
        } catch {
            self.error = error
        }
    }
    
    func stopRecordingAndTranscribe() async throws -> String {
        guard isRecording else { return "" }
        
        isRecording = false
        isTranscribing = true
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        
        // Wait a moment for final transcription
        try await Task.sleep(nanoseconds: 500_000_000)
        
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        audioEngine = nil
        
        isTranscribing = false
        
        return transcription
    }
    
    func cancelRecording() {
        isRecording = false
        isTranscribing = false
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionTask = nil
        recognitionRequest = nil
        audioEngine = nil
        transcription = ""
    }
    
    // MARK: - Text to Speech
    func speak(_ text: String) {
        guard !text.isEmpty else { return }
        
        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // Use system voice
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }
        
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
    
    // MARK: - Voice Notes
    func startRecordingVoiceNote() throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("voicenote_\(Date().timeIntervalSince1970).m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()
        
        recordingURL = audioFilename
        isRecording = true
        
        // Start level monitoring
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.audioRecorder?.updateMeters()
            let level = self?.audioRecorder?.averagePower(forChannel: 0) ?? -160
            let normalizedLevel = max(0, (level + 60) / 60)
            Task { @MainActor in
                self?.audioLevel = normalizedLevel
            }
        }
        
        return audioFilename
    }
    
    func stopRecordingVoiceNote() -> URL? {
        levelTimer?.invalidate()
        levelTimer = nil
        
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        audioLevel = 0
        
        return recordingURL
    }
}

extension VoiceService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
