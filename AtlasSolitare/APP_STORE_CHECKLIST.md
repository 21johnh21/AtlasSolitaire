# Atlas Solitaire - App Store Readiness Checklist

**Review Date:** February 22, 2026
**Bundle ID:** com.atlassolitare.AtlasSolitare
**Version:** 1.0 (Build 1)

---

## ✅ COMPLETED ITEMS

### 1. Project Configuration
- ✅ **Info.plist** - Properly configured with all required keys
- ✅ **Bundle Identifier** - `com.atlassolitare.AtlasSolitare`
- ✅ **Version Numbers** - 1.0 (1)
- ✅ **Display Name** - "Atlas Solitaire"
- ✅ **Platform** - iOS only (iPhone + iPad)
- ✅ **Supported Orientations** - Portrait, Landscape Left, Landscape Right
- ✅ **Game Center Entitlements** - Configured in `AtlasSolitare.entitlements`
- ✅ **SKAdNetwork Identifiers** - All 50 required networks added for AdMob

### 2. Privacy & Permissions
- ✅ **App Tracking Transparency** - `NSUserTrackingUsageDescription` configured
- ✅ **Privacy Description** - Clear message about contextual ads (no personal tracking)
- ✅ **No sensitive permissions** - App doesn't request camera, location, contacts, etc.

### 3. AdMob Integration
- ✅ **SDK Installed** - Google Mobile Ads SDK 13.0.0
- ✅ **App ID Configured** - `ca-app-pub-1453954241423045~4496056156`
- ✅ **Test/Production Switching** - Automatic via `#if DEBUG`
- ✅ **Privacy-First Targeting** - Contextual ads only, no cross-app tracking
- ✅ **Banner Ads** - Implemented at bottom of game screen
- ✅ **Interstitial Ads** - Every 10 games (configurable)
- ✅ **User Control** - Ads can be toggled off in settings

### 4. Game Center Integration
- ✅ **Authentication** - Configured with proper entitlements
- ✅ **Leaderboards Defined** - Fastest Time, Fewest Moves
- ✅ **Achievements Defined** - 9 achievements for various milestones
- ✅ **Development Testing** - DEBUG mode allows UI testing without server connection

### 5. Code Quality
- ✅ **Build Success** - Clean build with no errors
- ✅ **DEBUG Features** - Properly wrapped in `#if DEBUG` conditionals
  - Dev "Win" button (for testing interstitial ads)
  - Game Center UI testing without authentication
  - Test ad IDs in development
- ✅ **No Dead Code** - All imports are used
- ✅ **Proper Architecture** - MVVM pattern with clean separation

---

## ⚠️ CRITICAL - MUST FIX BEFORE RELEASE

### 1. AdMob Production Ad Unit IDs
**Status:** ❌ **BLOCKING** - App will NOT show ads without these

**Current State:**
```swift
static let productionBanner = "ca-app-pub-1453954241423045/XXXXX_BANNER"
static let productionInterstitial = "ca-app-pub-1453954241423045/XXXXX_INTERSTITIAL"
```

