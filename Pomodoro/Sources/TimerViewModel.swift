import Foundation
import Combine
import SwiftUI

// MARK: - Session Type

enum SessionType: String {
    case work = "Focus Time"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"

    var isBreak: Bool {
        self != .work
    }
}

// MARK: - Timer State

enum TimerState {
    case idle
    case running
    case paused
}

// MARK: - Timer ViewModel

/// Central state manager for the Pomodoro timer. Runs independently of any UI —
/// the timer continues ticking even when the popover is closed because we use
/// a Combine Timer publisher on the main run loop.
@MainActor
final class TimerViewModel: ObservableObject {

    // MARK: Published State

    @Published var timerState: TimerState = .idle
    @Published var sessionType: SessionType = .work
    @Published var remainingSeconds: Double = Defaults.workDuration
    @Published var completedPomodoros: Int = 0
    @Published var showSettings: Bool = false
    @Published var sessionName: String = ""

    // MARK: Settings (persisted via @AppStorage in SettingsView, read here via UserDefaults)

    var workDuration: Double {
        UserDefaults.standard.double(forKey: StorageKeys.workDuration).clamped(fallback: Defaults.workDuration)
    }
    var shortBreakDuration: Double {
        UserDefaults.standard.double(forKey: StorageKeys.shortBreakDuration).clamped(fallback: Defaults.shortBreakDuration)
    }
    var longBreakDuration: Double {
        UserDefaults.standard.double(forKey: StorageKeys.longBreakDuration).clamped(fallback: Defaults.longBreakDuration)
    }
    var pomodorosBeforeLongBreak: Int {
        let val = UserDefaults.standard.integer(forKey: StorageKeys.pomodorosBeforeLongBreak)
        return val > 0 ? val : Defaults.pomodorosBeforeLongBreak
    }
    var autoStartBreaks: Bool {
        UserDefaults.standard.bool(forKey: StorageKeys.autoStartBreaks)
    }
    var autoStartPomodoros: Bool {
        UserDefaults.standard.bool(forKey: StorageKeys.autoStartPomodoros)
    }
    var playSoundOnEnd: Bool {
        // Default to true if never set
        UserDefaults.standard.object(forKey: StorageKeys.playSoundOnEnd) == nil
            ? true
            : UserDefaults.standard.bool(forKey: StorageKeys.playSoundOnEnd)
    }
    var showTimerInMenuBar: Bool {
        UserDefaults.standard.object(forKey: StorageKeys.showTimerInMenuBar) == nil
            ? true
            : UserDefaults.standard.bool(forKey: StorageKeys.showTimerInMenuBar)
    }
    var tickSoundEnabled: Bool {
        UserDefaults.standard.bool(forKey: StorageKeys.tickSoundEnabled)
    }

    // MARK: Computed

    /// Total duration of the current session, used for progress calculation.
    var totalDuration: Double {
        switch sessionType {
        case .work: return workDuration
        case .shortBreak: return shortBreakDuration
        case .longBreak: return longBreakDuration
        }
    }

