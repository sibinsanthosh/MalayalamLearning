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
        MobileAds.shared.start(completionHandler: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 0) {
                HomeScreen(viewModel: viewModel)
                
                BannerAdView(adUnitID: "ca-app-pub-2521590777237351/5073128198")
                    .frame(height: 50)
            }
            .ignoresSafeArea(.keyboard)
        }
    }
}

// Preview Provider
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen(viewModel: MainViewModel())
    }
}
