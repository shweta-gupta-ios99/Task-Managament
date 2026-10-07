import FirebaseFirestore
import Foundation

protocol TaskServicing {
    func observeTasks(userID: String, onChange: @escaping (Result<[TaskItem], Error>) -> Void) -> ListenerRegistration
    func save(_ task: TaskItem, userID: String) async throws
    func delete(taskID: String, userID: String) async throws
}

final class TaskService: TaskServicing {
    private let database: Firestore

    init(database: Firestore = .firestore()) {
        self.database = database
    }

    func observeTasks(
        userID: String,
        onChange: @escaping (Result<[TaskItem], Error>) -> Void
    ) -> ListenerRegistration {
        collection(for: userID)
            .order(by: "dueDate")
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }
                guard let snapshot else {
                    onChange(.failure(TaskServiceError.missingSnapshot))
                    return
                }

                do {
                    let tasks = try snapshot.documents.map { document in
                        guard let task = TaskItem(document: document) else {
                            throw TaskServiceError.invalidTask(documentID: document.documentID)
                        }
                        return task
                    }
                    onChange(.success(tasks))
                } catch {
                    onChange(.failure(error))
                }
            }
    }

    func save(_ task: TaskItem, userID: String) async throws {
        var updated = task
        updated.updatedAt = .now

        let document = collection(for: userID).document(task.id)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            document.setData(updated.firestoreData) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func delete(taskID: String, userID: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            collection(for: userID).document(taskID).delete { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    
    private func collection(for userID: String) -> CollectionReference {
        database.collection("users").document(userID).collection("tasks")
    }
}

enum TaskServiceError: LocalizedError {
    case missingSnapshot
    case invalidTask(documentID: String)

    var errorDescription: String? {
        switch self {
        case .missingSnapshot:
            return "The task update could not be read. Please try again."
        case .invalidTask(let documentID):
            return "Task \(documentID) contains invalid data and could not be displayed."
        }
    }
}
