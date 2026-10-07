import SwiftUI

struct SettingsView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var notificationMessage: String?
    @State private var isRequestingNotifications = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    LabeledContent("Signed in as", value: authViewModel.email)
                    Button("Sign out", role: .destructive) {
                        authViewModel.signOut()
                    }
                }

                Section {
                    Button {
                        enableReminders()
                    } label: {
                        HStack {
                            Text("Enable task reminders")
                            Spacer()
                            if isRequestingNotifications { ProgressView() }
                        }
                    }
                    .disabled(isRequestingNotifications)
                    Text("Reminders are scheduled on this device at each task's due date.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if let notificationMessage {
                        Text(notificationMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Push delivery through Firebase Cloud Messaging also requires an APNs key and a trusted server to send messages.")
                }
            }
            .navigationTitle("Settings")
            .alert("Account error", isPresented: authErrorPresented) {
                Button("OK", role: .cancel) { authViewModel.errorMessage = nil }
            } message: {
                Text(authViewModel.errorMessage ?? "")
            }
        }
    }

    private var authErrorPresented: Binding<Bool> {
        Binding(
            get: { authViewModel.errorMessage != nil },
            set: { if !$0 { authViewModel.errorMessage = nil } }
        )
    }

    private func enableReminders() {
        isRequestingNotifications = true
        Task {
            do {
                try await ReminderService.shared.requestPermission()
                notificationMessage = "Notifications enabled."
            } catch {
                notificationMessage = error.localizedDescription
            }
            isRequestingNotifications = false
        }
    }
}
