# 🦀 Krab

**Your AI assistant, always visible**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-14.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green.svg)](https://developer.apple.com/xcode/swiftui/)

Krab is a beautiful, highly customizable macOS widget app that keeps your AI assistant and essential information always visible. Built with SwiftUI and designed with a stunning glass morphism aesthetic.

<p align="center">
  <img src="docs/screenshot-dark.png" alt="Krab Screenshot" width="800">
</p>

## ✨ Features

### 🤖 AI Integration
- **AI Chat** - Connect to OpenClaw, OpenAI, or any compatible AI backend
- **Voice Commands** - Speak commands and get voice responses back
- **Context-aware** - AI remembers your conversation history

### 💬 Telegram Integration
- **Send & Receive Messages** - Stay connected without switching apps
- **Voice Notes** - Record and send voice messages
- **Real-time Updates** - Instant message notifications

### 📊 Customizable Widgets
- **Weather** - Current conditions, forecast, and location-based data
- **Calendar** - Upcoming events from Apple Calendar
- **Reminders** - Tasks and to-dos with completion tracking
- **Quick Notes** - Capture thoughts instantly
- **Now Playing** - Control music from Spotify, Apple Music, etc.
- **System Stats** - CPU, RAM, battery, and disk usage
- **Pomodoro Timer** - Stay focused with customizable work sessions
- **Quick Actions** - Custom shortcuts and commands

### 🎨 Beautiful Design
- **Glass Morphism** - Translucent, blurred backgrounds
- **Dark Mode First** - Designed for dark mode, supports light mode
- **Smooth Animations** - Fluid transitions and interactions
- **Crab Theme** - Subtle 🦀 theming throughout

### ⚙️ Maximum Customization
- **Themes** - Light, Dark, or System automatic
- **Custom Colors** - Choose your accent color
- **Transparency** - Adjust background opacity and blur
- **Typography** - Configure font size and style
- **Widget Layout** - Choose which widgets to display
- **Keyboard Shortcuts** - Global hotkeys for quick access

## 📥 Installation

### Requirements
- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later (for building from source)

### Build from Source

1. Clone the repository:
```bash
git clone https://github.com/Sleywill/Krab.git
cd Krab
```

2. Open in Xcode:
```bash
open Krab.xcodeproj
```

3. Build and run (⌘R)

### Download Release
Coming soon! Check the [Releases](https://github.com/Sleywill/Krab/releases) page.

## 🚀 Quick Start

1. **Launch Krab** - The app runs in the menu bar
2. **Grant Permissions** - Allow calendar, reminders, microphone, and location access
3. **Configure AI** - Go to Settings → AI and enter your API endpoint
4. **Set Up Telegram** (optional) - Add your bot token and chat ID
5. **Customize** - Explore Settings to personalize your experience

### Global Shortcuts
| Shortcut | Action |
|----------|--------|
| `⌥ Space` | Show/Hide Krab |
| `⌥ V` | Voice Command |
| `⌥ N` | Quick Note |

## ⚙️ Configuration

### AI Backend Setup

Krab supports any OpenAI-compatible API. Configure in Settings → AI:

```
Endpoint: http://localhost:3000/api/chat
Model: claude-3-sonnet
```

For **OpenClaw** users, Krab automatically detects local instances.

### Telegram Bot Setup

1. Create a bot via [@BotFather](https://t.me/BotFather)
2. Get your bot token
3. Start a chat with your bot and get the chat ID
4. Enter both in Settings → Telegram

## 🛠️ Tech Stack

- **SwiftUI** - Modern declarative UI framework
- **WidgetKit** - Native macOS widget support
- **EventKit** - Calendar and Reminders integration
- **Speech Framework** - Voice recognition
- **AVFoundation** - Audio recording and playback
- **Telegram Bot API** - Real-time messaging

## 📁 Project Structure

```
Krab/
├── Sources/
│   ├── App/
│   │   ├── KrabApp.swift       # App entry point
│   │   └── AppState.swift      # Global app state
│   ├── Models/
│   │   ├── Models.swift        # Data models
│   │   └── SettingsManager.swift
│   ├── Services/
│   │   ├── WeatherService.swift
│   │   ├── CalendarService.swift
│   │   ├── AIService.swift
│   │   ├── VoiceService.swift
│   │   ├── TelegramService.swift
│   │   └── ...
│   ├── Views/
│   │   ├── Main/
│   │   │   ├── ContentView.swift
│   │   │   ├── DashboardView.swift
│   │   │   └── AIChatView.swift
│   │   ├── Widgets/
│   │   │   ├── WeatherWidgetView.swift
│   │   │   └── ...
│   │   └── Settings/
│   │       └── SettingsView.swift
│   └── Utilities/
│       └── Utilities.swift
├── Assets.xcassets/
└── Info.plist
```

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Guidelines
- Follow Swift style guidelines
- Use SwiftUI best practices
- Add documentation for new features
- Write tests for critical functionality

### Ideas for Contributions
- [ ] More widget types (stocks, news, etc.)
- [ ] Multiple AI provider support
- [ ] Widget resizing and repositioning
- [ ] iCloud sync for settings
- [ ] Localization support
- [ ] Custom themes
- [ ] Notification Center widgets

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with ❤️ by the community
- Inspired by the need for a beautiful, always-visible AI assistant
- Thanks to all contributors and users!

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/Sleywill/Krab/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Sleywill/Krab/discussions)

---

<p align="center">
  Made with 🦀 by <a href="https://github.com/Sleywil">Sleywil</a>
</p>
