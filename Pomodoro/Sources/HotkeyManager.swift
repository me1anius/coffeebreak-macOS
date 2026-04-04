import AppKit
import Carbon.HIToolbox

// MARK: - Shortcut Action

/// The actions that can be triggered by global keyboard shortcuts.
enum ShortcutAction: String, CaseIterable, Sendable {
    case startPause = "Start / Pause"
    case skip = "Skip Session"
    case reset = "Reset Timer"

    /// The UserDefaults key storing this shortcut's binding.
    var storageKey: String {
        switch self {
        case .startPause: return "shortcut_startPause"
        case .skip:       return "shortcut_skip"
        case .reset:      return "shortcut_reset"
        }
    }

    /// Unique hotkey ID for Carbon registration.
    var hotkeyID: UInt32 {
        switch self {
        case .startPause: return 1
        case .skip:       return 2
        case .reset:      return 3
        }
    }

    static func from(hotkeyID: UInt32) -> ShortcutAction? {
        allCases.first { $0.hotkeyID == hotkeyID }
    }
}

// MARK: - Shortcut Binding

/// A persisted key combination: modifier flags + key code.
struct ShortcutBinding: Codable, Equatable, Sendable {
    let keyCode: UInt16
    let modifiers: UInt     // NSEvent.ModifierFlags.rawValue

    /// Human-readable string like "⌃⌥P"
    var displayString: String {
        var parts: [String] = []
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option)  { parts.append("⌥") }
        if flags.contains(.shift)   { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }
        parts.append(keyCodeToString(keyCode))
        return parts.joined()
    }

    /// Whether this binding includes Cmd or Ctrl (required for Sequoia compatibility).
    var hasCmdOrCtrl: Bool {
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        return flags.contains(.command) || flags.contains(.control)
    }

    /// Convert NSEvent modifier flags to Carbon modifier flags.
    var carbonModifiers: UInt32 {
        var carbon: UInt32 = 0
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.option)  { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.shift)   { carbon |= UInt32(shiftKey) }
        return carbon
    }

    func save(for action: ShortcutAction) {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: action.storageKey)
        }
    }

    static func load(for action: ShortcutAction) -> ShortcutBinding? {
        guard let data = UserDefaults.standard.data(forKey: action.storageKey) else { return nil }
        return try? JSONDecoder().decode(ShortcutBinding.self, from: data)
    }

    static func remove(for action: ShortcutAction) {
        UserDefaults.standard.removeObject(forKey: action.storageKey)
    }
}

// MARK: - Hotkey Manager

/// Global singleton reference so the C callback can reach the manager.
/// Carbon event handlers are C function pointers and can't capture Swift context.
private nonisolated(unsafe) var sharedHotkeyManager: HotkeyManager?

/// Registers global keyboard shortcuts using Carbon's RegisterEventHotKey.
/// This works inside the App Sandbox without any permission prompts.
@MainActor
final class HotkeyManager {
    private var registeredHotkeys: [EventHotKeyRef] = []
    private weak var viewModel: TimerViewModel?
    private var eventHandler: EventHandlerRef?

    init(viewModel: TimerViewModel) {
        self.viewModel = viewModel
        sharedHotkeyManager = self
        installEventHandler()
        registerAll()
    }

    func cleanup() {
        unregisterAll()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
        sharedHotkeyManager = nil
    }

    /// Unregister all hotkeys and re-register from saved bindings.
    func reload() {
        unregisterAll()
        registerAll()
    }

    // MARK: - Carbon Event Handler

    /// Install a single Carbon event handler that dispatches all hotkey events.
    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            carbonHotkeyCallback,
            1,
            &eventType,
            nil,
            &eventHandler
        )

        if status != noErr {
            print("Failed to install Carbon event handler: \(status)")
        }
    }

    // MARK: - Register / Unregister

    private func registerAll() {
        for action in ShortcutAction.allCases {
            guard let binding = ShortcutBinding.load(for: action) else { continue }
            register(action: action, binding: binding)
        }
    }

    private func register(action: ShortcutAction, binding: ShortcutBinding) {
        let hotkeyID = EventHotKeyID(
            signature: OSType(0x504F4D4F),  // "POMO" as FourCharCode
            id: action.hotkeyID
        )

        var hotkeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(binding.keyCode),
            binding.carbonModifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        if status == noErr, let ref = hotkeyRef {
            registeredHotkeys.append(ref)
        } else {
            print("Failed to register hotkey for \(action.rawValue): \(status)")
        }
    }

    private func unregisterAll() {
        for ref in registeredHotkeys {
            UnregisterEventHotKey(ref)
        }
        registeredHotkeys.removeAll()
    }

    // MARK: - Handle Hotkey Event

    /// Called from the C callback when a registered hotkey is pressed.
    func handleHotkey(id: UInt32) {
        guard let action = ShortcutAction.from(hotkeyID: id),
              let vm = viewModel else { return }
        switch action {
        case .startPause: vm.startPause()
        case .skip:       vm.skipSession()
        case .reset:      vm.reset()
        }
    }
}

