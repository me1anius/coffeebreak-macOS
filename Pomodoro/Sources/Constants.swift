import SwiftUI

// MARK: - Default Timer Durations (in seconds)

enum Defaults {
    static let workDuration: Double = 25 * 60        // 25 minutes
    static let shortBreakDuration: Double = 5 * 60   // 5 minutes
    static let longBreakDuration: Double = 15 * 60   // 15 minutes
    static let pomodorosBeforeLongBreak: Int = 4
}

// MARK: - UserDefaults Keys

enum StorageKeys {
    static let workDuration = "workDuration"
    static let shortBreakDuration = "shortBreakDuration"
    static let longBreakDuration = "longBreakDuration"
    static let pomodorosBeforeLongBreak = "pomodorosBeforeLongBreak"
    static let autoStartBreaks = "autoStartBreaks"
    static let autoStartPomodoros = "autoStartPomodoros"
    static let playSoundOnEnd = "playSoundOnEnd"
    static let showTimerInMenuBar = "showTimerInMenuBar"
    static let tickSoundEnabled = "tickSoundEnabled"
    static let recentLabels = "recentLabels"
    static let hasSeenOnboarding = "hasSeenOnboarding"
    static let swipeGestureEnabled = "swipeGestureEnabled"
    static let countdownTickEnabled = "countdownTickEnabled"
}

// MARK: - Visual Constants

enum AppColors {
    // Work session gradient: warm caramel → espresso brown (smooth wrap)
    static let workStart = Color(red: 0.72, green: 0.50, blue: 0.30)
    static let workEnd = Color(red: 0.38, green: 0.22, blue: 0.12)

    // Break session gradient: soft latte → warm cream
    static let breakStart = Color(red: 0.68, green: 0.52, blue: 0.38)
    static let breakEnd = Color(red: 0.88, green: 0.76, blue: 0.60)

    // Coffee surface colors for ring fill
    static let coffeeDark = Color(red: 0.28, green: 0.16, blue: 0.08)
    static let coffeeMid = Color(red: 0.38, green: 0.24, blue: 0.14)
    static let crema = Color(red: 0.82, green: 0.68, blue: 0.50)

    static func gradientForSession(_ isWork: Bool) -> [Color] {
        isWork ? [workStart, workEnd] : [breakStart, breakEnd]
    }
}

enum AppSizing {
    static let popoverWidth: CGFloat = 280
    static let popoverHeight: CGFloat = 380
    static let ringSize: CGFloat = 160
    static let ringLineWidth: CGFloat = 12
    static let buttonSize: CGFloat = 44
}
