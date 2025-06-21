import SwiftUI

struct TabsView: View {
    let tabs: [Tab]
    @State private var selectedTabType = "player"

    var body: some View {
        VStack {
            if tabs.isEmpty {
                Text("No tabs found for this song.")
            } else {
                Picker("Select Tab Type", selection: $selectedTabType) {
                    Text("Guitar").tag("player")
                    Text("Piano").tag("text_bass_tab")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                List(tabs.filter { $0.tabTypes.contains(selectedTabType) }) { tab in
                    VStack(alignment: .leading) {
                        Text(tab.title).font(.headline)
                        Text(tab.artist.name).font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle("Tabs")
    }
}