import SwiftUI

struct SuggestionsView: View {
    @EnvironmentObject var musicService: MusicService
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(0..<musicService.suggestions.count, id: \.self) { index in
                    let suggestion = musicService.suggestions[index]
                    VStack(alignment: .leading) {
                        Text(suggestion.title)
                            .font(.headline)
                        
                        HStack {
                            Text(suggestion.artist)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text(suggestion.difficulty)
                                .font(.caption)
                                .padding(5)
                                .background(difficultyColor(for: suggestion.difficulty))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Song Suggestions")
            .toolbar {
                Button(action: {
                    isRefreshing = true
                    musicService.refreshSuggestions {
                        isRefreshing = false
                    }
                }) {
                    if isRefreshing {
                        ProgressView()
                    } else {
                        Image(systemName: "shuffle")
                    }
                }
            }
            .overlay(
                Group {
                    if musicService.suggestions.isEmpty {
                        VStack {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                                .padding()
                            
                            Text("No suggestions")
                                .font(.headline)
                            
                            Text("Your personalized suggestions will appear here")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                    }
                }
            )
        }
    }
    
    // Helper function to return appropriate color for difficulty level
    private func difficultyColor(for difficulty: String) -> Color {
        switch difficulty {
        case "Beginner":
            return .green
        case "Intermediate":
            return .blue
        case "Advanced":
            return .red
        default:
            return .gray
        }
    }
}

#Preview {
    SuggestionsView()
        .environmentObject(MusicService())
}