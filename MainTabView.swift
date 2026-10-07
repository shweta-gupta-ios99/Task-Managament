import SwiftUI

struct MainTabView: View {
    let userID: String
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var taskViewModel: TaskListViewModel

    init(userID: String, authViewModel: AuthViewModel) {
        self.userID = userID
        self.authViewModel = authViewModel
        _taskViewModel = StateObject(
            wrappedValue: TaskListViewModel(userID: userID)
        )
    }

    var body: some View {
        TabView {
            TaskListView(viewModel: taskViewModel)
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
            DashboardView(viewModel: taskViewModel)
                .tabItem {
                    Label("Overview", systemImage: "chart.bar")
                }
            SettingsView(authViewModel: authViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(.accentColor)
    }
}
