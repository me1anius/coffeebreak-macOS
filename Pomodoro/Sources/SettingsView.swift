import SwiftUI

/// Settings panel displayed inline within the popover.
/// Uses @AppStorage to persist all settings to UserDefaults automatically.
struct SettingsView: View {
    @ObservedObject var viewModel: TimerViewModel

    /// Tracks which shortcut action is currently being recorded (nil = none).
    @State private var recordingAction: ShortcutAction? = nil
    /// Local monitor used during shortcut recording.
    @State private var localMonitor: Any? = nil
    /// Force re-read of shortcuts from UserDefaults.
    @State private var shortcutRefresh: Bool = false
    /// Shows an error when user tries an invalid shortcut combo.
    @State private var shortcutError: Bool = false

    // Duration settings (stored in seconds)
    @AppStorage(StorageKeys.workDuration) private var workDuration: Double = Defaults.workDuration
    @AppStorage(StorageKeys.shortBreakDuration) private var shortBreakDuration: Double = Defaults.shortBreakDuration
    @AppStorage(StorageKeys.longBreakDuration) private var longBreakDuration: Double = Defaults.longBreakDuration
    @AppStorage(StorageKeys.pomodorosBeforeLongBreak) private var pomodorosBeforeLongBreak: Int = Defaults.pomodorosBeforeLongBreak

    // Behavior toggles
    @AppStorage(StorageKeys.autoStartBreaks) private var autoStartBreaks: Bool = false
    @AppStorage(StorageKeys.autoStartPomodoros) private var autoStartPomodoros: Bool = false
    @AppStorage(StorageKeys.playSoundOnEnd) private var playSoundOnEnd: Bool = true
    @AppStorage(StorageKeys.showTimerInMenuBar) private var showTimerInMenuBar: Bool = true
    @AppStorage(StorageKeys.tickSoundEnabled) private var tickSoundEnabled: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button(action: {
                    viewModel.showSettings = false
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(SubtleButtonStyle())

                Spacer()

                Text("Settings")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))

                Spacer()

                // Invisible spacer to center the title
                Color.clear.frame(width: 26, height: 26)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // MARK: Duration Settings
                    settingsSection("Durations") {
                        durationStepper("Focus", value: $workDuration, range: 60...3600, step: 60)
                        durationStepper("Short Break", value: $shortBreakDuration, range: 60...1800, step: 60)
                        durationStepper("Long Break", value: $longBreakDuration, range: 60...3600, step: 60)
                        stepperRow("Pomodoros", value: $pomodorosBeforeLongBreak, range: 2...10)
                    }

                    // MARK: Behavior Settings
                    settingsSection("Behavior") {
                        toggleRow("Auto-start breaks", isOn: $autoStartBreaks)
                        toggleRow("Auto-start pomodoros", isOn: $autoStartPomodoros)
                    }

                    // MARK: Sound Settings
                    settingsSection("Sound & Display") {
                        toggleRow("Sound on session end", isOn: $playSoundOnEnd)
                        toggleRow("Tick sound each second", isOn: $tickSoundEnabled)
                        toggleRow("Show timer in menu bar", isOn: $showTimerInMenuBar)
                    }

                    // MARK: Keyboard Shortcuts
                    settingsSection("Shortcuts") {
                        ForEach(ShortcutAction.allCases, id: \.rawValue) { action in
                            shortcutRow(action)
                        }

                        if shortcutError {
                            Text("Must include ⌘ or ⌃")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(.red.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .transition(.opacity)
                        }

                        Text("Shortcuts must include ⌘ or ⌃")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.quaternary)
                            .frame(maxWidth: .infinity)
                    }