// MARK: - Carbon C Callback

/// C-compatible callback for Carbon hotkey events. Dispatches to the shared manager.
private func carbonHotkeyCallback(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event = event else { return OSStatus(eventNotHandledErr) }

    var hotkeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        UInt32(kEventParamDirectObject),
        UInt32(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotkeyID
    )

    guard status == noErr else { return status }

    DispatchQueue.main.async {
        sharedHotkeyManager?.handleHotkey(id: hotkeyID.id)
    }

    return noErr
}

// MARK: - Key Code to String

/// Converts a virtual key code to a readable key name.
func keyCodeToString(_ keyCode: UInt16) -> String {
    switch Int(keyCode) {
    case kVK_ANSI_A: return "A"
    case kVK_ANSI_B: return "B"
    case kVK_ANSI_C: return "C"
    case kVK_ANSI_D: return "D"
    case kVK_ANSI_E: return "E"
    case kVK_ANSI_F: return "F"
    case kVK_ANSI_G: return "G"
    case kVK_ANSI_H: return "H"
    case kVK_ANSI_I: return "I"
    case kVK_ANSI_J: return "J"
    case kVK_ANSI_K: return "K"
    case kVK_ANSI_L: return "L"
    case kVK_ANSI_M: return "M"
    case kVK_ANSI_N: return "N"
    case kVK_ANSI_O: return "O"
    case kVK_ANSI_P: return "P"
    case kVK_ANSI_Q: return "Q"
    case kVK_ANSI_R: return "R"
    case kVK_ANSI_S: return "S"
    case kVK_ANSI_T: return "T"
    case kVK_ANSI_U: return "U"
    case kVK_ANSI_V: return "V"
    case kVK_ANSI_W: return "W"
    case kVK_ANSI_X: return "X"
    case kVK_ANSI_Y: return "Y"
    case kVK_ANSI_Z: return "Z"
    case kVK_ANSI_0: return "0"
    case kVK_ANSI_1: return "1"
    case kVK_ANSI_2: return "2"
    case kVK_ANSI_3: return "3"
    case kVK_ANSI_4: return "4"
    case kVK_ANSI_5: return "5"
    case kVK_ANSI_6: return "6"
    case kVK_ANSI_7: return "7"
    case kVK_ANSI_8: return "8"
    case kVK_ANSI_9: return "9"
    case kVK_Space:          return "Space"
    case kVK_Return:         return "↩"
    case kVK_Tab:            return "⇥"
    case kVK_Escape:         return "⎋"
    case kVK_Delete:         return "⌫"
    case kVK_ForwardDelete:  return "⌦"
    case kVK_UpArrow:        return "↑"
    case kVK_DownArrow:      return "↓"
    case kVK_LeftArrow:      return "←"
    case kVK_RightArrow:     return "→"
    case kVK_F1:  return "F1"
    case kVK_F2:  return "F2"
    case kVK_F3:  return "F3"
    case kVK_F4:  return "F4"
    case kVK_F5:  return "F5"
    case kVK_F6:  return "F6"
    case kVK_F7:  return "F7"
    case kVK_F8:  return "F8"
    case kVK_F9:  return "F9"
    case kVK_F10: return "F10"
    case kVK_F11: return "F11"
    case kVK_F12: return "F12"
    case kVK_ANSI_Minus:        return "-"
    case kVK_ANSI_Equal:        return "="
    case kVK_ANSI_LeftBracket:  return "["
    case kVK_ANSI_RightBracket: return "]"
    case kVK_ANSI_Backslash:    return "\\"
    case kVK_ANSI_Semicolon:    return ";"
    case kVK_ANSI_Quote:        return "'"
    case kVK_ANSI_Comma:        return ","
    case kVK_ANSI_Period:       return "."
    case kVK_ANSI_Slash:        return "/"
    case kVK_ANSI_Grave:        return "`"
    default: return "Key\(keyCode)"
    }
}
