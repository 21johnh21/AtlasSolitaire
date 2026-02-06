# Atlas Solitaire — Quick Setup Guide

## Step-by-Step Xcode Project Creation

Since this repository contains source files only (no `.xcodeproj`), follow these steps to create a working project:

---

### 1. Create New Xcode Project

```bash
cd /Users/johnhawley/Documents/src/AtlasSolitaire
```

1. Launch **Xcode 15+**
2. **File → New → Project**
3. Select **iOS → App**
4. Configure:
   - **Product Name:** `AtlasSolitaire`
   - **Team:** (select your team or leave as "None")
   - **Organization Identifier:** `com.atlassolitaire` (or your reverse-domain)
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** None
   - **Uncheck:** Include Tests (we have custom test targets)
5. **Save location:** Select the `AtlasSolitaire` folder itself (the one containing this SETUP.md)

Xcode will create an `.xcodeproj` file here.

---

### 2. Clean Up Default Files

Xcode creates some placeholder files we don't need:

1. In the Project Navigator (left sidebar), **delete** these files:
   - `ContentView.swift` (if present)
   - `AtlasSolitaireApp.swift` (Xcode's default — we have our own in `App/`)
2. When prompted, choose **Move to Trash**

---

### 3. Add Source Files to Project

#### Option A: Drag & Drop (Recommended)

1. In **Finder**, navigate to `/Users/johnhawley/Documents/src/AtlasSolitaire/`
2. Drag the following folders from Finder **into** the Xcode project navigator:
   - `App/`
   - `Sources/`
   - `Data/`
3. In the import dialog:
   - **Uncheck** "Copy items if needed" (files are already in place)
   - Select **"Create groups"** (not folder references)
   - Check **AtlasSolitaire** target
   - Click **Finish**

#### Option B: Add Files Manually

1. Right-click on the `AtlasSolitaire` group in the navigator
2. **Add Files to "AtlasSolitaire"...**
3. Navigate to each folder (`App`, `Sources`, `Data`) and select all files
4. Repeat for each subfolder

---

### 4. Verify Data Files Are in Bundle

JSON files must be copied to the app bundle:

1. Select the **AtlasSolitaire** target (blue icon at top of navigator)
2. Go to **Build Phases** tab
3. Expand **Copy Bundle Resources**
4. Verify these files are listed:
   ```
   europe_countries_01.json
   island_nations_01.json
   us_states_01.json
   national_capitals_01.json
   cities_in_uk_01.json
   default_deck.json
   ```
5. If missing, click **+** and add files from `Data/groups/` and `Data/decks/`

---

### 5. Add Test Target (Optional)

1. Click **+** at bottom-left of the targets list
2. Choose **iOS → Unit Testing Bundle**
3. Name it `AtlasSolitaireTests`
4. Delete the default test file Xcode creates
5. Add files from `Tests/` folder to this target:
   - `GameEngineTests.swift`
   - `DeckManagerTests.swift`

---

### 6. Configure Build Settings

#### Deployment Target

1. Select **AtlasSolitaire** target
2. **General** tab → **Deployment Info**
3. Set **Minimum Deployment:** iOS 16.0 or later

#### Supported Orientations

For iPhone:
- ✅ Portrait
- ❌ Landscape Left
- ❌ Landscape Right
- ❌ Upside Down

For iPad:
- ✅ Portrait
- ✅ Landscape (optional — layout is portrait-first)

---

### 7. Build & Run

1. Select a simulator: **Product → Destination → iPhone 15 Pro** (or any iOS 16+ device)
2. Press **⌘R** or click the **Play** button
3. The app should launch and display the **Atlas Solitaire** menu

---

## Troubleshooting

### "Cannot find 'Card' in scope"

**Fix:** Make sure all files in `Sources/Models/` are added to the app target:
- Select each `.swift` file
- In the **File Inspector** (right sidebar), check the **Target Membership** box for `AtlasSolitaire`

### "No such module 'SwiftUI'"

**Fix:** Verify deployment target is iOS 16+ (SwiftUI is available on all modern iOS).

### JSON Files Not Loading

**Fix:**
1. Verify JSON files appear in **Build Phases → Copy Bundle Resources**
2. Ensure file paths in `Data/groups/` and `Data/decks/` are correct
3. Check that JSON is valid (use `jsonlint` or paste into https://jsonlint.com)

### Tests Don't Run

**Fix:**
1. Ensure test files are added to the **AtlasSolitaireTests** target (not the main app target)
2. In each test file, add `@testable import AtlasSolitaire` at the top
3. Make sure classes/structs being tested are `public` or `internal` (not `private`)

---

## Next Steps

- **Add sound files:** Drop `.wav` files into `Assets/Sounds/` and add to Copy Bundle Resources
- **Customize groups:** Edit JSON files in `Data/groups/` to add new geography categories
- **Tweak UI:** Modify color palette in `Extensions.swift` (`Color.feltGreen`, etc.)
- **Run tests:** Press **⌘U** to verify all unit tests pass

---

**You're all set!** 🚀

Check `README.md` for gameplay rules and architecture details.
