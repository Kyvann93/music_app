import Foundation
import SwiftUI
import Combine

class AuthenticationService: ObservableObject {
    // In a real app, this would handle actual authentication
    // with a backend service or authentication provider
    
    @Published var isAuthenticating = false
    @Published var authError: String?
    
    func login(username: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        isAuthenticating = true
        authError = nil
        
        // Simulate network request with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Simple validation
            if username.lowercased() == "user" && password == "password" {
                let user = User(
                    id: "1",
                    username: username,
                    email: "\(username)@example.com"
                )
                self.isAuthenticating = false
                completion(.success(user))
            } else {
                self.authError = "Invalid credentials"
                self.isAuthenticating = false
                completion(.failure(AuthError.invalidCredentials))
            }
        }
    }
    
    func logout() {
        // In a real app, this would invalidate tokens, etc.
        print("User logged out")
    }
    
    enum AuthError: Error, LocalizedError {
        case invalidCredentials
        case networkError
        case serverError
        
        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return "Invalid username or password"
            case .networkError:
                return "Network connection error"
            case .serverError:
                return "Server error"
            }
        }
    }
}