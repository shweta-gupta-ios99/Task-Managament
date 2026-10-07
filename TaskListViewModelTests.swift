import FirebaseFirestore
import XCTest
@testable import TaskManagement

@MainActor
final class TaskListViewModelTests: XCTestCase {
    func testMetricsAndSearchAndStatusFiltering() {
        let today = Calendar.current.startOfDay(for: .now).addingTimeInterval(3_600)
        let viewModel = TaskListViewModel(
            service: UnusedTaskService(),
            initialTasks: [
                TaskItem(id: "1", title: "Write proposal", dueDate: today),
                TaskItem(id: "2", title: "Review notes", description: "Proposal feedback", dueDate: today, status: .completed)
            ]
        )

        XCTAssertEqual(viewModel.totalCount, 2)
        XCTAssertEqual(viewModel.completedCount, 1)
        XCTAssertEqual(viewModel.pendingCount, 1)

        viewModel.searchText = "proposal"
        XCTAssertEqual(viewModel.visibleTasks.count, 2)
        viewModel.statusFilter = .pending
        XCTAssertEqual(viewModel.visibleTasks.map(\.id), ["1"])
    }

    func testValidationRejectsBlankTitleAndPastDate() {
        let now = Date(timeIntervalSince1970: 1_000)

        XCTAssertThrowsError(try TaskListViewModel.validate(title: "   ", dueDate: now, now: now)) { error in
            XCTAssertEqual(error as? TaskValidationError, .emptyTitle)
        }
        XCTAssertThrowsError(try TaskListViewModel.validate(title: "Task", dueDate: now.addingTimeInterval(-1), now: now)) { error in
            XCTAssertEqual(error as? TaskValidationError, .dueDateInPast)
        }
        XCTAssertNoThrow(try TaskListViewModel.validate(title: "Task", dueDate: now, now: now))
    }
}

private final class UnusedTaskService: TaskServicing {
    func observeTasks(
        userID: String,
        onChange: @escaping (Result<[TaskItem], Error>) -> Void
    ) -> ListenerRegistration {
        NoopListener()
    }

    func save(_ task: TaskItem, userID: String) async throws {}
    func delete(taskID: String, userID: String) async throws {}
}

private final class NoopListener: ListenerRegistration {
    func remove() {}
}
