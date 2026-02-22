import SwiftUI
import GoogleMobileAds

// MARK: - BannerAdView

/// SwiftUI wrapper for Google AdMob banner ads
struct BannerAdView: UIViewRepresentable {
    @ObservedObject var adManager = AdManager.shared

    // Standard banner size (320x50)
    private let bannerHeight: CGFloat = 50

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear

        guard let bannerView = adManager.createBannerAd() else {
            print("[BannerAdView] Ads are disabled, returning empty view")
            return containerView
        }

        containerView.addSubview(bannerView)

        // Center the banner horizontally
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            bannerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            bannerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Find the banner view
        guard let bannerView = uiView.subviews.first as? BannerView else {
            return
        }

        // Load ad with root view controller
        if let rootViewController = uiView.window?.rootViewController {
            adManager.loadBannerAd(bannerView, rootViewController: rootViewController)
        }
    }

    /// Helper to create a fixed-height view for the banner
    static func fixedHeight() -> CGFloat {
        return 50
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()

        Text("Banner Ad Preview")
            .font(.headline)

        BannerAdView()
            .frame(height: BannerAdView.fixedHeight())
            .background(Color.gray.opacity(0.2))

        Spacer()
    }
    .background(Color.feltGreen)
}
