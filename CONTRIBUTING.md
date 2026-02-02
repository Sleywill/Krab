# Contributing to Krab 🦀

First off, thank you for considering contributing to Krab! It's people like you that make Krab such a great tool.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct. Please be respectful and considerate of others.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title** describing the issue
- **Steps to reproduce** the behavior
- **Expected behavior** vs what actually happened
- **Screenshots** if applicable
- **Environment details** (macOS version, Xcode version)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear title** describing the suggestion
- **Provide a detailed description** of the proposed functionality
- **Explain why** this enhancement would be useful
- **Include mockups** if you have design ideas

### Pull Requests

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. Ensure your code follows the existing style
4. Make sure your code builds without warnings
5. Write a clear PR description

## Development Setup

### Requirements
- macOS 14.0 or later
- Xcode 15.0 or later
- Swift 5.9

### Getting Started

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/Krab.git
cd Krab

# Open in Xcode
open Krab.xcodeproj

# Build and run
# Press ⌘R in Xcode
```

## Style Guidelines

### Swift Code Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftUI's declarative style
- Prefer `@StateObject` for owned observable objects
- Use `@EnvironmentObject` for shared state
- Keep views small and focused

### Code Organization

```swift
// MARK: - Properties
// MARK: - Body
// MARK: - Subviews
// MARK: - Methods
```

### Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters
- Reference issues and pull requests when relevant

### Example Commit Message

```
Add weather widget refresh button

- Add manual refresh functionality
- Show loading indicator during refresh
- Handle network errors gracefully

Fixes #123
```

## Project Structure

```
Krab/
├── Sources/
│   ├── App/           # App lifecycle and state
│   ├── Models/        # Data models and settings
│   ├── Services/      # Business logic and API calls
│   ├── Views/         # SwiftUI views
│   │   ├── Main/      # Main app views
│   │   ├── Widgets/   # Widget views
│   │   └── Settings/  # Settings views
│   └── Utilities/     # Helpers and extensions
└── Assets.xcassets/   # Images and colors
```

## Adding a New Widget

1. Create a new file in `Views/Widgets/`
2. Follow the existing widget pattern:

```swift
struct MyNewWidgetView: View {
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        WidgetCard(title: "My Widget", icon: "star", color: .blue) {
            // Widget content
        }
    }
}
```

3. Add the widget type to `WidgetType` enum in `Models.swift`
4. Add the widget to `DashboardView.swift`
5. Add toggle in `WidgetsSettingsView`

## Adding a New Service

1. Create a new file in `Services/`
2. Use the singleton pattern:

```swift
@MainActor
class MyService: ObservableObject {
    static let shared = MyService()
    
    @Published var data: MyData?
    
    func fetchData() async {
        // Implementation
    }
}
```

3. Initialize in `AppDelegate` if needed

## Testing

While we don't have extensive tests yet, please ensure:

- Your code compiles without warnings
- The app runs without crashes
- Your feature works as expected
- Existing features still work

## Documentation

- Add inline documentation for public APIs
- Update README if adding user-facing features
- Include code examples in documentation

## Questions?

Feel free to open an issue with your question or reach out in GitHub Discussions.

Thank you for contributing! 🦀
