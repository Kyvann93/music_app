import AVFoundation
import ShazamKit
import Combine

class MusicRecognitionService: NSObject, SHSessionDelegate {
    @Published var matchedSong: SHMatchedMediaItem?
    @Published var fetchedTabs: [Tab] = []
    @Published var error: Error?

    private var session: SHSession?
    private let audioEngine = AVAudioEngine()
    private let tablatureService = TablatureService()

    func startListening() {
        session = SHSession()
        session?.delegate = self

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, when) in
            self?.session?.matchStreamingBuffer(buffer, at: nil)
        }

        do {
            try audioEngine.start()
        } catch {
            self.error = error
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }

    func session(_ session: SHSession, didFind match: SHMatch) {
        if let firstItem = match.mediaItems.first {
            DispatchQueue.main.async {
                self.matchedSong = firstItem
            }

            if let title = firstItem.title, let artist = firstItem.artist {
                tablatureService.fetchTabs(for: title, artist: artist) { [weak self] result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let tabs):
                            self?.fetchedTabs = tabs
                        case .failure(let error):
                            self?.error = error
                        }
                    }
                }
            }
        }
    }

    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        self.error = error
    }
}