import Foundation
import UserNotifications
import AppKit

/// Handles macOS notifications and sound playback for session transitions.
/// Not confined to @MainActor because notification callbacks arrive on arbitrary queues.
final class NotificationManager: @unchecked Sendable {
    static let shared = NotificationManager()

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

    /// Play a subtle tick sound (system "Tink").
    @MainActor
    func playTickSound() {
        NSSound(named: "Tink")?.play()
    }
}
