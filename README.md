# Task Management

A native iOS task manager built with SwiftUI, MVVM, Firebase Authentication, Cloud Firestore, Firebase Cloud Messaging, local notifications, and Swift Charts.

## Features

- Email/password account creation and sign-in, persisted Firebase sessions, and password reset.
- User-scoped task create, edit, complete/reopen, delete, and real-time Firestore updates.
- Title and due-date validation, plus searchable tasks and status/due-date filters.
- Dashboard metrics and a status bar chart.
- Firestore's on-device persistent cache for offline viewing and queued writes that synchronize when connectivity returns.
- Per-task local due-date notifications and Firebase Messaging/APNs registration hooks.
- Dark Mode and adaptive layouts, plus focused ViewModel unit tests.

## Requirements

- Xcode 15 or later (iOS 17 deployment target).
- An Apple Developer team for device signing and push notification delivery.
- A Firebase project with an iOS app registered using the bundle identifier `com.example.TaskManagement`.

## Configure Firebase

1. In the Firebase console, create a project and register an iOS app with bundle ID `com.example.TaskManagement` (or change the app target bundle ID and register that value).
2. Download that app's `GoogleService-Info.plist` and add it to the `TaskManagement` app target in Xcode. Keep it out of source control; the repository ignores this project-specific file.
3. Enable **Email/Password** under Firebase Authentication → Sign-in method.
4. Create a Cloud Firestore database and deploy the included rules:

   ```sh
   firebase login
   firebase use --add
   firebase deploy --only firestore:rules
   ```

   The rules permit signed-in users to read/write only `/users/{their-uid}/tasks/{task-id}` and validate the task document shape. Do not replace them with public/test rules.
5. Open `TaskManagement.xcodeproj` in Xcode and allow Swift Package Manager to resolve the Firebase iOS SDK dependency (`FirebaseAuth`, `FirebaseFirestore`, and `FirebaseMessaging`).
6. Select the app scheme, set your development team, and build/run on an iOS 17+ simulator or device.

## Push notifications and reminders

The app registers with APNs after notification permission is granted, forwards the APNs device token to Firebase Messaging, and receives FCM registration-token updates through `ReminderService`. Local due-date notifications are scheduled for pending tasks on the device.

For remote pushes, configure an APNs authentication key in Firebase Cloud Messaging, enable Push Notifications (and Background Modes → Remote notifications if your server sends background/data pushes) for the app target, and provide a trusted server/Cloud Function to associate the FCM token with the authenticated account and send messages. This project intentionally does not store or expose FCM tokens in Firestore and does not send pushes from the client; a secure server-side sender is required for remote delivery.

## Offline behavior and data layout

Firestore's Apple SDK persistent cache is enabled by default. The task listener initially renders cached documents when available, and Firestore synchronizes pending writes and remote changes when the device reconnects. No additional local database or duplicate task cache is maintained.

Tasks are stored at:

```text
users/{Firebase Auth UID}/tasks/{task document ID}
```

Each task contains `title`, `description`, `dueDate`, `status` (`Pending` or `Completed`), `createdAt`, and `updatedAt`.

## Run tests

Open the project in Xcode and run the `TaskManagement` scheme's tests (`Product → Test`, or `⌘U`). Tests cover task validation, dashboard counts, search, and status filtering.

## Project layout

```text
TaskManagement/
  Models/       Task model and filters
  Services/     Firebase Auth, Firestore, and notification services
  ViewModels/   Observable MVVM state and validation
  Views/        Authentication, task editor/list, dashboard, settings
TaskManagementTests/
firestore.rules
```
