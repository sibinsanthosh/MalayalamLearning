import Foundation
import AVFoundation

class MainViewModel: ObservableObject {
    
    @Published var progress: Progress = Progress()
    @Published var vowels: [Letter] = []
    @Published var consonants: [Letter] = []
    @Published var stories: [Story] = []
    
    var audioPlayer: AVAudioPlayer?
    
    init() {
        configureAudioSession()
        loadData()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            print("Audio session configured successfully")
        } catch {
            print("Failed to set audio session category: \(error.localizedDescription)")
        }
    }
    
    func loadData() {
        self.vowels = DataRepository.shared.vowels
        self.consonants = DataRepository.shared.consonants
        self.stories = DataRepository.shared.stories
    }
    
    func addPoints(_ points: Int) {
        progress.points += points
    }
    
    func playSound(_ soundName: String) {
        print("Attempting to play sound: \(soundName)")
        
        let extensions = ["mp3", "m4a"]
        let subdirectories = [nil, "Raw"]
        var url: URL? = nil
        var detectedExtension: String? = nil
        
        searchLoop: for subdirectory in subdirectories {
            for ext in extensions {
                if let foundUrl = Bundle.main.url(forResource: soundName, withExtension: ext, subdirectory: subdirectory) {
                    url = foundUrl
                    detectedExtension = ext
                    print("Found sound at: \(foundUrl.path)")
                    break searchLoop
                }
            }
        }
        
        guard let finalUrl = url, let ext = detectedExtension else {
            print("CRITICAL: Sound file not found: \(soundName)")
            return
        }
        
        do {
            // We use fileTypeHint because some files (like .mp3) are actually .m4a/AAC.
            // If the extension is mp3, we first try as mp3, then as m4a as a fallback.
            let hint = ext == "m4a" ? AVFileType.m4a : AVFileType.mp3
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: finalUrl, fileTypeHint: hint.rawValue)
            } catch {
                print("Primary hint \(hint.rawValue) failed for \(finalUrl.lastPathComponent), trying m4a fallback...")
                // Fallback for cases where .mp3 is actually .m4a
                audioPlayer = try AVAudioPlayer(contentsOf: finalUrl, fileTypeHint: AVFileType.m4a.rawValue)
            }
            
            audioPlayer?.prepareToPlay()
            let started = audioPlayer?.play() ?? false
            print("Audio playback started: \(started)")
        } catch {
            print("Error initializing audio player for \(soundName): \(error.localizedDescription)")
        }
    }
}
