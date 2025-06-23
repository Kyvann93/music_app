import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User? = nil
    
    // For demo purposes, init with false, but could be
    // loaded from UserDefaults or keychain in a real app
    init() {
        self.isLoggedIn = false
        self.currentUser = nil
    }
    
    func login(username: String, password: String) -> Bool {
        // Simple authentication logic for demo
        if username.lowercased() == "user" && password == "password" {
            self.isLoggedIn = true
            self.currentUser = User(id: "1", username: username, email: "\(username)@example.com")
            return true
        }
        return false
    }
    
    func logout() {
        self.isLoggedIn = false
        self.currentUser = nil
    }
}