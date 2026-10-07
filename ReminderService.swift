import FirebaseMessaging
import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

final class ReminderService: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    static let shared = ReminderService()

    private override init() {
        super.init()
    }

    func configure() {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }

    func requestPermission() async throws {
        let granted = try await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])
        guard granted else {
            throw ReminderError.permissionDenied
        }
        await MainActor.run {
            UIApplicationRegistration.registerForRemoteNotifications()
        }
    }

    func scheduleReminder(for task: TaskItem) async throws {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [task.id])
        guard task.status == .pending, task.dueDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "Task due"
        content.body = task.title
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: task.dueDate
            ),
            repeats: false
        )
        try await center.add(
            UNNotificationRequest(identifier: task.id, content: content, trigger: trigger)
        )
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        NotificationCenter.default.post(
            name: .fcmTokenDidChange,
            object: nil,
            userInfo: ["token": fcmToken]
        )
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}

enum ReminderError: LocalizedError {
    case permissionDenied

    var errorDescription: String? {
        return "Notification permission is disabled. Enable notifications in Settings to receive reminders."
    }
}

extension Notification.Name {
    static let fcmTokenDidChange = Notification.Name("fcmTokenDidChange")
}

private enum UIApplicationRegistration {
    static func registerForRemoteNotifications() {
        #if canImport(UIKit)
        UIApplication.shared.registerForRemoteNotifications()
        #endif
    }
}
