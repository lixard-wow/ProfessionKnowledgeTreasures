# Changelog

## Version 1.3.0

### New

- **Completely redesigned look.** Every window has been rebuilt from scratch with custom artwork and fonts, and no longer uses the game's default frames.
- **Choose your style.** Three looks to pick from: **Artisan's Ledger** (warm walnut and brass), **Workbench** (flat and modern, with a color for each profession), and **Lixard Classic** (clean black, grey and gold). A picker appears the first time you log in. You can change it anytime from **Settings** or with **`/pkt theme`**.
- **Minimize button.** Collapse the tracker to a slim bar showing your next treasure while you travel from point to point. Expand it anytime, or toggle it with **`/pkt mini`**.
- **Darkmoon Faire minimize button.** Collapse the Faire window to a slim bar that shows one quest step at a time. Use the arrow buttons to move to the next step (or back to the previous one) while you work through the quest. Stepping past the last step moves on to your next profession's quest.
- Added an icon for each profession.

### Changed

- The Darkmoon Faire window, Settings, and both profession pickers have been redesigned to match your chosen look.
- Routes now follow real distances across the map, and each zone's route starts where the previous zone's ended, giving shorter paths between treasures.
- The tracker window now resizes to fit long treasure notes.

### Fixed

- PKT no longer takes over your quest tracking. If you track a quest yourself, it stays tracked.
- The **None (map pin only)** waypoint option now places a map pin, as described.
- PKT no longer removes a map pin that you placed yourself.
- Fixed route ordering sometimes choosing a longer path between treasures.
- Fixed long treasure notes overlapping other text in the tracker.
- Fixed the Darkmoon Faire window not opening automatically when you arrive at the Faire, including on non-English game clients.
- Entering a zone with no treasures no longer restarts your route or fills your chat with messages.
- Reduced background activity while you're not tracking a route.
- Fixed a possible conflict with other addons that use the same internal name.
- Corrected the spelling of Har'athir in treasure notes.
- Fixed the map location and notes for the two Zul'Aman treasures that share a spot (Vial of Zul'Aman Oddities and Loa-Blessed Dust). Both are now marked at the same cart, and each note says so.

## Version 1.2.2

### Updated

- Updated for **World of Warcraft Patch 12.0.7**.
- Reviewed for **Patch 12.1.0** compatibility. No issues are expected with the update. Support for new profession knowledge treasures will be added as they become available.

## Version 1.2.1

### New

- Added a **Manual Profession Picker**. If PKT can't detect your professions automatically, you can choose them yourself (up to 2 professions).
- Open the profession picker anytime with **`/pkt profs`** or from the **Settings** panel.
- Your profession selection is saved separately for each character.

### Fixed

- The tracker now only shows treasures for the professions your character actually knows.
- Fixed collected treasures sometimes being counted as missing, causing the tracker to appear when there was nothing left to collect.
- The tracker now closes automatically once all tracked treasures have been collected.
- Fixed profession detection for alts and non-English game clients.
- Fixed professions occasionally not being detected after logging in.
- Fixed the waypoint repeatedly bouncing between two treasures in the Voidstorm / Slayer's Rise area.
- Corrected the map location of a Zul'Aman treasure.

## Version 1.2.0

### New

- Added a Settings panel.
- Added waypoint system options.
- Added middle-click support for the minimap button.

### Fixed

- Fixed the direction arrow remaining active after closing the addon window.

## Version 1.1

### Improved

- Improved route optimization with smarter pathing.

### Fixed

- Fixed Herbalism detection.
- Fixed a portal waypoint issue.
- Corrected several treasure names and locations.

## Version 1.0

- Initial release.
- Automatically tracks profession knowledge treasures.
- Optimized treasure routing.
- Portal suggestions between zones.
- Built-in Darkmoon Faire profession guide.
- TomTom integration.
- Minimap button.
- Test mode.
