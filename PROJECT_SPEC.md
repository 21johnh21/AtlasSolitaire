# Atlas Solitaire — Project Specification

## 1 — Summary

Atlas Solitaire is a geography-themed Klondike-style solitaire built in Swift + SwiftUI for iPhone and iPad (portrait-first). Players stack related geography cards into foundation piles: each card belongs to a card group (a base card + partner cards). The app is data-driven with card groups defined in local JSON files (with placeholders for images for future expansion) and room to migrate to an API later. Every interaction must expose places for animations, haptic feedback, and sound.

Target audience: learners and casual players who enjoy a relaxing, thoughtful puzzle experience.

---

## 2 — Core Gameplay & Rules (Functional Spec)

### Layout (portrait)
- **Top-right:** Stock Pile (face-down stack)
- **Left of Stock:** Waste Pile (faces-up stack of drawn cards)
- **Below Stock/Waste:** 4 Foundation Piles (empty slots initially) — base cards (group bases) are placed here first; partner cards are added to matching base.
- **Below Foundation:** Tableau Piles (4 piles by default, like Klondike) — top card visible; other cards face-down. Empty tableau slots accept any card.

### Components & Behavior

#### Stock pile
- Click/tap draws the top card onto the top of the Waste pile (face-up).
- When stock is empty, user can tap a Reshuffle control (or it can be automatic when pressing stock) to shuffle all cards from the waste back into stock.
- Unlimited reshuffles allowed.

#### Waste pile
- Holds cards drawn from stock; top card is draggable.
- Cards can be dragged and dropped to any valid target (tableau, foundation).

#### Tableau piles
- Initially populated with random cards; only top card face-up (others face-down).
- Dragging top card reveals next card (flip to face-up).
- Empty tableau slot accepts any card.
- Partner cards can be stacked onto other partner cards of the same group in tableau.

#### Foundation piles
- There are exactly 4 foundation slots.
- Only Base cards (group base) can be placed on an empty foundation pile.
- After a base card is placed, partner cards from the same group can be placed on top of that base card in any order (no rank ordering required — matching group membership is the rule).
- When every card of a given group (base + all its partners) is placed on any one foundation pile (i.e., the group is completed), that group is cleared — those cards are removed from play and counted as completed. (This allows there to be more distinct groups than the 4 foundation slots.)

### Win Condition
The player wins when all groups present in the deck for that round are completed (i.e., all cards cleared). On win, show a win screen with options: Play Again (randomize new groups and deal) or Return to Menu.

### Other rules
- Free-play mode: categories/groups are randomized each round.
- There can be more groups than foundation piles. Players must decide which groups to place onto the 4 foundation slots; completed groups are removed to free foundation slots for other bases.
- Moving cards follows simplest rules:
  - Base cards only to empty foundation slot or empty tableau.
  - Partner cards to matching base in foundation or to other partner cards of the same group on tableau.
- Drag & drop interactions should animate smoothly and provide haptic and sound feedback hooks.

---

## 3 — Data Model & JSON Schema

### Goals
- Data-driven; initial storage via local JSON files. Easy to migrate to API later.
- Text-first cards now; include optional image placeholder for future images.

### Example JSON for a single group file
```json
{
  "group_id": "europe_countries_01",
  "group_name": "Countries of Europe",
  "base_card": {
    "id": "europe_base",
    "label": "Countries of Europe",
    "type": "base",
    "image": null
  },
  "partner_cards": [
    { "id": "france", "label": "France", "type": "partner", "image": null },
    { "id": "italy", "label": "Italy", "type": "partner", "image": null },
    { "id": "spain", "label": "Spain", "type": "partner", "image": null }
  ],
  "metadata": {
    "difficulty": "easy",
    "source": "local-json",
    "notes": "example group"
  }
}
```

### Deck file (combined)
A deck JSON file selects N groups to include in a game round, or you can store all groups and the client randomly selects groups per round.

```json
{
  "deck_id": "deck_2026_01",
  "deck_name": "Randomized Round",
  "groups": ["europe_countries_01", "island_nations_01", "us_states_01"],
  "shuffle_seed": 12345
}
```

### Card representation (Swift-friendly)
Minimal card model for runtime (Swift structs):

```swift
struct Card: Identifiable, Codable {
  let id: String
  let label: String
  let type: CardType // .base | .partner
  let groupId: String
  let imageName: String? // placeholder for future image assets
}
```

---

## 4 — Swift / Architecture Recommendations

### Tech stack
- **Language:** Swift 5.x
- **UI:** SwiftUI (iOS 16+ recommended)
- **Persistence:** FileManager + local JSON storage for group definitions; UserDefaults or SQLite/Core Data for saving game state. (Recommend simple Codable file saved in Application Support for game state.)
- **DI / State:** Use MVVM with ObservableObject view models. Consider Redux-like single source of truth (e.g., GameState ObservableObject) for deterministic behavior that's easier to test.
- **Haptics:** UIImpactFeedbackGenerator / UINotificationFeedbackGenerator via UIViewRepresentable or modern SwiftUI wrappers.
- **Sounds:** AVFoundation/AudioPlayer wrapper; play short sound effects for card flip, move, invalid drop, win, etc.
- **Animations:** SwiftUI animations and matchedGeometryEffect for smooth moves.

### Key modules / components
- **GameEngine** — core rules and validations (pure Swift; easily testable).
- **DeckManager** — loads JSON groups, builds the deck, shuffles with seeded RNG for reproducibility.
- **GameState (ObservableObject)** — current piles, moved cards, undo stack (optional).
- **PersistenceManager** — save/load game state and settings.
- **UI** — Views for Stock, Waste, Foundation, Tableau, CardView, Menu, Win screen.
- **InteractionManager** — drag/drop handling and mapping to GameEngine operations.
- **AudioManager, HapticManager, AnimationHooks.**

