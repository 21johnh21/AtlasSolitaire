# Atlas Solitaire

**Geography-themed Klondike-style solitaire for iPhone and iPad**

---

## Quick Start

### Prerequisites

- **Xcode 15+** (for iOS 16+ deployment target)
- **macOS Ventura** or later
- **Swift 5.9+**

### Creating the Xcode Project

This repository contains all source files but no `.xcodeproj` file. Follow these steps to create a working Xcode project:

1. **Open Xcode** and select **File → New → Project**
2. Choose **iOS → App** template
3. Configure:
   - **Product Name:** `AtlasSolitaire`
   - **Team:** (your Apple Developer team)
   - **Organization Identifier:** `com.yourcompany` (or leave default)
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** None (we use custom persistence)
   - **Uncheck** "Include Tests" (we have custom test targets)
4. Save the project **inside** `/Users/johnhawley/Documents/src/AtlasSolitaire/`

### Importing Source Files

1. **Delete** the default `ContentView.swift` and any placeholder files Xcode created
2. **Drag and drop** the following folders from Finder into the Xcode project navigator:
   - `App/`
   - `Sources/`
   - `Data/`
   - `Tests/` (create a new test target first if needed)
3. When prompted, select:
   - ✅ **Copy items if needed** (uncheck — files are already in place)
   - ✅ **Create groups** (not folder references)
   - ✅ Add to target: `AtlasSolitaire`
4. For the `Data/` folder:
   - Make sure **both** `groups/` and `decks/` subfolders are added to the app target
   - Verify JSON files appear in **Build Phases → Copy Bundle Resources**

### Verify Build

1. Select a simulator (e.g., iPhone 15 Pro) or device
2. Press **⌘R** to build and run
3. You should see the **Atlas Solitaire** menu screen

---

## Project Structure

```
AtlasSolitaire/
├─ App/
│  └─ AtlasSolitaireApp.swift       # App entry point, view model wiring
├─ Sources/
│  ├─ Models/                       # Data models (Card, Group, Deck, GameState)
│  ├─ GameEngine/                   # Core game logic (Rules, GameEngine)
│  ├─ ViewModels/                   # GameViewModel (ObservableObject)
│  ├─ Views/                        # SwiftUI views (CardView, GameView, etc.)
│  ├─ Services/                     # Managers (DeckManager, Persistence, Audio, Haptics)
│  └─ Utils/                        # Extensions and shared constants
├─ Data/
│  ├─ groups/                       # JSON group definitions (5 samples included)
│  └─ decks/                        # Deck definition files
├─ Tests/                           # Unit tests (GameEngineTests, DeckManagerTests)
├─ PROJECT_SPEC.md                  # Full feature specification
└─ README.md                        # This file
```

---

## How to Play

### Goal
Complete all geography card groups by stacking base cards and their partners onto foundation piles.

### Rules
- **Stock pile (top-right):** Tap to draw cards one at a time to the waste pile. When empty, tap again to reshuffle.
- **Waste pile (top-left):** The top card is always visible and draggable.
- **Foundation piles (4 slots):**
  - Place a **base card** (e.g., "Countries of Europe") on an empty slot.
  - Stack **partner cards** from the same group (e.g., "France", "Italy") onto the base in any order.
  - When all cards of a group are on a foundation, the group is **cleared** (removed from play).
- **Tableau piles (4 columns):**
  - Cards are dealt face-down; top card is face-up.
  - Empty tableau slots accept any card.
  - Partner cards from the same group can stack on each other in tableau.
- **Win condition:** Clear all groups in the deck.

### Interactions
- **Tap-to-select:** Tap a card to select it (highlighted in gold), then tap a destination.
- **Drag-and-drop:** Drag a card directly to a foundation or tableau pile.
- **Tap stock:** Draw a card (or reshuffle when stock is empty).

---

## Architecture

### MVVM + ObservableObject
- **GameViewModel** is the single source of truth, owns the `GameEngine`, and publishes state to SwiftUI views.
- **GameEngine** contains pure game logic (no SwiftUI) for easy unit testing.
- **Rules** module is fully stateless — all validation logic is static and deterministic.

