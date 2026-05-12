# Changelog

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