---

## 5 — Persistence & Game State
Save the following on device:
- Current deck + groups used.
- Pile contents: stock (order), waste, foundation slots, tableau piles (face up/down states).
- Completed groups list and counters.
- Settings (sound enabled, haptics enabled).

Use Codable structs and write as a single JSON file to Application Support. Autosave on every meaningful state change and on backgrounding.

---

## 6 — UI/UX Details & Interaction Hooks

### CardView
- **Props:** card, isFaceUp, isDraggable, isHighlighted.
- **Events:** onTap, onLongPress, onDragStart, onDrop.
- Provide `animationIdentifier` to coordinate matchedGeometryEffect.
- Provide sound/haptic hooks: onFlip, onDrag, onDropSuccess, onDropFail.

### Animations
- **Flip:** 3D flip transition for revealing card.
- **Move:** matchedGeometryEffect or animated position transitions for drag/drop.
- **Reveal:** subtle scale + opacity when revealing new face-up card under a tableau.

### Haptics (configurable on/off)
- Light impact on drag start.
- Medium impact on successful placement.
- Notification success on group completed / win.

### Sounds
Minimal fx set: `flip.wav`, `move.wav`, `drop_success.wav`, `invalid.wav`, `complete_group.wav`, `win.wav`.
Sounds are short and non-intrusive; user setting to disable.

### Accessibility
- Support VoiceOver labels for card labels and piles.
- Ensure drag/drop alternatives (tap-to-select & choose target).
- Large Dynamic Type support for labels.

---

## 7 — Edge Cases & Rules Clarifications (deterministic behavior)
- If a partner card is dragged to a foundation with a different base card: invalid — return to source.
- If more than one partner of same group exists on tableau, stacking is allowed only when the target top card is of the same group.
- When group completes and cards are cleared, reveal any newly exposed tableau cards immediately.
- If the player tries to place a base card on a non-empty foundation slot: invalid.
- When deck is randomized, ensure at least one base card exists among groups chosen (obvious but ensure generator prevents degenerate decks).

---

## 8 — File & Repo Structure (suggested)
```
AtlasSolitaire/
├─ App/
│  └─ AtlasSolitaireApp.swift
├─ Sources/
│  ├─ Models/
│  │  ├─ Card.swift
│  │  ├─ Group.swift
│  │  ├─ Deck.swift
│  │  └─ GameState.swift
│  ├─ GameEngine/
│  │  ├─ GameEngine.swift
│  │  └─ Rules.swift
│  ├─ ViewModels/
│  │  └─ GameViewModel.swift
│  ├─ Views/
│  │  ├─ CardView.swift
│  │  ├─ StockView.swift
│  │  ├─ WasteView.swift
│  │  ├─ FoundationView.swift
│  │  ├─ TableauView.swift
│  │  ├─ GameView.swift
│  │  ├─ WinView.swift
│  │  └─ MenuView.swift
│  ├─ Services/
│  │  ├─ PersistenceManager.swift
│  │  ├─ DeckManager.swift
│  │  ├─ AudioManager.swift
│  │  └─ HapticManager.swift
│  └─ Utils/
│     └─ Extensions.swift
├─ Data/
│  ├─ groups/
│  │  ├─ europe_countries_01.json
│  │  ├─ island_nations_01.json
│  │  ├─ us_states_01.json
│  │  ├─ national_capitals_01.json
│  │  └─ cities_in_uk_01.json
│  └─ decks/
│     └─ default_deck.json
├─ Assets/
│  └─ Sounds/
├─ Tests/
│  ├─ GameEngineTests.swift
│  └─ DeckManagerTests.swift
└─ PROJECT_SPEC.md
```

---

## 9 — Testing
- Unit tests for GameEngine rules: valid moves, invalid moves, reshuffle behavior, group completion and clearing, win detection.
- Integration tests for persistence: save/load state returns identical game snapshot.
- UI tests for critical flows: draw from stock, drag/drop, reshuffle, clear group, win screen.

---

## 10 — Migration to API (future)
DeckManager should treat local JSON as a pluggable data source. Define a protocol:

```swift
protocol GroupDataSource {
  func loadAllGroups() -> [Group]
  func loadDeck(id: String) -> Deck
}
```

Implement `LocalJSONDataSource` and later `RemoteAPIDataSource` that conforms to the protocol.
Keep models Codable and API-friendly.

---

## 11 — Non-Functional / UX Notes
- Keep UI minimal and calm — clean card face with large labels; subtle background map texture would be optional later.
- Performance: prioritize smooth animations; precompute card positions for fast rendering.
- Analytics: optional; if later added keep privacy in mind (no PII).

---

## 12 — Example Small JSON Set (for quick local testing)
See `Data/groups/` — 5 unique groups provided (europe_countries_01, island_nations_01, us_states_01, national_capitals_01, cities_in_uk_01), each with base + 5 partners.

**Note:** `london` appears as a partner in both `national_capitals_01` and `cities_in_uk_01`. Card IDs are scoped at runtime by prefixing with `groupId` (e.g. `cities_in_uk_01_london`) to ensure global uniqueness. The JSON `id` field is the local, display-friendly identifier.

**Note:** The original sample data included `us_states_01` twice with identical content. The duplicate has been removed.

---

## 13 — Acceptance Criteria
- App runs on iPhone & iPad (portrait), deals randomized rounds from JSON.
- All piles function as specified; unlimited reshuffle exists and works.
- Base/partner rules enforced; group completion clears group and frees foundation slot.
- State persists and restores exactly.
- Win screen displays when all groups cleared with Play Again / Return to Menu options.
- All interactions expose hooks for animations/haptics/sounds.
