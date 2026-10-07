import FirebaseCore
import FirebaseMessaging
import SwiftUI
import UIKit

@main
struct TaskManagementApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if let userID = authViewModel.userID {
                    MainTabView(userID: userID, authViewModel: authViewModel)
                } else {
                    AuthenticationView(viewModel: authViewModel)
                }
            }
            .preferredColorScheme(nil)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        ReminderService.shared.configure()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
}
