import AVFoundation

@MainActor
final class SoundPlayer {
    static let shared = SoundPlayer()

    private var players: [String: AVAudioPlayer] = [:]
    private var sessionActive = false
    private(set) var isMuted = false

    func play(_ name: String, ext: String = "wav", volume: Float = 1.0) {
        if isMuted { return }
        ensureAudioSession()
        let key = "\(name).\(ext)"

        if let player = players[key] {
            player.volume = volume
            if !player.isPlaying {
                player.play()
            } else {
                player.currentTime = 0
            }
            return
        }

        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            players[key] = player
            player.play()
        } catch {
            // Ignore audio errors to keep gameplay smooth.
        }
    }

    func playLoop(_ name: String, ext: String = "mp3", volume: Float = 1.0) {
        if isMuted { return }
        ensureAudioSession()
        let key = "\(name).\(ext)"

        if let player = players[key] {
            player.numberOfLoops = -1
            player.volume = volume
            if !player.isPlaying {
                player.play()
            }
            return
        }

        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = volume
            player.prepareToPlay()
            players[key] = player
            player.play()
        } catch {
            // Ignore audio errors to keep gameplay smooth.
        }
    }

    func stop(_ name: String, ext: String = "mp3") {
        let key = "\(name).\(ext)"
        guard let player = players[key] else { return }
        player.stop()
        player.currentTime = 0
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
        if muted {
            stopAll()
        }
    }

    func duck(_ name: String, ext: String = "mp3", to volume: Float, for seconds: Double) {
        let key = "\(name).\(ext)"
        guard let player = players[key] else { return }
        let original = player.volume
        player.volume = volume
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            guard let self = self else { return }
            guard let player = self.players[key], !self.isMuted else { return }
            player.volume = original
        }
    }

    private func stopAll() {
        for player in players.values {
            player.stop()
            player.currentTime = 0
        }
    }

    private func ensureAudioSession() {
        guard !sessionActive else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)
            sessionActive = true
        } catch {
            // Ignore audio session errors to keep gameplay smooth.
        }
    }
}
