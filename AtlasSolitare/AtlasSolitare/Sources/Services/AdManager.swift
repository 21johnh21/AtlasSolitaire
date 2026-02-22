import Foundation
import GoogleMobileAds
import AppTrackingTransparency
import Combine

// MARK: - AdManager

/// Manages Google AdMob integration for the game.
/// Handles banner ads, interstitial ads, and ensures test ads are used in development.
class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()

    // MARK: - Published Properties

    @Published var areAdsEnabled: Bool = true
    @Published var bannerAdLoaded: Bool = false
    @Published var interstitialAdLoaded: Bool = false

    // MARK: - Ad Configuration

    /// Set this to false in production builds to disable all ads
    /// Can be toggled via settings or for premium users
    var globalAdsEnabled: Bool {
        get { areAdsEnabled }
        set { areAdsEnabled = newValue }
    }

    /// Number of games played before showing an interstitial ad
    private let interstitialFrequency = 20

    /// Counter for games played since last interstitial
    private var gamesPlayedSinceLastAd = 0

    // MARK: - Ad Unit IDs

    /// AdMob Ad Unit IDs
    /// IMPORTANT: Replace these with your actual AdMob IDs before release
    private enum AdUnitID {
        // Test IDs - used in development
        static let testBanner = "ca-app-pub-3940256099942544/2934735716"
        static let testInterstitial = "ca-app-pub-3940256099942544/4411468910"

        // Production IDs - replace these with your real AdMob IDs
        static let productionBanner = "ca-app-pub-1453954241423045~4496056156"
        static let productionInterstitial = "ca-app-pub-1453954241423045~4496056156"
    }

    /// Returns the appropriate ad unit ID based on build configuration
    private var bannerAdUnitID: String {
        #if DEBUG
        return AdUnitID.testBanner
        #else
        return AdUnitID.productionBanner
        #endif
    }

    private var interstitialAdUnitID: String {
        #if DEBUG
        return AdUnitID.testInterstitial
        #else
        return AdUnitID.productionInterstitial
        #endif
    }

    // MARK: - Ad Instances

    private var interstitialAd: InterstitialAd?

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    // MARK: - Setup

    /// Initialize the Mobile Ads SDK
    /// Call this once at app launch
    func initialize() {
        print("[AdManager] Initializing Google Mobile Ads SDK")

        #if DEBUG
        print("[AdManager] ⚠️ DEVELOPMENT MODE - Using test ads only")
        #else
        print("[AdManager] 🚀 PRODUCTION MODE - Using real ads")
        #endif

        // Start the Google Mobile Ads SDK
        Task {
            await MobileAds.shared.start()
            print("[AdManager] ✅ Mobile Ads SDK initialized")

            // Set request configuration for contextual targeting
            configureRequestConfiguration()

            // Preload first interstitial
            loadInterstitialAd()
        }
    }

    /// Configure ad request settings for better targeting and privacy
    private func configureRequestConfiguration() {
        let requestConfiguration = MobileAds.shared.requestConfiguration

        // Set content URL hints for contextual targeting
        // This helps Google show relevant ads based on content, not tracking
        requestConfiguration.publisherPrivacyPersonalizationState = .disabled

        // Add test device IDs in development
        #if DEBUG
        requestConfiguration.testDeviceIdentifiers = [
            "Simulator",  // Use string literal instead of GADSimulatorID
            // Add your physical device IDs here for testing:
            // "YOUR-DEVICE-ID-HERE"
        ]
        #endif

        print("[AdManager] Request configuration updated for privacy-first ads")
    }

    // MARK: - Banner Ads

    /// Create a banner ad view
    /// Call this from your SwiftUI view to get a banner ad
    func createBannerAd() -> BannerView? {
        guard areAdsEnabled else {
            print("[AdManager] Ads are disabled")
            return nil
        }

        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = bannerAdUnitID

        // The root view controller will be set when presenting
        bannerView.delegate = self

        return bannerView
    }

    /// Load banner ad with contextual targeting
    func loadBannerAd(_ bannerView: BannerView, rootViewController: UIViewController) {
        guard areAdsEnabled else { return }

        let request = createAdRequest()
        bannerView.rootViewController = rootViewController
        bannerView.load(request)

        print("[AdManager] Loading banner ad")
    }

    // MARK: - Interstitial Ads

    /// Preload an interstitial ad
    private func loadInterstitialAd() {
        guard areAdsEnabled else { return }

        let request = createAdRequest()

        Task {
            do {
                let ad = try await InterstitialAd.load(
                    with: interstitialAdUnitID,
                    request: request
                )

                print("[AdManager] ✅ Interstitial ad loaded successfully")
                await MainActor.run {
                    self.interstitialAd = ad
                    self.interstitialAd?.fullScreenContentDelegate = self
                    self.interstitialAdLoaded = true
                }
            } catch {
                print("[AdManager] ❌ Failed to load interstitial ad: \(error.localizedDescription)")
                await MainActor.run {
                    self.interstitialAdLoaded = false
                }
            }
        }
    }

    /// Call this when a game ends to potentially show an interstitial ad
    func onGameEnd() {
        guard areAdsEnabled else { return }

        gamesPlayedSinceLastAd += 1
        print("[AdManager] Games since last ad: \(gamesPlayedSinceLastAd)/\(interstitialFrequency)")

        if gamesPlayedSinceLastAd >= interstitialFrequency {
            showInterstitialAd()
        }
    }

    /// Show the interstitial ad if loaded
    private func showInterstitialAd() {
        guard let interstitialAd = interstitialAd else {
            print("[AdManager] ⚠️ Interstitial ad not ready yet")
            // Try to load it for next time
            loadInterstitialAd()
            return
        }

        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            print("[AdManager] ❌ Cannot show ad - no root view controller")
            return
        }

        print("[AdManager] 📺 Showing interstitial ad")
        interstitialAd.present(from: rootViewController)

        // Reset counter
        gamesPlayedSinceLastAd = 0
    }

    // MARK: - Ad Request Creation

    /// Create an ad request with contextual targeting hints
    /// This helps serve relevant ads based on app content without tracking
    private func createAdRequest() -> Request {
        let request = Request()

        // Add contextual signals (content-based, not user-based)
        // This tells Google the app is about geography/education/games
        let extras = Extras()
        extras.additionalParameters = [
            "content_url": "https://atlassolitaire.com/geography-card-game",
            "category": "games_educational",
            "topics": "geography,education,puzzle,card-games"
        ]
        request.register(extras)

        return request
    }
}

// MARK: - BannerViewDelegate

extension AdManager: BannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        print("[AdManager] ✅ Banner ad loaded successfully")
        bannerAdLoaded = true
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        print("[AdManager] ❌ Banner ad failed to load: \(error.localizedDescription)")
        bannerAdLoaded = false
    }

    func bannerViewDidRecordClick(_ bannerView: BannerView) {
        print("[AdManager] 👆 Banner ad clicked")
    }
}

// MARK: - FullScreenContentDelegate

extension AdManager: FullScreenContentDelegate {
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("[AdManager] ✅ Interstitial ad will present")
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("[AdManager] ❌ Interstitial ad failed to present: \(error.localizedDescription)")
        // Try to load a new one
        loadInterstitialAd()
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("[AdManager] ✅ Interstitial ad dismissed")
        // Preload the next interstitial
        loadInterstitialAd()
    }
}
