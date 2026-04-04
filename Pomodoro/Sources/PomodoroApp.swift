import AppKit

/// Pure AppKit entry point. We avoid SwiftUI's @main App protocol entirely
/// because a menu-bar-only app with `LSUIElement = YES` and no visible windows
/// can cause SwiftUI's scene management to terminate the process prematurely.
///
/// Instead, we set up NSApplication manually and use AppDelegate to create
/// the status item and popover.
@main
enum PomodoroApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate

        // Activation policy .accessory = no Dock icon, no app switcher entry
        app.setActivationPolicy(.accessory)

        app.run()
    }
}
