import SwiftUI

struct MusicWidgetView: View {
    @StateObject private var nowPlayingService = NowPlayingService.shared
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        WidgetCard(title: "Now Playing", icon: "music.note", color: .pink) {
            if let nowPlaying = nowPlayingService.nowPlaying {
                HStack(spacing: 12) {
                    // Album art placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Image(systemName: "music.note")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(width: 60, height: 60)
                    
                    // Track info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(nowPlaying.title)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                        
                        Text(nowPlaying.artist)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 4)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.pink)
                                    .frame(width: geometry.size.width * nowPlaying.progress, height: 4)
                            }
                        }
                        .frame(height: 4)
                        
                        Text(nowPlaying.timeString)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Controls
                HStack(spacing: 20) {
                    Spacer()
                    
                    Button {
                        nowPlayingService.previousTrack()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    
                    Button {
                        nowPlayingService.playPause()
                    } label: {
                        Image(systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        nowPlayingService.nextTrack()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.top, 8)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    
                    Text("Nothing playing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Play music in Spotify or Apple Music")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
        }
        .onAppear {
            nowPlayingService.startMonitoring()
        }
    }
}

#Preview {
    MusicWidgetView()
        .environmentObject(SettingsManager.shared)
        .frame(width: 300)
        .padding()
        .preferredColorScheme(.dark)
}