**Required Actions:**
1. Go to [AdMob Console](https://apps.admob.com/)
2. Sign in with your Google account
3. Navigate to **Apps** → **Atlas Solitaire**
4. Click **Add Ad Unit**
5. Create a **Banner** ad unit
   - Copy the ad unit ID (format: `ca-app-pub-1453954241423045/1234567890`)
   - Replace `XXXXX_BANNER` in `AdManager.swift` line 46
6. Create an **Interstitial** ad unit
   - Copy the ad unit ID
   - Replace `XXXXX_INTERSTITIAL` in `AdManager.swift` line 47
7. Save and rebuild

**File Location:** `AtlasSolitare/Sources/Services/AdManager.swift:46-47`

---

## 🌐 WEBSITE SETUP (5 Minutes - Do This First!)

You need URLs for:
- **Support URL** (required by App Store)
- **Privacy Policy URL** (required by AdMob)
- **Marketing URL** (optional but recommended)

### Quick Setup with GitHub Pages (FREE):

1. **Create GitHub Repository:**
   ```bash
   cd /Users/johnhawley/Documents/src/AtlasSolitaire/AtlasSolitare
   git init
   git add .
   git commit -m "Initial commit"

   # Create repo on github.com, then:
   git remote add origin https://github.com/YOUR_USERNAME/atlas-solitaire.git
   git push -u origin main
   ```

2. **Enable GitHub Pages:**
   - Go to GitHub repo → Settings → Pages
   - Source: Branch `main`, folder `/docs`
   - Save and wait 2-3 minutes

3. **Your URLs will be:**
   - Marketing: `https://YOUR_USERNAME.github.io/atlas-solitaire/`
   - Support: `https://YOUR_USERNAME.github.io/atlas-solitaire/support.html`
   - Privacy: `https://YOUR_USERNAME.github.io/atlas-solitaire/privacy.html`

**Full instructions in:** `docs/README.md`

**Before going live:** Replace placeholder emails in HTML files with your real email!

---

## 📋 APP STORE CONNECT SETUP (Before Submission)

### 1. Create App on App Store Connect
1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Click **My Apps** → **+** → **New App**
3. Fill in details:
   - **Platform:** iOS
   - **Name:** Atlas Solitaire
   - **Primary Language:** English
   - **Bundle ID:** `com.atlassolitare.AtlasSolitare`
   - **SKU:** `atlassolitaire-ios` (or your choice)

### 2. App Information
- **Category:** Games → Card
- **Secondary Category:** (optional) Games → Puzzle
- **Content Rights:** Check if you own all content
- **Age Rating:** Complete questionnaire (likely 4+)

### 3. Pricing & Availability
- **Price:** Free (with ads)
- **Availability:** All countries (or your selection)

### 4. App Privacy
**Required Privacy Declarations:**

**Data Types Collected:**
- ✅ **Advertising Data** - For contextual ad targeting
  - Used for: **Third-Party Advertising**
  - Linked to user: **No**
  - Used for tracking: **No**

**Third-Party SDKs:**
- Google AdMob (advertising)
- GameKit (Game Center - Apple's framework)

**Privacy Policy URL:** You'll need to create a privacy policy and host it somewhere (GitHub Pages, your website, etc.)

### 5. Game Center Setup
1. In App Store Connect, go to your app
2. Navigate to **Services** → **Game Center**
3. Click **Enable Game Center**
4. Add Leaderboards:
   - **ID:** `com.atlassolitaire.leaderboard.fastesttime`
   - **Name:** Fastest Time
   - **Format:** Time (Elapsed)
   - **Sort:** Low to High

   - **ID:** `com.atlassolitaire.leaderboard.fewestmoves`
   - **Name:** Fewest Moves
   - **Format:** Integer
   - **Sort:** Low to High

5. Add Achievements (9 total):
   - `com.atlassolitaire.achievement.firstwin` - First Win (10 points)
   - `com.atlassolitaire.achievement.speeddemon` - Speed Demon - Win in under 2 minutes (25 points)
   - `com.atlassolitaire.achievement.efficient` - Efficient - Win in under 50 moves (25 points)
   - `com.atlassolitaire.achievement.perfectgame` - Perfect Game - Win in under 1 min AND 40 moves (50 points)
   - `com.atlassolitaire.achievement.winstreak5` - 5 Win Streak (30 points)
   - `com.atlassolitaire.achievement.winstreak10` - 10 Win Streak (50 points)
   - `com.atlassolitaire.achievement.totalwins10` - 10 Total Wins (20 points)
   - `com.atlassolitaire.achievement.totalwins50` - 50 Total Wins (40 points)
   - `com.atlassolitaire.achievement.totalwins100` - 100 Total Wins (60 points)

---

## 📱 APP STORE ASSETS NEEDED

### Screenshots Required
- **6.9" Display (iPhone 16 Pro Max)** - Minimum 3, maximum 10
- **6.7" Display (iPhone 15 Pro Max)** - Minimum 3, maximum 10
- **6.5" Display** - Minimum 3, maximum 10
- **5.5" Display** - Minimum 3, maximum 10
- **12.9" Display (iPad Pro)** - Minimum 3, maximum 10
- **Recommended:** Show gameplay, winning screen, settings, Game Center

### App Icon
- **Required:** 1024×1024 PNG (no transparency, no rounded corners)
- Already in Assets.xcassets, but verify it's high quality

### App Preview Video (Optional but Recommended)
- 15-30 seconds showing gameplay
- Portrait orientation
- No sound effects required but recommended

### Marketing Materials
- **App Description** (Up to 4,000 characters)
- **Promotional Text** (170 characters - can be updated without new submission)
- **Keywords** (100 characters) - Suggestions:
  - "solitaire,card game,atlas,klondike,patience,cards,puzzle,strategy,brain"
- **Support URL** - Where users can get help
- **Marketing URL** (optional) - Your website or landing page

---

## 🚀 BUILD & SUBMISSION PROCESS

### 1. Pre-Submission Checklist
- [ ] Replace AdMob production ad unit IDs
- [ ] Set up Game Center on App Store Connect
- [ ] Test on real device (not simulator)
- [ ] Test with Release build configuration
- [ ] Verify ads show correctly
- [ ] Verify Game Center works (after server setup)
- [ ] Take screenshots on required device sizes
- [ ] Prepare app icon (1024×1024)
- [ ] Write app description
- [ ] Create privacy policy
- [ ] Set up support email/website

### 2. Archive & Upload
```bash
# 1. Select "Any iOS Device" as the run destination in Xcode
# 2. Product → Archive
# 3. Wait for archive to complete
# 4. Window → Organizer
# 5. Select your archive
# 6. Click "Distribute App"
# 7. Choose "App Store Connect"
# 8. Upload
# 9. Wait for processing (can take 15-60 minutes)
```

### 3. TestFlight Beta Testing (Recommended)
1. After upload processes, go to App Store Connect
2. Navigate to **TestFlight**
3. Add yourself as an internal tester
4. Install TestFlight app on your device
5. Test the production build thoroughly
6. Fix any issues and upload new build

### 4. Submit for Review
1. In App Store Connect, go to your app
2. Click **App Store** tab
3. Fill in all required information
4. Upload screenshots for all required sizes
5. Click **Submit for Review**
6. Answer export compliance questions
7. Wait for review (typically 1-3 days)

---

## 📊 CURRENT STATUS SUMMARY

### What's Ready
✅ Core game functionality complete
✅ AdMob SDK integrated with test ads working
✅ Game Center configured with entitlements
✅ Privacy descriptions in place
✅ Build succeeds with no errors
✅ DEBUG features properly isolated
✅ UI/UX polished and complete

### What's Missing (BLOCKING RELEASE)
❌ Production AdMob ad unit IDs
❌ Game Center configured on App Store Connect
❌ App Store assets (screenshots, description, etc.)
✅ Privacy policy, support, and marketing pages created (in `docs/` folder)
⚠️ Website hosting setup needed (see instructions below)

### Estimated Time to Release
- **If you have assets ready:** 1-2 hours setup + 1-3 days review
- **If you need to create assets:** 1-2 days prep + 1-3 days review

---

## 💡 RECOMMENDATIONS

### Before First Submission
1. **Test on Real Device** - Simulator doesn't accurately represent performance
2. **Test Ads** - Make sure both banner and interstitial show correctly in DEBUG
3. **TestFlight Beta** - Always test production build before public release
4. **Proofread Everything** - App name, description, keywords (hard to change after launch)

### Post-Launch Monitoring
1. **Check AdMob Dashboard** - Monitor ad revenue and fill rates
2. **Game Center Leaderboards** - Ensure data is syncing correctly
3. **Crash Reports** - Monitor in App Store Connect
4. **User Reviews** - Respond to feedback
5. **Analytics** - Consider adding App Store analytics or third-party tool

### Future Enhancements (Optional)
- In-app purchases to remove ads (premium version)
- More deck themes/card designs
- Daily challenges
- Multiplayer features
- Cloud save sync across devices
- Achievement animations

---

## 📞 SUPPORT RESOURCES

- **App Store Connect:** https://appstoreconnect.apple.com/
- **AdMob Console:** https://apps.admob.com/
- **Apple Developer:** https://developer.apple.com/
- **App Review Guidelines:** https://developer.apple.com/app-store/review/guidelines/
- **Human Interface Guidelines:** https://developer.apple.com/design/human-interface-guidelines/

---

## ✅ FINAL CHECKLIST

Before you submit, check all these boxes:

**Code:**
- [ ] Production ad unit IDs configured
- [ ] Build succeeds in Release configuration
- [ ] Tested on real iOS device
- [ ] No debug print statements in production code (we have proper logging)
- [ ] Version number set correctly (1.0)

**App Store Connect:**
- [ ] App created
- [ ] Game Center leaderboards added
- [ ] Game Center achievements added
- [ ] Privacy policy created and URL added
- [ ] App description written
- [ ] Keywords selected
- [ ] Screenshots uploaded (all required sizes)
- [ ] App icon uploaded (1024×1024)
- [ ] Support URL configured
- [ ] Pricing set (Free)
- [ ] Countries/regions selected

**Legal:**
- [ ] Privacy policy complies with requirements
- [ ] Content rights verified
- [ ] Age rating appropriate
- [ ] Export compliance answered

**Testing:**
- [ ] Tested game mechanics thoroughly
- [ ] Tested ads (banner and interstitial)
- [ ] Tested settings (sound, haptics, ads toggle)
- [ ] Tested Game Center UI
- [ ] Tested on multiple device sizes
- [ ] Tested with low battery mode
- [ ] Tested airplane mode behavior

---

## 🎉 YOU'RE ALMOST READY!

Your app is in excellent shape. The code is clean, well-architected, and follows best practices. Once you:

1. Create the AdMob ad units and update the IDs
2. Set up Game Center on App Store Connect
3. Prepare your App Store assets

You'll be ready to submit! Good luck with your launch! 🚀
