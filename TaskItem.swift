import Foundation
import FirebaseFirestore
import FirebaseAuth

enum TaskStatus: String, CaseIterable, Identifiable, Codable {
    case pending = "Pending"
    case completed = "Completed"

    var id: String { rawValue }
}

struct TaskItem: Identifiable, Equatable, Codable {
    var id: String
    var title: String
    var description: String
    var dueDate: Date
    var status: TaskStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        description: String = "",
        dueDate: Date,
        status: TaskStatus = .pending,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard
            let title = data["title"] as? String,
            let dueDate = (data["dueDate"] as? Timestamp)?.dateValue(),
            let statusString = data["status"] as? String,
            let status = TaskStatus(rawValue: statusString)
        else {
            return nil
        }

        self.init(
            id: document.documentID,
            title: title,
            description: data["description"] as? String ?? "",
            dueDate: dueDate,
            status: status,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? .now,
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? .now
        )
    }

    var firestoreData: [String: Any] {
        [
            "title": title,
            "description": description,
            "dueDate": Timestamp(date: dueDate),
            "status": status.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
}

enum TaskFilter: String, CaseIterable, Identifiable, Hashable {
    case all = "All"
    case pending = "Pending"
    case completed = "Completed"

    var id: String { rawValue }

    func includes(_ task: TaskItem) -> Bool {
        switch self {
        case .all: return true
        case .pending: return task.status == .pending
        case .completed: return task.status == .completed
        }
    }
}
