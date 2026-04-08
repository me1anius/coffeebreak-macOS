import AppKit
import Carbon.HIToolbox

/// The app delegate creates and retains the menu bar controller, timer
/// view model, and hotkey manager. It serves as the root of the app's object graph.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var viewModel: TimerViewModel?
    private var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permissions early
        NotificationManager.shared.requestAuthorization()

        // Add a hidden Edit menu so CMD+A/C/V/X work in text fields
        setupEditMenu()

        // Set default CMD+L for Rename Task on first launch
        if UserDefaults.standard.data(forKey: StorageKeys.renameTaskShortcut) == nil {
            let cmdL = ShortcutBinding(
                keyCode: UInt16(kVK_ANSI_L),
                modifiers: NSEvent.ModifierFlags.command.rawValue
            )
            if let data = try? JSONEncoder().encode(cmdL) {
                UserDefaults.standard.set(data, forKey: StorageKeys.renameTaskShortcut)
            }
        }


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

    // MARK: - Edit Menu

    /// Adds a standard Edit menu so CMD+A, CMD+C, CMD+V, CMD+X work in text fields.
    /// Menu-bar-only apps don't get one automatically.
    @MainActor private func setupEditMenu() {
        let mainMenu = NSMenu()

        let editMenuItem = NSMenuItem()
        editMenuItem.submenu = {
            let menu = NSMenu(title: "Edit")
            menu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
            menu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
            menu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
            menu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
            menu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
            menu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
            return menu
        }()

        mainMenu.addItem(editMenuItem)
        NSApp.mainMenu = mainMenu
    }
}
