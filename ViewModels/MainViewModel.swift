import Foundation
import AVFoundation

class MainViewModel: ObservableObject {

    @Published var vowels: [Letter] = []
    @Published var consonants: [Letter] = []
    @Published var stories: [Story] = []

    init() {
        configureAudioSession()
        loadData()
    }

    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func loadData() {
        vowels = DataRepository.shared.vowels
        consonants = DataRepository.shared.consonants
        stories = DataRepository.shared.stories
    }

    /// Adds points to the active child's profile.
    func addPoints(_ points: Int) {
        ProgressStore.shared.addPoints(points)
    }

    /// Plays a bundled sound (mp3/m4a, in the bundle root or Raw/), respecting the sound setting.
    func playSound(_ soundName: String) {
        Speaker.shared.playFile(soundName)
    }
}