### Data Flow
1. User interaction (tap / drag) → **View** calls intent method on **GameViewModel**
2. **GameViewModel** calls **GameEngine** mutation method
3. **GameEngine** validates via **Rules**, mutates `GameState`, triggers `onStateChanged` callback
4. **GameViewModel** publishes updated state → SwiftUI re-renders

### Persistence
- Game state auto-saves to Application Support directory as JSON after every move.
- On app launch, the last saved game is restored (if `phase == .playing`).
- Settings (sound/haptics toggles) persist separately.

### Audio & Haptics
- **AudioManager** pre-loads `.wav` files from `Assets/Sounds/` (placeholders for now).
- **HapticManager** fires `UIImpactFeedbackGenerator` events on drag/drop/success.
- Both managers respect user settings.

---

## Adding New Groups

1. Create a new JSON file in `Data/groups/` following this format:

```json
{
  "group_id": "african_capitals_01",
  "group_name": "African Capitals",
  "base_card": {
    "id": "african_capitals_base",
    "label": "African Capitals",
    "type": "base",
    "image": null
  },
  "partner_cards": [
    { "id": "cairo", "label": "Cairo", "type": "partner", "image": null },
    { "id": "nairobi", "label": "Nairobi", "type": "partner", "image": null }
  ],
  "metadata": {
    "difficulty": "medium",
    "source": "local-json"
  }
}
```

2. Add the file to the Xcode project (**Copy Bundle Resources**)
3. The `DeckManager` will automatically discover it when building random decks

**Note:** Card IDs within a group must be unique (e.g., `"cairo"`). IDs are scoped at runtime by prefixing with `group_id` to ensure global uniqueness across groups.

---

## Testing

### Unit Tests

Run tests via **⌘U** in Xcode or:

```bash
xcodebuild test -scheme AtlasSolitaire -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

**Coverage includes:**
- All `Rules` validation logic (foundation, tableau, reshuffle, group completion)
- `GameEngine` operations (draw, move, reshuffle, win detection)
- `DeckManager` group loading, deduplication, seeded shuffles

### Manual Testing Checklist

- [ ] New game starts with 4 tableau piles, cards dealt face-down except top cards
- [ ] Tapping stock draws a card to waste
- [ ] Reshuffle works when stock is empty
- [ ] Base cards can only be placed on empty foundations
- [ ] Partner cards stack on matching bases
- [ ] Completed groups are cleared and foundation slot becomes available
- [ ] Win screen appears when all groups cleared
- [ ] Game state persists across app restarts
- [ ] Sound/haptic settings persist

---

## Extending the App

### Migrate to API Backend

The `DeckManager` uses a protocol `GroupDataSource`. To fetch groups from a server:

1. Create a new class `RemoteAPIDataSource: GroupDataSource`
2. Implement `loadAllGroups()` and `loadDeck(id:)` with network calls
3. Inject `RemoteAPIDataSource()` into `DeckManager` at app launch

The rest of the codebase remains unchanged.

### Add Images

1. Add `.png` assets to `Assets.xcassets` (e.g., `france.png`)
2. Update JSON files with `"image": "france"`
3. Modify `CardView` to display `Image(card.imageName!)` instead of text labels

### Undo Stack

The `GameState` has a `@CodableIgnored var previousState` field ready for single-level undo. Wire up:

```swift
engine.state.previousState = currentStateCopy
```

before mutations, then add an "Undo" button that calls:

```swift
if let prev = engine.state.previousState {
    engine.state = prev
    publishState()
}
```

---

## Known Limitations / TODOs

- **No hint system** — player must discover valid moves manually
- **No animations for group clear** — cards disappear instantly (opportunity for particle effects)
- **No difficulty settings** — number of groups per round is hardcoded (easy to parameterize)
- **No statistics / leaderboards** — no game history tracking yet
- **Sound files are placeholders** — actual `.wav` assets not included

---

## Credits

Built in **Swift + SwiftUI** following Apple's modern best practices.

**Architecture:** MVVM with ObservableObject
**Persistence:** Codable JSON to Application Support
**Animations:** SwiftUI `.animation()` and `matchedGeometryEffect`
**Haptics:** UIKit `UIImpactFeedbackGenerator`
**Audio:** AVFoundation `AVAudioPlayer`

---

## License

This project is provided as-is for educational and development purposes. Customize freely.

---

**Enjoy your journey around the world, one card at a time!** 🌍🃏
