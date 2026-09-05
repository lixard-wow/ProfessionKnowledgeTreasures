# PROJECT

Consolidated internal working docs for Profession Knowledge Treasures (architecture/state, dev rules, TODO, issues, testing, and the dev changelog all live here in one file). CLAUDE.md and the root CHANGELOG.md remain separate — CLAUDE.md is auto-loaded by Claude Code, and CHANGELOG.md is a standard convention file external tools (CurseForge, GitHub releases) expect to find under that exact name.

## Table of Contents
- [Addon Context](#addon-context)
- [Dev Rules](#dev-rules)
- [TODO](#todo)
- [Issues](#issues)
- [Testing](#testing)
- [Changelog (Dev)](#changelog-dev)

---

## Addon Context

### Addon Identity
- Addon Name: Profession Knowledge Treasures (PKT)
- Primary Purpose: Tracks Midnight-era profession knowledge treasures filtered to the player's known professions, builds an optimized cross-zone collection route, and guides the player to each treasure via native/TomTom waypoints and portal/zone-transit suggestions.
- Expansion Target: Midnight-era client (Interface 120100, 120007, 120005)

### Core Features
- Automatic profession detection, with a manual profession picker fallback (saved per-character) when auto-detection fails
- Route building across zones using zone ordering plus nearest-neighbor + 2-opt route optimization
- Native waypoint and TomTom integration, with a configurable waypoint system (native / tomtom / both / none)
- Portal and zone-transit suggestions when the next treasure is in a different zone group (direct portal lookup, falling back to hub-portal routing)
- Auto-advance to the next treasure on loot/quest-log events, with periodic re-check ticker
- Darkmoon Faire profession knowledge quest tracker, auto-shown when the player is at the Faire
- Minimap button via LibDBIcon
- Test mode for simulating arbitrary profession sets
- Slash commands: `/pkt` and `/profknowledge` (next, prev, first, nearest, reload, profs, dmf, test, debug, settings, mapid, list)

### Architecture Overview
- `PKT_Data.lua` - static data tables: zone names/order/groups/flyable connections/transit hubs, portal definitions, profession name/base-ID tables, per-profession treasure location lists (`PKT.TREASURES`), Darkmoon Faire map ID and quest data
- `PKT_Main.lua` - core logic: profession detection (`HasProfession`, `GetActiveProfSet`), route building (`BuildRoute`, `NearestNeighborSort`, `TwoOpt`), waypoint management (native `C_Map` waypoints + TomTom), portal/transit-hub pathing (`GetPortalSuggestion`), auto-advance on loot/quest events (`CheckAutoAdvance`), Darkmoon Faire zone detection, the `/pkt` slash command handler, and the login/event lifecycle (`PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD`, `SKILL_LINES_CHANGED`, `ZONE_CHANGED_NEW_AREA`, quest/loot events, `SUPER_TRACKING_CHANGED`)
- `PKT_UI.lua` - all UI: main tracker frame + profession breakdown, Darkmoon Faire quest frame, Settings frame, Test Profession picker frame, Manual Profession picker frame
- `Libs/` - embedded third-party libraries (LibStub, CallbackHandler-1.0, LibDataBroker-1.1, LibDBIcon-1.0) - third-party, not linted/edited

### SavedVariables
- `PKT_SavedVars` (account-wide) - e.g. `waypointSystem` setting
- `PKT_CharVars` (per-character) - `manualProfs` (manual profession picker selections)

### Known Constraints
- None logged yet

### Known Issues
- None logged yet

### Current Focus
- Session initialization; no active task

### Notes for AI
- Do not guess APIs
- Do not expand scope
- Keep solutions minimal
- Follow CLAUDE.md and this file's Dev Rules section strictly

---

## Dev Rules

### Project Baseline
- WoW addon project
- Interface version: 120100, 120007, 120005
- Lua only
- No external libraries unless explicitly approved
- Prefer custom UI over Blizzard templates/assets

### Non-Negotiables
- No guessing on WoW APIs
- Verify uncertain API behavior before implementation
- Never do math on secret/protected values
- Never attempt to expose, infer, or bypass restricted values
- Respect combat lockdown and secure frame limitations
- Do not add hidden scope or unrelated cleanup

### Scope Control
- Do only what was requested
- Keep changes minimal and targeted
- Do not rewrite surrounding systems unless required for the task
- If a broader refactor would help, propose it instead of silently doing it

### Structure
- Keep files responsibility-focused
- Avoid duplicate helpers or duplicate implementations
- Reuse existing module boundaries where possible
- Prefer data-only extraction first
- Split growing files before they become unmanageable
- Do not create unnecessary conceptual layers

### Performance
- Event-driven first
- Avoid unnecessary OnUpdate usage
- Cache reused values
- Avoid repeated allocations in hot paths
- Gate disabled features so they stop doing work
- Use dirty/queued refreshes when appropriate instead of constant rebuilding

### SavedVariables
- Use one canonical SavedVariables table
- Keep defaults centralized
- Do not scatter persistence logic across unrelated files

### Localization
- All player-facing strings should be localized
- enUS is source of truth
- Avoid string concatenation for localized UI text
- Missing locale strings should be obvious during development

### UI / Layout
- Support different UI scales and resolutions
- Avoid clipping and zero-width layout states
- Avoid fragile offsets
- Prefer measured or bounded sizing for dynamic content
- Test layouts in narrow and wider frame states

### File and Docs Workflow
Project docs live in docs/PROJECT.md (a single consolidated file).

Maintain these sections when the workflow is active:
- TODO
- Issues
- Changelog (Dev)
- Testing

Definition of done includes:
- requested code change completed
- relevant docs updated
- obvious regressions checked
- completion marker printed in chat

### Required Pre-Flight Check
Before making changes, confirm:
- scope is clear
- solution is minimal
- no duplicate helper is being introduced
- localization rules are being followed
- event-driven approach is preferred
- debug/dev-only code stays isolated when applicable

### Completion Marker
When finishing a prompt or task, print:
PROMPT X COMPLETE

---

## TODO

### Active
- None yet

### Backlog
- None yet

### Completed
- Move finished items here and mark with prompt number/date if desired

---

## Issues

- None logged yet

---

## Testing

- None logged yet

---

## Changelog (Dev)

### Format
- PROMPT X
  - Intent:
  - Files changed:
  - Result:
  - Notes:

### Entries
- (none yet — this section grows as work happens)