    /// Progress from 0 (just started) to 1 (complete).
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (remainingSeconds / totalDuration)
    }

    /// Formatted time string, e.g. "18:32".
    var formattedTime: String {
        let minutes = Int(remainingSeconds) / 60
        let seconds = Int(remainingSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Text shown in the menu bar.
    var menuBarText: String {
        switch timerState {
        case .idle:
            return "🍅 Ready"
        case .paused:
            if showTimerInMenuBar {
                return "🍅 \(formattedTime) ⏸"
            }
            return "🍅 Paused"
        case .running:
            if showTimerInMenuBar {
                let icon = sessionType.isBreak ? "☕" : "🍅"
                return "\(icon) \(formattedTime)"
            }
            return sessionType.isBreak ? "☕" : "🍅"
        }
    }

    /// Callback for the menu bar controller to update the status item text.
    var onMenuBarTextChange: ((String) -> Void)?

    /// Callback to reload hotkey bindings after shortcuts are changed in settings.
    var onShortcutsChanged: (() -> Void)?
    /// Callback to pause/resume hotkeys during shortcut recording.
    var onHotkeysPause: (() -> Void)?
    var onHotkeysResume: (() -> Void)?

    // MARK: Private

    private var timerCancellable: AnyCancellable?

    // MARK: - Actions

    func startPause() {
        switch timerState {
        case .idle:
            start()
        case .running:
            pause()
        case .paused:
            resume()
        }
    }

    func start() {
        if timerState == .idle {
            // Reset remaining time to the full session duration
            remainingSeconds = totalDuration
        }
        timerState = .running
        startTimer()
    }

    func pause() {
        timerState = .paused
        stopTimer()
        notifyMenuBar()
    }

    func resume() {
        timerState = .running
        startTimer()
    }

    func reset() {
        stopTimer()
        timerState = .idle
        sessionType = .work
        remainingSeconds = workDuration
        completedPomodoros = 0
        notifyMenuBar()
    }

    func skipSession() {
        stopTimer()
        sessionComplete()
    }

    // MARK: - Timer Engine

    /// Uses Combine's Timer.publish which fires on the main RunLoop. This keeps
    /// ticking even when the popover is closed because the RunLoop keeps running
    /// for a menu bar app.
    private func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func tick() {
        guard remainingSeconds > 0 else { return }

        remainingSeconds -= 1
        notifyMenuBar()

        // Optional tick sound
        if tickSoundEnabled {
            NotificationManager.shared.playTickSound()
        }

        // 10-second countdown alert at the end of breaks
        if sessionType.isBreak && remainingSeconds <= 10 && remainingSeconds > 0 {
            NotificationManager.shared.playTickSound()
            if remainingSeconds == 10 {
                NotificationManager.shared.sendSessionNotification(
                    title: "Break ending soon!",
                    body: "10 seconds until focus time resumes."
                )
            }
        }

        if remainingSeconds <= 0 {
            sessionComplete()
        }
    }

    // MARK: - Session Transitions

    private func sessionComplete() {
        stopTimer()

        if sessionType == .work {
            // Play chime 3 times to grab attention during focus
            if playSoundOnEnd {
                NotificationManager.shared.playCompletionSound()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    NotificationManager.shared.playCompletionSound()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    NotificationManager.shared.playCompletionSound()
                }
            }

            completedPomodoros += 1

            // Determine break type
            if completedPomodoros % pomodorosBeforeLongBreak == 0 {
                sessionType = .longBreak
                remainingSeconds = longBreakDuration

                NotificationManager.shared.sendSessionNotification(
                    title: "Focus session complete!",
                    body: "Great work! Time for a long break. You've completed \(completedPomodoros) sessions."
                )
            } else {
                sessionType = .shortBreak
                remainingSeconds = shortBreakDuration

                NotificationManager.shared.sendSessionNotification(
                    title: "Focus session complete!",
                    body: "Time for a short break. Session \(completedPomodoros) of \(pomodorosBeforeLongBreak) done."
                )
            }

            if autoStartBreaks {
                timerState = .running
                startTimer()
            } else {
                timerState = .idle
            }
        } else {
            // Break ended
            if playSoundOnEnd {
                NotificationManager.shared.playCompletionSound()
            }

            sessionType = .work
            remainingSeconds = workDuration

            NotificationManager.shared.sendSessionNotification(
                title: "Break's over!",
                body: autoStartPomodoros ? "Focus time is starting now." : "Ready to focus again? Let's go!"
            )

            if autoStartPomodoros {
                timerState = .running
                startTimer()
            } else {
                timerState = .idle
            }
        }

        notifyMenuBar()
    }

    private func notifyMenuBar() {
        onMenuBarTextChange?(menuBarText)
    }
}

// MARK: - Double Extension

private extension Double {
    /// Returns self if > 0, otherwise returns the fallback.
    func clamped(fallback: Double) -> Double {
        self > 0 ? self : fallback
    }
}
