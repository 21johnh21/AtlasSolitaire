# Game Center Setup Guide

This document explains how to complete the Game Center integration for Atlas Solitaire.

## Overview

The app is now integrated with Game Center and includes:
- **2 Leaderboards**: Fastest Time and Fewest Moves
- **9 Achievements**: Various milestones for wins, streaks, and perfect games
- Automatic score submission when games are won
- Statistics tracking (total wins, win streaks)

## Required Setup Steps

### 1. Enable Game Center Capability in Xcode

1. Open the project in Xcode
2. Select the **AtlasSolitare** target
3. Go to the **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Game Center**
6. Ensure your Team is selected

### 2. Configure App Store Connect

You need to create the leaderboards and achievements in App Store Connect before they will work.

#### A. Leaderboards

Create these two leaderboards in App Store Connect:

**1. Fastest Completion Time**
- **Leaderboard ID**: `com.atlassolitaire.leaderboard.fastesttime`
- **Leaderboard Name**: "Fastest Time"
- **Score Format**: Time (Minutes, Seconds)
- **Sort Order**: Low to High (best scores)
- **Score Range**: 0 to 3600 (0 seconds to 1 hour)
- **Description**: "Complete all groups in the fastest time"

**2. Fewest Moves**
- **Leaderboard ID**: `com.atlassolitaire.leaderboard.fewestmoves`
- **Leaderboard Name**: "Fewest Moves"
- **Score Format**: Integer
- **Sort Order**: Low to High (best scores)
- **Score Range**: 0 to 1000
- **Description**: "Complete all groups with the fewest moves"

#### B. Achievements

Create these achievements in App Store Connect:

| Achievement ID | Name | Points | Description |
|---------------|------|--------|-------------|
| `com.atlassolitaire.achievement.firstwin` | First Victory | 5 | Win your first game |
| `com.atlassolitaire.achievement.speeddemon` | Speed Demon | 10 | Win a game in under 2 minutes |
| `com.atlassolitaire.achievement.efficient` | Efficient Player | 10 | Win a game in under 50 moves |
| `com.atlassolitaire.achievement.perfectgame` | Perfect Game | 25 | Win in under 1 minute AND under 40 moves |
| `com.atlassolitaire.achievement.winstreak5` | Streak Master | 15 | Win 5 games in a row |
| `com.atlassolitaire.achievement.winstreak10` | Unstoppable | 30 | Win 10 games in a row |
| `com.atlassolitaire.achievement.totalwins10` | Getting Started | 10 | Win 10 games total |
| `com.atlassolitaire.achievement.totalwins50` | Dedicated Player | 25 | Win 50 games total |
| `com.atlassolitaire.achievement.totalwins100` | Atlas Master | 50 | Win 100 games total |

### 3. Testing Game Center

#### Sandbox Testing

1. Create a sandbox tester account in App Store Connect:
   - Go to **Users and Access** > **Sandbox Testers**
   - Create a new tester account
2. On your test device:
   - Sign out of Game Center in Settings
   - Run the app
   - Sign in with your sandbox tester account when prompted
3. Play and win a game to test score submission
4. Tap the **Leaderboard** button on the main menu to view leaderboards

#### Production Testing

- Game Center features will be available once your app is approved and live on the App Store
- All leaderboards and achievements must be configured before submitting for review

## How It Works

### Authentication
- The app automatically authenticates with Game Center on launch
- Users will see a Game Center welcome banner if it's their first time
- Authentication status is tracked in `GameCenterManager.shared.isAuthenticated`

### Score Submission
- When a game is won, scores are automatically submitted to both leaderboards:
  - Time in seconds (faster is better)
  - Move count (fewer is better)
- Submission happens in `GameViewModel.handleWin()`

### Achievement Tracking
- Achievements are evaluated after each win based on:
  - Game completion time
  - Number of moves
  - Current win streak
  - Total wins
- Win streaks reset when the app is closed or a new game is started without winning

### Statistics
- Statistics are stored locally in `AppSettings`:
  - `totalWins`: Cumulative wins
  - `currentWinStreak`: Current consecutive wins
  - `bestWinStreak`: Best streak ever achieved

## Code References

### Key Files
- `GameCenterManager.swift` - Main Game Center service (authentication, leaderboards, achievements)
- `GameCenterView.swift` - SwiftUI wrapper for presenting Game Center UI
- `GameViewModel.swift` - Score submission and statistics tracking
- `GameState.swift` - Statistics storage in `AppSettings`

### Key Methods
- `GameCenterManager.authenticatePlayer()` - Authenticate with Game Center
- `GameCenterManager.submitGameResult()` - Submit scores to leaderboards
- `GameCenterManager.processGameWin()` - Check and unlock achievements
- `GameCenterManager.showLeaderboard()` - Display Game Center leaderboard UI
- `GameViewModel.handleWin()` - Called when game is won, triggers all Game Center updates

## Troubleshooting

### "Not Authenticated" Messages
- Ensure Game Center is enabled on the device (Settings > Game Center)
- Sign in with a valid Apple ID or sandbox tester account
- Check that the Game Center capability is enabled in Xcode

### Leaderboards/Achievements Not Showing
- Verify IDs in code match exactly what's in App Store Connect
- Ensure leaderboards/achievements are in "Ready to Submit" state in App Store Connect
- For sandbox testing, make sure you're signed in with a sandbox tester account

### Scores Not Submitting
- Check console logs for Game Center errors
- Verify network connectivity
- Ensure `isAuthenticated` is `true` before submission

## Future Enhancements

Potential additions for future versions:
- Compare scores with friends
- Weekly/monthly leaderboard variants
- More granular achievements (e.g., per deck type)
- Social sharing of achievements
- In-game achievement notifications with custom UI