                    // MARK: Reset Defaults
                    Button(action: resetDefaults) {
                        Text("Reset Defaults")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 14)
                            .background(
                                Capsule()
                                    .fill(Color.primary.opacity(0.06))
                            )
                    }
                    .buttonStyle(SpringButtonStyle())
                    .padding(.top, 4)
                    .padding(.bottom, 12)
                }
                .padding(.horizontal, 16)
            }
        }
        .frame(width: AppSizing.popoverWidth, height: AppSizing.popoverHeight)
    }

    // MARK: - Section Builder

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.tertiary)
                .padding(.leading, 2)

            VStack(spacing: 2) {
                content()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
        }
    }

    // MARK: - Row Components

    /// A stepper for duration values (stored in seconds, displayed as minutes).
    private func durationStepper(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .regular, design: .rounded))

            Spacer()

            HStack(spacing: 8) {
                Button(action: {
                    value.wrappedValue = max(range.lowerBound, value.wrappedValue - step)
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Text("\(Int(value.wrappedValue / 60)) min")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .frame(width: 46, alignment: .center)

                Button(action: {
                    value.wrappedValue = min(range.upperBound, value.wrappedValue + step)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
    }

    /// An integer stepper row.
    private func stepperRow(_ label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .regular, design: .rounded))

            Spacer()

            HStack(spacing: 8) {
                Button(action: {
                    value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1)
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Text("\(value.wrappedValue)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .frame(width: 46, alignment: .center)

                Button(action: {
                    value.wrappedValue = min(range.upperBound, value.wrappedValue + 1)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
    }

    /// A toggle row.
    private func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .font(.system(size: 12, weight: .regular, design: .rounded))
        }
        .toggleStyle(.switch)
        .controlSize(.mini)
        .padding(.vertical, 1)
    }

    // MARK: - Shortcut Row

    private func shortcutRow(_ action: ShortcutAction) -> some View {
        let _ = shortcutRefresh // Force SwiftUI to re-evaluate when this toggles
        let binding = ShortcutBinding.load(for: action)
        let isRecording = recordingAction == action

        return HStack {
            Text(action.rawValue)
                .font(.system(size: 12, weight: .regular, design: .rounded))

            Spacer()

            if isRecording {
                Text("Press shortcut...")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.orange)
                    .frame(minWidth: 80)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(.orange.opacity(0.5), lineWidth: 1)
                    )
            } else if let binding = binding {
                HStack(spacing: 4) {
                    Button(action: { startRecording(action) }) {
                        Text(binding.displayString)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.primary)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(Color.primary.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: { clearShortcut(action) }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button(action: { startRecording(action) }) {
                    Text("Record")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.primary.opacity(0.06))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
    }

    private func startRecording(_ action: ShortcutAction) {
        recordingAction = action
        shortcutError = false

        // Listen for the next key press locally (inside the app's popover)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            let mods = event.modifierFlags.intersection([.control, .option, .shift, .command])

            // Escape cancels recording
            if event.keyCode == 53 { // kVK_Escape
                stopRecording()
                return nil
            }

            let binding = ShortcutBinding(keyCode: event.keyCode, modifiers: mods.rawValue)

            // Require Cmd or Ctrl for macOS Sequoia compatibility
            guard binding.hasCmdOrCtrl else {
                withAnimation { shortcutError = true }
                // Auto-hide error after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { self.shortcutError = false }
                }
                return nil
            }

            binding.save(for: action)
            stopRecording()
            viewModel.onShortcutsChanged?()
            return nil  // Consume the event
        }
    }

    private func stopRecording() {
        recordingAction = nil
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        shortcutRefresh.toggle()
    }

    private func clearShortcut(_ action: ShortcutAction) {
        ShortcutBinding.remove(for: action)
        viewModel.onShortcutsChanged?()
        shortcutRefresh.toggle()
    }

    // MARK: - Reset Defaults

    private func resetDefaults() {
        workDuration = Defaults.workDuration
        shortBreakDuration = Defaults.shortBreakDuration
        longBreakDuration = Defaults.longBreakDuration
        pomodorosBeforeLongBreak = Defaults.pomodorosBeforeLongBreak
        autoStartBreaks = false
        autoStartPomodoros = false
        playSoundOnEnd = true
        showTimerInMenuBar = true
        tickSoundEnabled = false

        // Clear all shortcuts
        for action in ShortcutAction.allCases {
            ShortcutBinding.remove(for: action)
        }
        viewModel.onShortcutsChanged?()
        shortcutRefresh.toggle()
    }
}
