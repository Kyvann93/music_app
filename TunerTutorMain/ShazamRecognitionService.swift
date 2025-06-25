import ShazamKit
import AVFoundation

// Delegate protocol to communicate results back
protocol ShazamRecognitionServiceDelegate: AnyObject {
    func didFindMatch(mediaItem: SHMatchedMediaItem)
    func didNotFindMatch(error: Error?) // Error might be nil if simply no match
    func didFailWithError(serviceError: Error) // For service-level errors (mic, audio engine)
    func didStartListening()
}

// Define a specific error enum for the service
enum ShazamRecognitionError: Error, LocalizedError {
    case microphoneAccessDenied
    case audioEngineStartError(Error)
    case signatureGenerationError(Error)
    case matchAttemptError(Error) // Error during session.match(signature)
    case genericError(String)

    var errorDescription: String? {
        switch self {
        case .microphoneAccessDenied:
            return "Microphone access is required to identify songs. Please enable it in Settings."
        case .audioEngineStartError(let underlyingError):
            return "Could not start audio engine: \(underlyingError.localizedDescription)"
        case .signatureGenerationError(let underlyingError):
            return "Could not generate audio signature: \(underlyingError.localizedDescription)"
        case .matchAttemptError(let underlyingError):
            return "Could not attempt song match: \(underlyingError.localizedDescription)"
        case .genericError(let message):
            return message
        }
    }
}


class ShazamRecognitionService: NSObject, SHSessionDelegate {

    weak var delegate: ShazamRecognitionServiceDelegate?

    private var shazamSession: SHSession?
    private var audioEngine = AVAudioEngine()
    private var signatureGenerator: SHSignatureGenerator?

    public static let microphoneAccessDeniedErrorDomain = "ShazamRecognitionService"
    public static let microphoneAccessDeniedErrorCode = 1001

    // MARK: - Public Methods

    public func startRecognition() {
        requestMicrophoneAccess { [weak self] granted in
            guard let self = self else { return }
            if granted {
                self.prepareAndStartAudioEngineAndSession()
            } else {
                DispatchQueue.main.async {
                    let micError = ShazamRecognitionError.microphoneAccessDenied
                    self.delegate?.didFailWithError(serviceError: micError)
                }
            }
        }
    }

    public func stopRecognition() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        shazamSession = nil
        signatureGenerator = nil
    }

    // MARK: - Private Helper Methods

    private func requestMicrophoneAccess(completion: @escaping (Bool) -> Void) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }

    private func prepareAndStartAudioEngineAndSession() {
        if audioEngine.isRunning {
            stopRecognition()
        }

        shazamSession = SHSession()
        signatureGenerator = SHSignatureGenerator()
        shazamSession?.delegate = self

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 2048, format: recordingFormat) { [weak self] (buffer, audioTime) in
            guard let self = self, let session = self.shazamSession, let generator = self.signatureGenerator else { return }

            do {
                try generator.append(buffer, at: audioTime)
                // Attempt to match only if generator has enough data
                // This is a conceptual check; SHSignatureGenerator throws if not enough data.
                session.match(generator.signature())
            } catch let error as SHSignatureGenerator.Error where error.code == .notEnoughData {
                // Normal case: not enough data yet. Do nothing.
            } catch let error as SHSignatureGenerator.Error {
                 DispatchQueue.main.async {
                    self.delegate?.didFailWithError(serviceError: ShazamRecognitionError.signatureGenerationError(error))
                }
            }
             catch {
                DispatchQueue.main.async {
                    self.delegate?.didFailWithError(serviceError: ShazamRecognitionError.matchAttemptError(error))
                }
            }
        }

        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.delegate?.didStartListening()
            }
        } catch {
            DispatchQueue.main.async {
                self.delegate?.didFailWithError(serviceError: ShazamRecognitionError.audioEngineStartError(error))
                self.stopRecognition()
            }
        }
    }

    // MARK: - SHSessionDelegate Methods

    func session(_ session: SHSession, didFind match: SHMatch) {
        if let firstMatch = match.mediaItems.first {
            DispatchQueue.main.async {
                self.delegate?.didFindMatch(mediaItem: firstMatch)
            }
        } else {
            DispatchQueue.main.async {
                 self.delegate?.didNotFindMatch(error: ShazamRecognitionError.genericError("Match object was empty."))
            }
        }
    }

    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        DispatchQueue.main.async {
            // If error is nil, it's a genuine "no match". If non-nil, it's a matching process error.
            self.delegate?.didNotFindMatch(error: error)
        }
    }
}

// Remember to add the `NSMicrophoneUsageDescription` key to your app's Info.plist:
// <key>NSMicrophoneUsageDescription</key>
// <string>This app needs to access your microphone to identify songs playing around you.</string>
