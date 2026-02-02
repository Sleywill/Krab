import SwiftUI
import AppKit

@main
struct KrabApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared
    @StateObject private var settings = SettingsManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(settings)
                .frame(minWidth: 400, minHeight: 300)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Krab") {
                    appState.showAbout = true
                }
            }
            CommandGroup(replacing: .newItem) {}
        }
        
        Settings {
            SettingsView()
                .environmentObject(settings)
        }
        
        MenuBarExtra("Krab", systemImage: "bubble.left.and.bubble.right.fill") {
            MenuBarView()
                .environmentObject(appState)
                .environmentObject(settings)
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover = NSPopover()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request permissions
        PermissionsManager.shared.requestAllPermissions()
        
        // Setup global hotkey
        HotkeyManager.shared.registerGlobalHotkey()
        
        // Start services
        WeatherService.shared.startUpdating()
        CalendarService.shared.startUpdating()
        SystemStatsService.shared.startMonitoring()
        
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregisterGlobalHotkey()
    }
}
