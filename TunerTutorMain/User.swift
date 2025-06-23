import Foundation

struct User: Identifiable, Equatable {
    var id: String
    var username: String
    var email: String
    var skillLevel: String = "Intermediate"
    var preferredGenres: [String] = ["Rock", "Blues", "Jazz"]
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}