import Foundation
import SwiftUI
import Combine

class MusicService: ObservableObject {
    // Sample data - in a real app, this would come from a backend service
    
    @Published var isLoading = false
    @Published var suggestions: [(title: String, artist: String, difficulty: String)] = []
    @Published var historyItems: [String] = []
    
    private let sampleSuggestions = [
        (title: "Blackbird", artist: "The Beatles", difficulty: "Intermediate"),
        (title: "Dust in the Wind", artist: "Kansas", difficulty: "Intermediate"),
        (title: "Tears in Heaven", artist: "Eric Clapton", difficulty: "Advanced"),
        (title: "Time of Your Life", artist: "Green Day", difficulty: "Beginner"),
        (title: "Layla", artist: "Eric Clapton", difficulty: "Advanced")
    ]
    
    private let sampleHistoryItems = [
        "Stairway to Heaven - Led Zeppelin",
        "Hotel California - Eagles",
        "Sweet Child O' Mine - Guns N' Roses",
        "Wonderwall - Oasis",
        "Nothing Else Matters - Metallica"
    ]
    
    init() {
        loadInitialData()
    }
    
    private func loadInitialData() {
        // Load data immediately for demo purposes
        self.suggestions = sampleSuggestions
        self.historyItems = sampleHistoryItems
    }
    
    func refreshSuggestions(completion: @escaping () -> Void = {}) {
        isLoading = true
        // Add artificial delay to simulate network
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.suggestions = self.sampleSuggestions.shuffled()
            self.isLoading = false
            completion()
        }
    }
    
    func refreshHistory(completion: @escaping () -> Void = {}) {
        isLoading = true
        // Add artificial delay to simulate network
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.historyItems = self.sampleHistoryItems
            self.isLoading = false
            completion()
        }
    }
    
    func searchSongs(query: String, completion: @escaping ([String]) -> Void) {
        // This would search a backend API for songs matching the query
        let filteredResults = self.sampleSuggestions
            .filter { $0.title.lowercased().contains(query.lowercased()) || 
                     $0.artist.lowercased().contains(query.lowercased()) }
            .map { "\($0.title) - \($0.artist)" }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(filteredResults)
        }
    }
}