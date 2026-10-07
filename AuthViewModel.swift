import Foundation
import Combine
import Firebase
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmation = ""
    @Published var isCreatingAccount = false
    @Published private(set) var userID: String?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var informationMessage: String?
    
    private let service: AuthServicing
    
    init(service: AuthServicing = AuthService()) {
        self.service = service
        userID = service.currentUserID
        email = service.currentEmail ?? ""
    }
    
        func authenticate() async {
            clearMessages()
            let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            guard Self.isValidEmail(normalizedEmail) else {
                errorMessage = "Enter a valid email address."
                return
            }
            guard password.count >= 6 else {
                errorMessage = "Password must be at least 6 characters."
                return
            }
            if isCreatingAccount, password != confirmation {
                errorMessage = "Passwords do not match."
                return
            }
    
            isLoading = true
            defer { isLoading = false }
            do {
                if isCreatingAccount {
                    userID = try await service.createAccount(email: normalizedEmail, password: password)
                } else {
                    userID = try await service.signIn(email: normalizedEmail, password: password)
                }
            } catch {
                errorMessage = Self.userFacingMessage(for: error)
            }
        }
    
    func resetPassword() async {
        clearMessages()
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isValidEmail(normalizedEmail) else {
            errorMessage = "Enter a valid email address first."
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        do {
            try await service.sendPasswordReset(to: normalizedEmail)
            informationMessage = "Password reset email sent."
        } catch {
            
            print("❌ AUTHENTICATION FAILED")
            print("❌ Error:", error)
            print("❌ Localized:", error.localizedDescription)
            
            let nsError = error as NSError
            print("❌ Domain:", nsError.domain)
            print("❌ Code:", nsError.code)
            print("❌ UserInfo:", nsError.userInfo)
            errorMessage = Self.userFacingMessage(for: error)
            
            
        }
    }
    
    func signOut() {
        do {
            try service.signOut()
            userID = nil
            email = ""
            password = ""
            confirmation = ""
        } catch {
            errorMessage = Self.userFacingMessage(for: error)
        }
    }
    
    static func isValidEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".")
    }
    
    private func clearMessages() {
        errorMessage = nil
        informationMessage = nil
    }
    
    private static func userFacingMessage(for error: Error) -> String {
        let message = (error as NSError).localizedDescription
        return message.isEmpty ? "Something went wrong. Please try again." : message
    }
    
   
}
