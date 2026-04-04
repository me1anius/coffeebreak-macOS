import AppKit

/// The app delegate creates and retains the menu bar controller, timer
/// view model, and hotkey manager. It serves as the root of the app's object graph.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var viewModel: TimerViewModel?
    private var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permissions early
        NotificationManager.shared.requestAuthorization()

        // Create the shared view model
        let vm = TimerViewModel()
        viewModel = vm

        // Create the menu bar controller (sets up status item + popover)
        menuBarController = MenuBarController(viewModel: vm)

        // Register global keyboard shortcuts
        let hkm = HotkeyManager(viewModel: vm)
        hotkeyManager = hkm

        // Let the view model notify the hotkey manager to reload when shortcuts change
        vm.onShortcutsChanged = { [weak hkm] in
            hkm?.reload()
        }
        vm.onHotkeysPause = { [weak hkm] in
            hkm?.unregisterAllPublic()
        }
        vm.onHotkeysResume = { [weak hkm] in
            hkm?.reload()
        }
    }
}
