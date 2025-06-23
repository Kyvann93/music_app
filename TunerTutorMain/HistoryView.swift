import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var musicService: MusicService
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(musicService.historyItems, id: \.self) { item in
                    VStack(alignment: .leading) {
                        Text(item)
                            .font(.headline)
                        
                        Text("Last viewed: Today")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Your History")
            .toolbar {
                Button(action: {
                    isRefreshing = true
                    musicService.refreshHistory {
                        isRefreshing = false
                    }
                }) {
                    if isRefreshing {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .overlay(
                Group {
                    if musicService.historyItems.isEmpty {
                        VStack {
                            Image(systemName: "music.note")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                                .padding()
                            
                            Text("No history yet")
                                .font(.headline)
                            
                            Text("Your practice history will appear here")
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
}

#Preview {
    HistoryView()
        .environmentObject(MusicService())
}