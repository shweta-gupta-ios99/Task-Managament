import FirebaseFirestore
import Foundation
import Combine
import UserNotifications

enum DueDateFilter: String, CaseIterable, Identifiable, Hashable {
    case any = "Any date"
    case overdue = "Overdue"
    case today = "Due today"
    case upcoming = "Upcoming"

    var id: String { rawValue }
}

enum TaskValidationError: LocalizedError, Equatable {
    case emptyTitle
    case dueDateInPast

    var errorDescription: String? {
        switch self {
        case .emptyTitle: return "A task title is required."
        case .dueDateInPast: return "The due date cannot be in the past."
        }
    }
}

@MainActor
final class TaskListViewModel: ObservableObject {
    @Published private(set) var tasks: [TaskItem]
    @Published var searchText = ""
    @Published var statusFilter: TaskFilter = .all
    @Published var dueDateFilter: DueDateFilter = .any
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var reminderMessage: String?

    private let userID: String?
    private let service: TaskServicing
    private var listener: ListenerRegistration?

    init(
        userID: String? = nil,
        service: TaskServicing = TaskService(),
        initialTasks: [TaskItem] = []
    ) {
        self.userID = userID
        self.service = service
        tasks = initialTasks
        if let userID {
            observeTasks(for: userID)
        }
    }

    deinit {
        listener?.remove()
    }

    var visibleTasks: [TaskItem] {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return tasks
            .filter(statusFilter.includes)
            .filter { task in
                guard !normalizedSearch.isEmpty else { return true }
                return task.title.localizedCaseInsensitiveContains(normalizedSearch)
                    || task.description.localizedCaseInsensitiveContains(normalizedSearch)
            }
            .filter(matchesDueDate)
            .sorted { $0.dueDate < $1.dueDate }
    }

    var totalCount: Int { tasks.count }
    var completedCount: Int { tasks.filter { $0.status == .completed }.count }
    var pendingCount: Int { totalCount - completedCount }

    func save(title: String, description: String, dueDate: Date, existingTask: TaskItem? = nil) async {
        errorMessage = nil
        do {
            try Self.validate(title: title, dueDate: dueDate)
            guard let userID else {
                throw TaskListError.notSignedIn
            }
            let task = TaskItem(
                id: existingTask?.id ?? UUID().uuidString,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                dueDate: dueDate,
                status: existingTask?.status ?? .pending,
                createdAt: existingTask?.createdAt ?? .now,
                updatedAt: .now
            )
            try await service.save(task, userID: userID)
            do {
                try await ReminderService.shared.scheduleReminder(for: task)
                reminderMessage = nil
            } catch {
                reminderMessage = "Task saved, but the reminder could not be scheduled: \(error.localizedDescription)"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleCompletion(for task: TaskItem) async {
        guard let userID else {
            errorMessage = TaskListError.notSignedIn.localizedDescription
            return
        }
        var updatedTask = task
        updatedTask.status = task.status == .completed ? .pending : .completed
        updatedTask.updatedAt = .now
        do {
            try await service.save(updatedTask, userID: userID)
            do {
                try await ReminderService.shared.scheduleReminder(for: updatedTask)
                reminderMessage = nil
            } catch {
                reminderMessage = "Task updated, but the reminder could not be updated: \(error.localizedDescription)"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ task: TaskItem) async {
        guard let userID else {
            errorMessage = TaskListError.notSignedIn.localizedDescription
            return
        }
        do {
            try await service.delete(taskID: task.id, userID: userID)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    static func validate(title: String, dueDate: Date, now: Date = .now) throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TaskValidationError.emptyTitle
        }
        guard dueDate >= now else {
            throw TaskValidationError.dueDateInPast
        }
    }

    private func observeTasks(for userID: String) {
        isLoading = true
        listener = service.observeTasks(userID: userID) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let tasks):
                    self.tasks = tasks
                    self.errorMessage = nil
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func matchesDueDate(_ task: TaskItem) -> Bool {
        let calendar = Calendar.current
        switch dueDateFilter {
        case .any:
            return true
        case .overdue:
            return task.status == .pending && task.dueDate < calendar.startOfDay(for: .now)
        case .today:
            return calendar.isDateInToday(task.dueDate)
        case .upcoming:
            return task.dueDate >= calendar.startOfDay(for: .now)
                && !calendar.isDateInToday(task.dueDate)
        }
    }
}

enum TaskListError: LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        return "Sign in to manage tasks."
    }
}
