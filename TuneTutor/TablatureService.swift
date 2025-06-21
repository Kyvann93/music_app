import Foundation

struct Tab: Codable, Identifiable {
    let id: Int
    let title: String
    let artist: Artist
    let tabTypes: [String]

    struct Artist: Codable {
        let name: String
    }
}

class TablatureService {
    func fetchTabs(for song: String, artist: String, completion: @escaping (Result<[Tab], Error>) -> Void) {
        let pattern = "\(artist) \(song)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.songsterr.com/a/ra/songs.json?pattern=\(pattern)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "TablatureService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "TablatureService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let tabs = try JSONDecoder().decode([Tab].self, from: data)
                completion(.success(tabs))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}