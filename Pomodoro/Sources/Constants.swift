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
}

// MARK: - Visual Constants

enum AppColors {
    // Work session gradient: warm tomato red → orange
    static let workStart = Color(red: 0.95, green: 0.25, blue: 0.2)
    static let workEnd = Color(red: 1.0, green: 0.55, blue: 0.15)

    // Break session gradient: cool teal → blue
    static let breakStart = Color(red: 0.15, green: 0.78, blue: 0.75)
    static let breakEnd = Color(red: 0.25, green: 0.47, blue: 0.95)

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
