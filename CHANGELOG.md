# Changelog

## 1.1.0

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

## 1.0.0

- Initial release
- Tracks Midnight profession knowledge treasures for all 11 professions
- Filters treasures to your character's active professions
- Nearest-neighbor routing with 2-opt optimization
- Portal suggestions when traveling between zones
- Darkmoon Faire knowledge quest guide
- TomTom waypoint integration
- Minimap button via LibDBIcon
- Test mode for previewing any profession combination
