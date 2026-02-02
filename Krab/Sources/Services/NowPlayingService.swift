import Foundation
import Combine
import AppKit

@MainActor
class NowPlayingService: ObservableObject {
    static let shared = NowPlayingService()
    
    @Published var nowPlaying: NowPlayingInfo?
    @Published var isPlaying = false
    
    private var updateTimer: Timer?
    
    func startMonitoring() {
        updateNowPlaying()
        scheduleUpdates()
    }
    
    func stopMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func scheduleUpdates() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateNowPlaying()
        }
    }
    
    private func updateNowPlaying() {
        // Use MRMediaRemote framework via private API
        // This is a simplified version - full implementation would use MRMediaRemote
        
        // Get info from running media apps
        let runningApps = NSWorkspace.shared.runningApplications
        let mediaApps = ["Music", "Spotify", "VLC", "QuickTime Player", "IINA", "Apple Music"]
        
        for app in runningApps {
            guard let appName = app.localizedName, mediaApps.contains(appName) else { continue }
            
            // Try to get now playing info via AppleScript
            let script = """
            tell application "\(appName)"
                if it is running then
                    try
                        if player state is playing then
                            set trackName to name of current track
                            set artistName to artist of current track
                            set albumName to album of current track
                            set trackDuration to duration of current track
                            set trackPosition to player position
                            return trackName & "|||" & artistName & "|||" & albumName & "|||" & (trackDuration as string) & "|||" & (trackPosition as string)
                        end if
                    end try
                end if
            end tell
            return ""
            """
            
            if let scriptObject = NSAppleScript(source: script) {
                var errorDict: NSDictionary?
                let output = scriptObject.executeAndReturnError(&errorDict)
                
                if let result = output.stringValue, !result.isEmpty {
                    let components = result.components(separatedBy: "|||")
                    
                    if components.count >= 5 {
                        let title = components[0]
                        let artist = components[1]
                        let album = components[2]
                        let duration = Double(components[3]) ?? 0
                        let position = Double(components[4]) ?? 0
                        
                        nowPlaying = NowPlayingInfo(
                            title: title,
                            artist: artist,
                            album: album,
                            artworkData: nil,
                            duration: duration,
                            elapsedTime: position,
                            isPlaying: true,
                            appName: appName
                        )
                        isPlaying = true
                        return
                    }
                }
            }
        }
        
        // No media playing
        isPlaying = false
        nowPlaying = nil
    }
    
    // MARK: - Playback Controls
    func playPause() {
        guard let appName = nowPlaying?.appName else { return }
        
        let script = """
        tell application "\(appName)"
            playpause
        end tell
        """
        
        if let scriptObject = NSAppleScript(source: script) {
            var errorDict: NSDictionary?
            scriptObject.executeAndReturnError(&errorDict)
        }
        
        updateNowPlaying()
    }
    
    func nextTrack() {
        guard let appName = nowPlaying?.appName else { return }
        
        let script = """
        tell application "\(appName)"
            next track
        end tell
        """
        
        if let scriptObject = NSAppleScript(source: script) {
            var errorDict: NSDictionary?
            scriptObject.executeAndReturnError(&errorDict)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateNowPlaying()
        }
    }
    
    func previousTrack() {
        guard let appName = nowPlaying?.appName else { return }
        
        let script = """
        tell application "\(appName)"
            previous track
        end tell
        """
        
        if let scriptObject = NSAppleScript(source: script) {
            var errorDict: NSDictionary?
            scriptObject.executeAndReturnError(&errorDict)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateNowPlaying()
        }
    }
}
