# Changelog

## 1.2.1

### Bug Fixes
- Fixed all 11 professions being tracked regardless of what the character actually knows — the tracker now correctly filters to your learned professions, so collected treasures show complete and the window no longer pops up on a finished character
- Login detection now waits for quest-completion data to finish syncing before deciding what's collected, preventing the tracker from appearing on a fully-cleared character
- Tracker now closes itself automatically once all treasures are confirmed collected, even if quest data finishes loading after login
- Fixed professions not being detected on alts when profession/skill data loads after login — PKT now re-scans as professions become available and rebuilds the route, instead of relying on a single early scan
- Fixed a profession in a later character slot being skipped when an earlier slot was empty
- Profession detection is now locale-proof — it matches by the base profession skill-line ID (a stable number, not text) as well as the game's own localized profession name, so it works on non-English clients. This fixes detection failing on alts of a non-English (e.g. German) client, where it previously only worked on the first character of a session
- `/pkt debug` now reports the actual detection result for each tracked profession
- Fixed the waypoint flipping back and forth between two treasures that sit on different maps within the same zone group (e.g. Pure Void Crystal in Voidstorm and Miniaturized Transport Skiff in Slayer's Rise). All "nearest" distance calculations — the next-treasure waypoint, the travel-portal suggestion, and the in-zone route ordering — now use world positions so distances are valid across maps in a group

### Improvements
- Added a manual profession picker: if PKT can't auto-detect your professions (or detects them wrong), open the picker and choose them by hand. A manual selection is saved per character and overrides auto-detection; press **Clear** to return to automatic. The picker opens automatically when nothing is detected, and you can open it anytime with `/pkt profs` or the **Select Manually** button in the Settings panel.

---

## 1.2.0

### Bug Fixes
- Fixed direction arrow remaining active after closing the addon window — closing now clears all waypoints

### Improvements
- Added Settings panel (gear icon beside the X button, or `/pkt settings`) to configure the waypoint system
- Waypoint system options: Native + TomTom (default), Native Only, TomTom Only, or None (map pin only)
- Minimap button now supports middle-click to open Settings
- TomTom users can now select "Native Only" or "None" to prevent PKT from interfering with TomTom's quest tracking arrow

---

## 1.1

### Bug Fixes
- Fixed Herbalism not being detected as an active profession
- Fixed portal waypoint appearing then immediately disappearing when routing between zones
- Fixed routing taking inefficient paths (backtracking) within a zone

### Data Corrections
- Corrected "Harvester's Sickle" (Zul'Aman) to **Sweeping Harvester's Scythe** with the correct quest ID
- Added missing **Harvester's Sickle** treasure in Harandar
- Corrected Mining **Star Metal Deposit** zone and coordinates
- Fixed spelling of Tailoring treasure **Particularly Enchanting Tablecloth**

### Improvements
- Route now uses nearest-neighbor + 2-opt optimization for better pathing within each zone
- Zone indicator in the tracker UI now correctly accounts for zone groups when checking nearby treasures

---

## 1.0

- Initial release
- Tracks Midnight profession knowledge treasures for all 11 professions
- Filters treasures to your character's active professions
- Nearest-neighbor routing with 2-opt optimization
- Portal suggestions when traveling between zones
- Darkmoon Faire knowledge quest guide
- TomTom waypoint integration
- Minimap button via LibDBIcon
- Test mode for previewing any profession combination
