import FirebaseAuth
import Foundation

protocol AuthServicing {
    var currentUserID: String? { get }
    var currentEmail: String? { get }
    func signIn(email: String, password: String) async throws -> String
    func createAccount(email: String, password: String) async throws -> String
    func sendPasswordReset(to email: String) async throws
    func signOut() throws
}

final class AuthService: AuthServicing {
    var currentUserID: String? { Auth.auth().currentUser?.uid }
    var currentEmail: String? { Auth.auth().currentUser?.email }

    func signIn(email: String, password: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let userID = result?.user.uid {
                    continuation.resume(returning: userID)
                } else {
                    continuation.resume(throwing: AuthServiceError.missingUser)
                }
            }
        }
    }

    
    func createAccount(email: String, password: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let userID = result?.user.uid {
                    continuation.resume(returning: userID)
                } else {
                    continuation.resume(throwing: AuthServiceError.missingUser)
                }
            }
        }
    }

    func sendPasswordReset(to email: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
}

enum AuthServiceError: LocalizedError {
    case missingUser

    var errorDescription: String? {
        "Authentication completed without returning a user account."
    }
}
