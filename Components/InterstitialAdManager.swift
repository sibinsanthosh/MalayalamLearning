import Foundation
import GoogleMobileAds
import UIKit

class InterstitialAdManager: NSObject, FullScreenContentDelegate, ObservableObject {
    static let shared = InterstitialAdManager()
    
    private var interstitial: InterstitialAd?
    private var clickCount = 0
    private var onAdDismissed: (() -> Void)?
    
    private let adUnitID = "ca-app-pub-2521590777237351/8157393475"
    
    private override init() {
        super.init()
        loadAd()
    }
    
    func loadAd() {
        let request = Request()
        InterstitialAd.load(with: adUnitID,
                               request: request,
                               completionHandler: { [weak self] ad, error in
                                if let error = error {
                                    print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                                    return
                                }
                                self?.interstitial = ad
                                self?.interstitial?.fullScreenContentDelegate = self
                               })
    }
    
    func showAdIfAppropriate(completion: @escaping () -> Void) {
        clickCount += 1
        
        // Every 3rd click, show the ad
        if clickCount % 3 == 0 {
            if let interstitial = interstitial,
               let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = scene.windows.first?.rootViewController {
                
                self.onAdDismissed = completion
                interstitial.present(from: rootVC)
                
            } else {
                print("Ad wasn't ready or couldn't find root VC")
                completion()
                loadAd() // Try to reload if it failed
            }
        } else {
            completion()
        }
    }
    
    // MARK: - GADFullScreenContentDelegate
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        onAdDismissed?()
        onAdDismissed = nil
        loadAd() // Load the next ad
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad failed to present: \(error.localizedDescription)")
        onAdDismissed?()
        onAdDismissed = nil
        loadAd()
    }
}
