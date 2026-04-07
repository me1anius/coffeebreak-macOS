import Foundation
import UserNotifications
import AppKit
import AudioToolbox

/// Handles macOS notifications and sound playback for session transitions.
/// Not confined to @MainActor because notification callbacks arrive on arbitrary queues.
final class NotificationManager: @unchecked Sendable {
    static let shared = NotificationManager()

    /// System sound ID for the tick — plays on a system thread, zero main thread impact.
    private var tickSoundID: SystemSoundID = {
        var soundID: SystemSoundID = 0
        if let url = Bundle.main.url(forResource: "tick", withExtension: "aiff") {
            AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        }
        return soundID
    }()


    private init() {}

    /// Request notification permission on first launch.
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
        }
    }

    /// Send a local notification when a session ends.
    func sendSessionNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to deliver notification: \(error.localizedDescription)")
            }
        }
    }

    /// Play the system "Glass" sound as a gentle chime.
    @MainActor
    func playCompletionSound() {
        NSSound(named: "Glass")?.play()
    }

    /// Play the tick sound via AudioServices — runs on a system thread, doesn't touch the RunLoop.
    func playTickSound() {
        guard tickSoundID != 0 else { return }
        AudioServicesPlaySystemSound(tickSoundID)
    }

}
