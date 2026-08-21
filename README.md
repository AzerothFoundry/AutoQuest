# AutoQuest

A lightweight World of Warcraft 1.12 addon (Vanilla / Turtle WoW) that automates quest interactions.

Only stock 1.12 API is used. No dependency on ClassicAPI, Nampower, SuperWoW, or UnitXP_SP3.

## Features
- **Auto-Accept Quests**: Automatically accepts quests from NPC Gossip or Greeting windows.
- **Auto-Turn-In Quests**: Automatically turns in complete quests and selects the reward when there is only zero or one option.
- **OctoPawn Reward Picking**: When multiple rewards are offered, picks the choice with the best score for your current OctoPawn role stat weights (`/aq pawn`). Inactive unless OctoPawn is loaded.
- **Auto-Pick Reward**: Optionally pick the first reward even when multiple are offered (`/aq reward`). Off by default.
- **Smart Quest Scanning**: On a quest greeting, each active quest is scanned in turn so a non-completable quest no longer blocks a completable one from being turned in. Incomplete quests are skipped so the remaining quests still get processed.
- **Full Quest Log Guard**: If the quest log is full, acceptance is skipped with a warning instead of silently failing.
- **Shift-Key Bypass**: Hold **SHIFT** while interacting with an NPC to temporarily disable all automation.
- **Deferred Actions**: Accept/complete/turn-in calls run on the next UI frame so the quest window is fully settled, avoiding race conditions.
- **Slash Commands**:
  - `/aq toggle` - Toggle the entire addon on/off.
  - `/aq accept` - Toggle automatic quest acceptance.
  - `/aq turnin` - Toggle automatic quest turn-in.
  - `/aq reward` - Auto-pick the first reward when multiple rewards are offered.
  - `/aq pawn` - Pick the best reward using the current OctoPawn role stat weights (only when OctoPawn is loaded).

## OctoPawn integration
- AutoQuest detects OctoPawn at runtime by checking for `OctoPawnDB.weights`, `OctoPawn_ScoreTooltip`, and `OctoPawn_GetScanTooltip`. All calls are guarded, so the addon loads and runs normally when OctoPawn is absent.
- With `/aq pawn` enabled and multiple rewards offered, each choice is loaded into OctoPawn's scan tooltip and scored with `OctoPawn_ScoreTooltip` (which uses the player's active role weights). The highest-scoring choice is selected. Ties favor the first choice.
- Reward selection priority: OctoPawn best-score (when `/aq pawn` is on and OctoPawn is available) → first reward (when `/aq reward` is on) → manual selection.
- Requires an active role with weights set in OctoPawn; otherwise the feature stays dormant.

## Installation
1. Download the repository.
2. Extract the `AutoQuest` folder into your `Interface/AddOns` directory.
3. Ensure the folder name is exactly `AutoQuest`.

## API notes
- `GetGossipActiveQuests()` / `GetGossipAvailableQuests()` return `title, level` pairs per quest (2 values each) on 1.12. Active gossip quests are only the ones ready to turn in.
- Greeting active quests (`GetNumActiveQuests` / `SelectActiveQuest`) may be in-progress or completable; only `IsQuestCompletable()` distinguishes them, so the addon probes each one and skips the ones that are not ready.
- Reward choice items are read with the stock `GameTooltip:SetQuestItem("choice", i)` API and scored via OctoPawn's public `OctoPawn_ScoreTooltip`.