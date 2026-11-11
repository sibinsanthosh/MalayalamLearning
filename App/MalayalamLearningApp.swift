import SwiftUI
import GoogleMobileAds

// MARK: - App Delegate for orientation locking
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        // Lock iPad to landscape; allow all orientations on iPhone
        if UIDevice.current.userInterfaceIdiom == .pad {
            return [.landscapeLeft, .landscapeRight]
        }
        return .portrait
    }
}

@main
struct MalayalamLearningApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = MainViewModel()
    
    init() {
        // This is a children's app: request only child-directed, general-audience ads
        // (COPPA / Google Families policy) and treat users as under the age of consent.
        let config = MobileAds.shared.requestConfiguration
        config.tagForChildDirectedTreatment = true
        config.tagForUnderAgeOfConsent = true
        config.maxAdContentRating = .general
        MobileAds.shared.start(completionHandler: nil)
    }

    private var bannerHeight: CGFloat { UIDevice.current.userInterfaceIdiom == .pad ? 90 : 50 }

    var body: some Scene {
        WindowGroup {
            // The banner gets its own strip below the app so it never covers buttons or content.
            VStack(spacing: 0) {
                HomeScreen(viewModel: viewModel)
                BannerAdView(adUnitID: "ca-app-pub-2521590777237351/5073128198")
                    .frame(height: bannerHeight)
                    .frame(maxWidth: .infinity)
            }
            .background(DS.surface.ignoresSafeArea())
            .ignoresSafeArea(.keyboard)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
    }
}

// Preview Provider
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen(viewModel: MainViewModel())
    }
}
