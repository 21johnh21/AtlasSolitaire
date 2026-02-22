# Google AdMob Setup Guide for Atlas Solitaire

## Overview

This guide will help you set up Google AdMob for Atlas Solitaire with:
- ✅ Banner ads at the bottom of the game board
- ✅ Interstitial (full-screen) ads every 20 games
- ✅ Test ads in development (no real ads shown during testing)
- ✅ Easy on/off toggle for ads
- ✅ Privacy-first contextual targeting (no cross-app tracking)

## Step 1: Install Google Mobile Ads SDK

### Using Swift Package Manager (Recommended)

1. Open your Xcode project
2. Go to **File > Add Package Dependencies**
3. Enter the Google Mobile Ads SDK URL:
   ```
   https://github.com/googleads/swift-package-manager-google-mobile-ads.git
   ```
4. Select "Up to Next Major Version" with version `11.0.0`
5. Click "Add Package"
6. Select `GoogleMobileAds` and click "Add Package"

### Using CocoaPods (Alternative)

If you prefer CocoaPods, add to your `Podfile`:
```ruby
pod 'Google-Mobile-Ads-SDK'
```

Then run:
```bash
pod install
```

## Step 2: Create AdMob Account & Get Ad Unit IDs

1. Go to [https://admob.google.com](https://admob.google.com)
2. Sign in with your Google account
3. Click "Apps" → "Add App"
4. Select "iOS" platform
5. Enter app name: "Atlas Solitaire"
6. Once created, click "Ad units" → "Add Ad Unit"

### Create Banner Ad Unit
7. Select "Banner"
8. Name it "Atlas Solitaire - Banner"
9. Click "Create Ad Unit"
10. **Copy the Ad Unit ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY`)

### Create Interstitial Ad Unit
11. Click "Add Ad Unit" again
12. Select "Interstitial"
13. Name it "Atlas Solitaire - Interstitial"
14. Click "Create Ad Unit"
15. **Copy the Ad Unit ID**

## Step 3: Update Ad Unit IDs in Code

Open `Sources/Services/AdManager.swift` and replace the production ad unit IDs:

```swift
private enum AdUnitID {
    // ... test IDs stay the same ...

    // Replace these with your actual AdMob IDs
    static let productionBanner = "ca-app-pub-1453954241423045~4496056156"  // ← Your banner ID
    static let productionInterstitial = "ca-app-pub-1453954241423045~4496056156"  // ← Your interstitial ID
}
```

## Step 4: Configure Info.plist

Add the following keys to your `Info.plist`:

### Required: AdMob App ID

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~AAAAAAAAAA</string>
```

Replace with your **AdMob App ID** (find this in AdMob console → App Settings).

### Optional: App Tracking Transparency (ATT)

```xml
<key>NSUserTrackingUsageDescription</key>
<string>This app uses contextual ads based on game content, not personal tracking.</string>

<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
    <!-- Google's SKAdNetwork identifiers -->
    <!-- Find full list at: https://developers.google.com/admob/ios/compatible-ad-networks -->
</array>
```

## Step 5: Initialize AdMob in Your App

The AdManager is already configured to initialize automatically, but you need to call it from your app's entry point.

Add to your `@main` App struct or first view's `onAppear`:

```swift
import SwiftUI

@main
struct AtlasSolitareApp: App {
    init() {
        // Initialize AdMob
        AdManager.shared.initialize()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Step 6: Add Banner Ad to Game View

The banner ad is already integrated into `GameView.swift`. Just make sure it's placed at the bottom:

```swift
VStack {
    // Game content

    Spacer()

    // Banner ad at bottom
    if AdManager.shared.areAdsEnabled {
        BannerAdView()
            .frame(height: BannerAdView.fixedHeight())
    }
}
```

## Step 7: Trigger Interstitial Ads

Interstitial ads are automatically triggered every 20 games. The logic is already implemented in `AdManager.swift`:

```swift
// In GameViewModel when game ends (win or loss):
AdManager.shared.onGameEnd()
```

## Testing

### Development Mode (Automatic)
- In `DEBUG` builds, **only test ads** are shown
- Test ads are provided by Google and generate no revenue
- Safe to click and interact with during development

### Test on Physical Device
To test on your iPhone/iPad:
1. Build and run in DEBUG mode
2. You should see ads labeled "Test Ad"
3. If you see real ads, check that your build configuration is set to DEBUG

### Production Mode
- In `RELEASE` builds, real ads are shown
- Never click your own ads in production!

## Disabling Ads

### For Testing
```swift
AdManager.shared.globalAdsEnabled = false
```

### For Premium Users (Future Feature)
Add this to your settings persistence:
```swift
// In AppSettings
var adsEnabled: Bool = true

// When user purchases ad removal
settings.adsEnabled = false
AdManager.shared.globalAdsEnabled = false
```

### Via Settings UI
Users can toggle ads in Settings already - the UI is connected to `AdManager.shared.areAdsEnabled`.

## Privacy & Targeting

### Contextual Targeting
The app is configured to use **contextual targeting** based on content, not user tracking:

```swift
// In AdManager.createAdRequest()
extras.additionalParameters = [
    "content_url": "https://atlassolitaire.com/geography-card-game",
    "category": "games_educational",
    "topics": "geography,education,puzzle,card-games"
]
```

This tells Google:
- ✅ The app is about geography and educational games
- ✅ Show relevant ads (travel, education, games)
- ❌ Does NOT track user across other apps
- ❌ Does NOT use personal data

### What Data is Collected?
- **Google collects**: Device type, OS version, ad interactions
- **Google does NOT collect**: User location, browsing history, personal info
- **Personalization**: DISABLED (set in `configureRequestConfiguration()`)

## Troubleshooting

### Ads Not Showing
1. Check that Ad Unit IDs are correct
2. Verify `GADApplicationIdentifier` is in Info.plist
3. Check console for error messages
4. Ensure you're using test ads in development

### "Invalid Ad Unit ID" Error
- You forgot to replace production IDs in `AdManager.swift`
- Use test IDs for now: `ca-app-pub-3940256099942544/2934735716`

### Real Ads in Development
- Check your build configuration is set to `DEBUG`
- Test device ID might not be registered

### Low Fill Rate (Few Ads)
- Normal for new apps - improves over time
- AdMob needs data to optimize ad delivery
- Consider adding more content categories

## Revenue Optimization

### Expected Revenue (Estimates)
- **Banner CPM**: $0.10 - $2.00 per 1000 impressions
- **Interstitial CPM**: $1.00 - $10.00 per 1000 impressions
- **Geography/Education niche**: Medium-high CPM

### Tips
1. Don't show ads too frequently (current: every 20 games is good)
2. Keep ads non-intrusive (banner at bottom is perfect)
3. Ensure good user experience (users who play longer = more ad views)
4. Consider rewarded ads for hints/power-ups in future

## Next Steps

1. ✅ Install Google Mobile Ads SDK
2. ✅ Create AdMob account and get Ad Unit IDs
3. ✅ Update `AdManager.swift` with your production IDs
4. ✅ Add `GADApplicationIdentifier` to Info.plist
5. ✅ Test with test ads in development
6. ✅ Submit to App Store with real ads enabled

## Support

- **AdMob Help**: https://support.google.com/admob
- **iOS Integration Guide**: https://developers.google.com/admob/ios/quick-start
- **Privacy & Consent**: https://developers.google.com/admob/ios/privacy

---

**Important**: Never click your own ads in production! This violates AdMob policies and can get your account banned.
