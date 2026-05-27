PKT = PKT or {}
PKT.testMode = false
PKT.testProfs = {}
local format = string.format
local huge = math.huge
local PKT_TAG    = "|cff00ccff[PKT]|r"
local PKT_TAG_OK = "|cff00ff00[PKT]|r"
local C_YELLOW   = "|cffffff00"
local C_GRAY     = "|cffaaaaaa"
local C_ORANGE   = "|cffff9900"
local C_RED      = "|cffff4444"
local C_GREEN    = "|cff00ff00"
local C_GOLD     = "|cffFFDD44"
local C_END      = "|r"
local currentWaypointUID
local currentIndex = 0
local currentNativeMapID, currentNativeX, currentNativeY
local routeList = {}
local activeProfIDs = {}
local loginStarted = false
local autoShown = false
local inWorld = false
local questSettleTimer = nil
local JumpToNearestInZone
local function HasProfession(skillLineID)
    if PKT.testMode then return PKT.testProfs[skillLineID] == true end
    local info = C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
    if info and info.skillLevel and info.skillLevel > 0 then return true end
    local baseID       = PKT.PROF_BASE and PKT.PROF_BASE[skillLineID]
    local parentID     = info and info.professionID
    local localizedName = info and info.professionName
    local englishName   = PKT.PROF_NAMES[skillLineID]
    local slots = { GetProfessions() }
    for i = 1, select("#", GetProfessions()) do
        local idx = slots[i]
        if idx then
            local name, _, _, _, _, _, lineID = GetProfessionInfo(idx)
            if name then
                if lineID == skillLineID then return true end
                if baseID and lineID == baseID then return true end
                if parentID and lineID == parentID then return true end
                if localizedName and name == localizedName then return true end
                if name == englishName then return true end
            end
        end
    end
    return false
end
local function GetPlayerZoneAndPos()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return nil, 0.5, 0.5 end
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if pos then return mapID, pos.x, pos.y end
    return mapID, 0.5, 0.5
end
local function GetZoneGroup(mapID)
    if not PKT.ZONE_GROUPS then return { mapID } end
    for _, group in ipairs(PKT.ZONE_GROUPS) do
        for _, id in ipairs(group) do
            if id == mapID then return group end
        end
    end
    return { mapID }
end
local function GetZoneGroupSet(mapID)
    local set = {}
    for _, id in ipairs(GetZoneGroup(mapID)) do set[id] = true end
    return set
end
PKT.GetZoneGroupSet = GetZoneGroupSet
local function DistSq(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return dx * dx + dy * dy
end
local function IsLooted(treasure)
    return C_QuestLog.IsQuestFlaggedCompleted(treasure.quest)
end
PKT.IsLooted = IsLooted
local function CountRemaining(list)
    local n = 0
    for _, t in ipairs(list) do
        if not IsLooted(t) then n = n + 1 end
    end
    return n
end
PKT.CountRemaining = CountRemaining
local function TwoOpt(route)
    local n = #route
    if n < 4 then return end
    local improved = true
    while improved do
        improved = false
        for i = 1, n - 2 do
            for j = i + 2, n - 1 do
                local a, b = route[i], route[i + 1]
                local c, d = route[j], route[j + 1]
                local before = DistSq(a.x, a.y, b.x, b.y) + DistSq(c.x, c.y, d.x, d.y)
                local after  = DistSq(a.x, a.y, c.x, c.y) + DistSq(b.x, b.y, d.x, d.y)
                if after < before - 1e-9 then
                    local left, right = i + 1, j
                    while left < right do
                        route[left], route[right] = route[right], route[left]
                        left = left + 1
                        right = right - 1
                    end
                    improved = true
                end
            end
        end
    end
end
local function NearestNeighborSort(treasures, startX, startY)
    local visited = {}
    local looted = {}
    local unvisited = 0
    for i, t in ipairs(treasures) do
        if IsLooted(t) then
            looted[#looted + 1] = t
        else
            unvisited = unvisited + 1
        end
    end
    local sorted = {}
    local cx, cy = startX, startY
    while unvisited > 0 do
        local bestIdx, bestDist = nil, huge
        for i, t in ipairs(treasures) do
            if not visited[i] and not IsLooted(t) then
                local d = DistSq(cx, cy, t.x, t.y)
                if d < bestDist then bestDist = d; bestIdx = i end
            end
        end
        if not bestIdx then break end
        visited[bestIdx] = true
        unvisited = unvisited - 1
        local best = treasures[bestIdx]
        sorted[#sorted + 1] = best
        cx, cy = best.x, best.y
    end
    TwoOpt(sorted)
    for _, t in ipairs(looted) do sorted[#sorted + 1] = t end
    return sorted
end
function PKT.GetManualProfs()
    if PKT_CharVars and PKT_CharVars.manualProfs then return PKT_CharVars.manualProfs end
    return {}
end
function PKT.SetManualProf(profID, on)
    PKT_CharVars = PKT_CharVars or {}
    PKT_CharVars.manualProfs = PKT_CharVars.manualProfs or {}
    PKT_CharVars.manualProfs[profID] = on or nil
end
function PKT.HasManualProfs()
    return next(PKT.GetManualProfs()) ~= nil
end
local function GetActiveProfSet()
    if not PKT.testMode then
        local manualSet = {}
        for profID, on in pairs(PKT.GetManualProfs()) do
            if on then manualSet[profID] = true end
        end
        if next(manualSet) then return manualSet end
    end
    local set = {}
    for profID in pairs(PKT.PROF_NAMES) do
        if HasProfession(profID) then set[profID] = true end
    end
    return set
end
PKT.GetActiveProfSet = GetActiveProfSet
local function BuildRoute()
    routeList = {}
    activeProfIDs = GetActiveProfSet()
    local playerMapID, playerX, playerY = GetPlayerZoneAndPos()
    local playerZoneID = playerMapID
    if playerMapID then
        local group = GetZoneGroup(playerMapID)
        local orderSet = {}
        for _, id in ipairs(PKT.ZONE_ORDER) do orderSet[id] = true end
        for _, id in ipairs(group) do
            if orderSet[id] then playerZoneID = id; break end
        end
    end
    local byZone = {}
    for profID in pairs(activeProfIDs) do
        local treasures = PKT.TREASURES[profID]
        if treasures then
            for _, t in ipairs(treasures) do
                if not byZone[t.mapID] then byZone[t.mapID] = {} end
                byZone[t.mapID][#byZone[t.mapID] + 1] = t
            end
        end
    end
    local currentOrderIdx = 0
    for i, mapID in ipairs(PKT.ZONE_ORDER) do
        if mapID == playerZoneID then currentOrderIdx = i; break end
    end
    local zoneOrder = {}
    if playerZoneID and byZone[playerZoneID] then
        zoneOrder[#zoneOrder + 1] = playerZoneID
    end
    if currentOrderIdx > 0 then
        for i = currentOrderIdx + 1, #PKT.ZONE_ORDER do
            local mapID = PKT.ZONE_ORDER[i]
            if mapID ~= playerZoneID and byZone[mapID] then zoneOrder[#zoneOrder + 1] = mapID end
        end
        for i = 1, currentOrderIdx - 1 do
            local mapID = PKT.ZONE_ORDER[i]
            if mapID ~= playerZoneID and byZone[mapID] then zoneOrder[#zoneOrder + 1] = mapID end
        end
    else
        for _, mapID in ipairs(PKT.ZONE_ORDER) do
            if mapID ~= playerZoneID and byZone[mapID] then zoneOrder[#zoneOrder + 1] = mapID end
        end
    end
    for i, mapID in ipairs(zoneOrder) do
        if byZone[mapID] then
            local sameMap = (mapID == playerMapID)
            local startX = sameMap and playerX or 0
            local startY = sameMap and playerY or 0
            local sorted = NearestNeighborSort(byZone[mapID], startX, startY)
            for _, t in ipairs(sorted) do routeList[#routeList + 1] = t end
        end
    end
end
local function FindNextIncomplete(startIdx)
    for i = startIdx, #routeList do
        if not IsLooted(routeList[i]) then return i end
    end
end
local function FindPrevIncomplete(startIdx)
    for i = startIdx, 1, -1 do
        if not IsLooted(routeList[i]) then return i end
    end
end
local function GetWaypointSystem()
    return PKT_SavedVars and PKT_SavedVars.waypointSystem or "both"
end
PKT.GetWaypointSystem = GetWaypointSystem
local function SetNativeWaypoint(mapID, x, y)
    local sys = GetWaypointSystem()
    if sys == "tomtom" or sys == "none" then return false end
    if not C_Map.SetUserWaypoint or not UiMapPoint then return false end
    local ok = pcall(function()
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromVector2D(mapID, CreateVector2D(x, y)))
        if C_SuperTrack then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
    end)
    if ok then
        currentNativeMapID, currentNativeX, currentNativeY = mapID, x, y
    end
    return ok
end
local function ClearCurrentWaypoint()
    if C_Map.ClearUserWaypoint then C_Map.ClearUserWaypoint() end
    if currentWaypointUID and TomTom then
        TomTom:RemoveWaypoint(currentWaypointUID)
        currentWaypointUID = nil
    end
end
local function AddTomTomWaypoint(mapID, x, y, title)
    if not TomTom then return end
    local sys = GetWaypointSystem()
    if sys == "native" or sys == "none" then return end
    currentWaypointUID = TomTom:AddWaypoint(mapID, x, y, {
        title = title,
        from = "ProfessionKnowledgeTreasures",
        persistent = false, minimap = true, world = true, crazy = true,
    })
end
local function SetWaypointAt(index)
    ClearCurrentWaypoint()
    local t = routeList[index]
    if not t then return end
    currentIndex = index
    local playerMapID = C_Map.GetBestMapForUnit("player")
    local playerGroupSet = GetZoneGroupSet(playerMapID)
    local portal = not playerGroupSet[t.mapID] and PKT.GetPortalSuggestion(playerMapID, t.mapID)
    if portal then
        local nativeOk = SetNativeWaypoint(portal.mapID, portal.x, portal.y)
        AddTomTomWaypoint(portal.mapID, portal.x, portal.y, format("[PKT] %s", portal.name))
        print(format(PKT_TAG .. " Take " .. C_ORANGE .. "%s" .. C_END .. " (%.1f, %.1f) \226\134\146 " .. C_YELLOW .. "%s" .. C_END .. " in " .. C_GRAY .. "%s" .. C_END,
            portal.name, portal.x * 100, portal.y * 100, t.name, PKT.ZONE_NAMES[t.mapID] or "?"))
        if not nativeOk and not TomTom then
            print(format(PKT_TAG .. " " .. C_RED .. "Waypoint unavailable" .. C_END .. " \226\128\148 portal is at " .. C_YELLOW .. "%.1f, %.1f" .. C_END .. " on the %s map",
                portal.x * 100, portal.y * 100, PKT.ZONE_NAMES[portal.mapID] or "?"))
        end
    else
        SetNativeWaypoint(t.mapID, t.x, t.y)
        AddTomTomWaypoint(t.mapID, t.x, t.y, format("[PKT] %s", t.name))
        local zoneName = PKT.ZONE_NAMES[t.mapID] or "Unknown"
        print(format(PKT_TAG .. " Next: " .. C_YELLOW .. "%s" .. C_END .. " in " .. C_GRAY .. "%s" .. C_END .. " (%.1f, %.1f)%s",
            t.name, zoneName, t.x * 100, t.y * 100,
            t.notes and (C_ORANGE .. "  [" .. t.notes .. "]" .. C_END) or ""))
    end
    PKT.UpdateUI()
end
local autoAdvancePending = false
local function CheckAutoAdvance()
    if autoAdvancePending then return end
    if #routeList == 0 then
        PKT.UpdateUI()
        return
    end
    if CountRemaining(routeList) == 0 then
        if currentIndex ~= 0 then
            ClearCurrentWaypoint()
            currentIndex = 0
            print(PKT_TAG_OK .. " All profession knowledge treasures collected! Grats!")
        end
        PKT.UpdateUI()
        if autoShown and PKT.HideUI then PKT.HideUI() end
        autoShown = false
        return
    end
    if currentIndex == 0 then
        PKT.UpdateUI()
        return
    end
    local current = routeList[currentIndex]
    if current and not IsLooted(current) then
        PKT.UpdateUI()
        return
    end
    if not JumpToNearestInZone() then
        local idx = FindNextIncomplete(1)
        if idx then SetWaypointAt(idx) end
    end
end
local function ToWorldPos(mapID, x, y)
    if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
    local ok, continentID, worldPos = pcall(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(x, y))
    if ok and worldPos then return continentID, worldPos.x, worldPos.y end
    return nil
end
JumpToNearestInZone = function()
    local playerMapID, playerX, playerY = GetPlayerZoneAndPos()
    if not playerMapID or #routeList == 0 then return false end
    local groupSet = GetZoneGroupSet(playerMapID)
    local pcont, pwx, pwy = ToWorldPos(playerMapID, playerX, playerY)
    local bestIdx, bestDist = nil, huge
    for i, t in ipairs(routeList) do
        if groupSet[t.mapID] and not IsLooted(t) then
            local d
            if pcont then
                local tc, twx, twy = ToWorldPos(t.mapID, t.x, t.y)
                if tc == pcont then d = DistSq(pwx, pwy, twx, twy) end
            elseif t.mapID == playerMapID then
                d = DistSq(playerX, playerY, t.x, t.y)
            end
            if d and d < bestDist then bestDist = d; bestIdx = i end
        end
    end
    if not bestIdx then
        for i, t in ipairs(routeList) do
            if groupSet[t.mapID] and not IsLooted(t) then bestIdx = i; break end
        end
    end
    if bestIdx then SetWaypointAt(bestIdx); return true end
    return false
end
PKT.JumpToNearestInZone = JumpToNearestInZone
local function IsPortalUnlocked(portal)
    if not portal.unlockQuest then return true end
    return C_QuestLog.IsQuestFlaggedCompleted(portal.unlockQuest)
end
local function IsFlyable(fromMapID, toMapID)
    if not PKT.ZONE_FLYABLE then return false end
    for _, pair in ipairs(PKT.ZONE_FLYABLE) do
        if (pair[1] == fromMapID and pair[2] == toMapID) or
           (pair[2] == fromMapID and pair[1] == toMapID) then
            return true
        end
    end
    return false
end
local function FindDirectPortal(fromSet, toSet)
    for _, portal in ipairs(PKT.PORTALS) do
        if fromSet[portal.mapID] and toSet[portal.dest] and IsPortalUnlocked(portal) then
            return portal
        end
    end
end
local function FindHubPortal(fromGroup, fromSet, toSet, toMapID, fromMapID, px, py)
    if not PKT.ZONE_TRANSIT then return nil end
    local hubMapID
    for _, id in ipairs(fromGroup) do
        if PKT.ZONE_TRANSIT[id] then hubMapID = PKT.ZONE_TRANSIT[id]; break end
    end
    if not hubMapID then return nil end
    local hubGroup = GetZoneGroup(hubMapID)
    local hubSet = GetZoneGroupSet(hubMapID)
    local hubCanReach = false
    for _, portal in ipairs(PKT.PORTALS) do
        if hubSet[portal.mapID] and toSet[portal.dest] and IsPortalUnlocked(portal) then
            hubCanReach = true; break
        end
    end
    if not hubCanReach then
        for _, id in ipairs(hubGroup) do
            if IsFlyable(id, toMapID) then hubCanReach = true; break end
        end
    end
    if hubCanReach then
        local pcont, pwx, pwy = ToWorldPos(fromMapID, px, py)
        local best, bestDist, firstEligible = nil, huge, nil
        for _, portal in ipairs(PKT.PORTALS) do
            if fromSet[portal.mapID] and hubSet[portal.dest] and IsPortalUnlocked(portal) then
                firstEligible = firstEligible or portal
                local d
                if pcont then
                    local tc, twx, twy = ToWorldPos(portal.mapID, portal.x, portal.y)
                    if tc == pcont then d = DistSq(pwx, pwy, twx, twy) end
                elseif portal.mapID == fromMapID then
                    d = DistSq(px, py, portal.x, portal.y)
                end
                if d and d < bestDist then bestDist = d; best = portal end
            end
        end
        best = best or firstEligible
        if best then return best end
    end
    return FindDirectPortal(hubSet, toSet)
end
function PKT.GetPortalSuggestion(fromMapID, toMapID)
    if not fromMapID or not toMapID then return nil end
    local fromGroup = GetZoneGroup(fromMapID)
    local fromSet = GetZoneGroupSet(fromMapID)
    local toSet = GetZoneGroupSet(toMapID)
    if toSet[fromMapID] then return nil end
    if IsFlyable(fromMapID, toMapID) then return nil end
    local direct = FindDirectPortal(fromSet, toSet)
    if direct then return direct end
    local _, px, py = GetPlayerZoneAndPos()
    return FindHubPortal(fromGroup, fromSet, toSet, toMapID, fromMapID, px, py)
end
function PKT.GetCurrent()
    return routeList[currentIndex], currentIndex, #routeList
end
function PKT.GetRouteList()
    return routeList
end
function PKT.GetProfBreakdown()
    local result = {}
    for profID in pairs(activeProfIDs) do
        local treasures = PKT.TREASURES[profID]
        local remaining, total = 0, treasures and #treasures or 0
        if treasures then
            for _, t in ipairs(treasures) do
                if not IsLooted(t) then remaining = remaining + 1 end
            end
        end
        result[#result + 1] = { name = PKT.PROF_NAMES[profID], remaining = remaining, total = total }
    end
    table.sort(result, function(a, b) return a.name < b.name end)
    return result
end
function PKT.GoNext()
    local idx = FindNextIncomplete(currentIndex + 1)
    if idx then SetWaypointAt(idx)
    else print(PKT_TAG .. " No more incomplete treasures ahead.") end
end
function PKT.GoPrev()
    local idx = FindPrevIncomplete(currentIndex - 1)
    if idx then SetWaypointAt(idx)
    else print(PKT_TAG .. " No more incomplete treasures before this one.") end
end
function PKT.GoFirst()
    local idx = FindNextIncomplete(1)
    if idx then SetWaypointAt(idx)
    else print(PKT_TAG_OK .. " All done!") end
end
function PKT.StopTracking()
    ClearCurrentWaypoint()
    currentIndex = 0
    currentNativeMapID = nil
    PKT.UpdateUI()
end
function PKT.OnWaypointSystemChanged(newSystem)
    if newSystem == "native" or newSystem == "none" then
        if currentWaypointUID and TomTom then
            TomTom:RemoveWaypoint(currentWaypointUID)
            currentWaypointUID = nil
        end
    end
    if newSystem == "tomtom" or newSystem == "none" then
        if C_Map.ClearUserWaypoint then C_Map.ClearUserWaypoint() end
        currentNativeMapID = nil
    end
    if currentIndex > 0 and newSystem ~= "none" then
        local t = routeList[currentIndex]
        if t and not IsLooted(t) then
            SetWaypointAt(currentIndex)
        end
    end
end
function PKT.GoNearest()
    if not JumpToNearestInZone() then PKT.GoFirst() end
end
function PKT.GetActiveDMFProfs()
    if not PKT.DMF_QUESTS then return {} end
    local result = {}
    for profID in pairs(PKT.PROF_NAMES) do
        if HasProfession(profID) and PKT.DMF_QUESTS[profID] then
            local q = PKT.DMF_QUESTS[profID]
            local done = C_QuestLog.IsQuestFlaggedCompleted(q.questID)
            result[#result + 1] = { profID = profID, name = PKT.PROF_NAMES[profID], quest = q, done = done }
        end
    end
    table.sort(result, function(a, b) return a.name < b.name end)
    return result
end
local function StartRoute()
    BuildRoute()
    local remaining = CountRemaining(routeList)
    if remaining > 0 then
        if not JumpToNearestInZone() then
            local idx = FindNextIncomplete(1)
            if idx then SetWaypointAt(idx) end
        end
    end
    return remaining
end
local function ProfSetDiffers(newSet)
    for id in pairs(newSet) do if not activeProfIDs[id] then return true end end
    for id in pairs(activeProfIDs) do if not newSet[id] then return true end end
    return false
end
local function RefreshProfessions()
    if not loginStarted or IsInInstance() then return end
    local newSet = GetActiveProfSet()
    if not ProfSetDiffers(newSet) then return end
    ClearCurrentWaypoint()
    currentIndex = 0
    local remaining = StartRoute()
    if remaining > 0 and not autoShown then
        autoShown = true
        print(format(PKT_TAG .. " %d profession knowledge treasure(s) remaining.", remaining))
        PKT.ShowUI()
    end
    PKT.UpdateUI()
end
PKT.RefreshProfessions = RefreshProfessions
function PKT.Reload()
    local remaining = StartRoute()
    if remaining == 0 then
        PKT.UpdateUI()
        print(PKT_TAG_OK .. " All profession knowledge treasures already collected!")
        return
    end
    print(format(PKT_TAG .. " Route built: " .. C_YELLOW .. "%d" .. C_END .. " remaining of " .. C_GRAY .. "%d" .. C_END .. " total.",
        remaining, #routeList))
end
SLASH_PKT1 = "/pkt"
SLASH_PKT2 = "/profknowledge"
SlashCmdList["PKT"] = function(msg)
    local cmd = strtrim(msg):lower()
    if     cmd == "next"    then PKT.GoNext()
    elseif cmd == "prev"    then PKT.GoPrev()
    elseif cmd == "first"   then PKT.GoFirst()
    elseif cmd == "nearest" then PKT.GoNearest()
    elseif cmd == "reload"  then PKT.Reload()
    elseif cmd == "profs" or cmd == "professions" then PKT.ToggleManualProfUI()
    elseif cmd == "dmf"     then PKT.ToggleDMFUI()
    elseif cmd == "test"    then
        PKT.testMode = not PKT.testMode
        PKT.testProfs = {}
        if PKT.testMode then
            for profID in pairs(PKT.PROF_NAMES) do PKT.testProfs[profID] = true end
            print(PKT_TAG .. " " .. C_RED .. "Test mode ON" .. C_END .. " \226\128\148 choose professions in the picker.")
            if PKT.ShowTestProfUI then PKT.ShowTestProfUI() end
        else
            if PKT.HideTestProfUI then PKT.HideTestProfUI() end
            print(PKT_TAG .. " Test mode off.")
        end
        PKT.Reload()
        PKT.UpdateUI()
    elseif cmd == "debug"   then
        print(PKT_TAG .. " Profession detection debug:")
        print("  " .. C_GRAY .. "Character profession slots:" .. C_END)
        local slots = { GetProfessions() }
        for i = 1, select("#", GetProfessions()) do
            local idx = slots[i]
            if idx then
                local name, _, skillLevel, _, _, _, lineID = GetProfessionInfo(idx)
                if name then
                    print(format("    %s (lineID=%d, skill=%d)", name, lineID or 0, skillLevel or 0))
                end
            end
        end
        print("  " .. C_GRAY .. "Tracked professions (actual detection result):" .. C_END)
        for profID, profName in pairs(PKT.PROF_NAMES) do
            local info = C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID(profID)
            print(format("    %s (ID=%d): %s%s", profName, profID,
                HasProfession(profID) and (C_GREEN .. "DETECTED" .. C_END) or (C_RED .. "no" .. C_END),
                info and format(C_GRAY .. " [lvl %d, parentID %d]" .. C_END, info.skillLevel or -1, info.professionID or 0) or ""))
        end
    elseif cmd == "settings" then
        PKT.ToggleSettingsUI()
    elseif cmd == "mapid"   then
        local mapID = C_Map.GetBestMapForUnit("player")
        local mapInfo = mapID and C_Map.GetMapInfo(mapID)
        print(format(PKT_TAG .. " Current mapID: " .. C_YELLOW .. "%d" .. C_END .. " (%s)", mapID or 0, mapInfo and mapInfo.name or "?"))
    elseif cmd == "list"    then
        local count = 0
        for i, t in ipairs(routeList) do
            if not IsLooted(t) then
                count = count + 1
                local zoneName = PKT.ZONE_NAMES[t.mapID] or "?"
                print(format(PKT_TAG .. " %d. " .. C_YELLOW .. "%s" .. C_END .. " - %s (%.1f, %.1f)",
                    i, t.name, zoneName, t.x * 100, t.y * 100))
            end
        end
        if count == 0 then print(PKT_TAG_OK .. " All done!") end
    else
        PKT.ToggleUI()
    end
end
local dmfAutoOpened = false
local function IsAtDarkmoonFaire()
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID == PKT.DMF_MAP_ID then return true end
    return GetRealZoneText() == "Darkmoon Island"
end
local function CheckDMFZone()
    if IsAtDarkmoonFaire() then
        if not PKT.IsDMFShown() then
            dmfAutoOpened = true
            PKT.ShowDMFUI()
            print(PKT_TAG .. " " .. C_GOLD .. "Darkmoon Faire" .. C_END .. " detected \226\128\148 showing knowledge quests.")
        end
    else
        if dmfAutoOpened and PKT.IsDMFShown() then PKT.HideDMFUI() end
        dmfAutoOpened = false
    end
end
local DoLoginStart
local function ScheduleLoginStart()
    if loginStarted or not inWorld then return end
    if questSettleTimer then questSettleTimer:Cancel() end
    questSettleTimer = C_Timer.NewTimer(2, function()
        questSettleTimer = nil
        if DoLoginStart then DoLoginStart() end
    end)
end
DoLoginStart = function()
    if loginStarted then return end
    loginStarted = true
    if questSettleTimer then questSettleTimer:Cancel(); questSettleTimer = nil end
    local remaining = StartRoute()
    if remaining > 0 then
        autoShown = true
        print(format(PKT_TAG .. " %d profession knowledge treasure(s) remaining.", remaining))
        PKT.ShowUI()
    end
    PKT.UpdateUI()
    CheckDMFZone()
    C_Timer.After(3, RefreshProfessions)
    C_Timer.After(6, RefreshProfessions)
    C_Timer.After(10, RefreshProfessions)
    C_Timer.After(11, function()
        if loginStarted and next(activeProfIDs) == nil and PKT.ShowManualProfUI then
            print(PKT_TAG .. " " .. C_ORANGE .. "Couldn't detect your professions" .. C_END .. " \226\128\148 please pick them manually.")
            PKT.ShowManualProfUI()
        end
    end)
    C_Timer.NewTicker(3, CheckAutoAdvance)
end
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("SKILL_LINES_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
eventFrame:RegisterEvent("LOOT_CLOSED")
eventFrame:RegisterEvent("SUPER_TRACKING_CHANGED")
eventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_LOGIN" then
        PKT.InitUI()
    elseif event == "PLAYER_ENTERING_WORLD" then
        inWorld = true
        C_Timer.After(15, function()
            if not loginStarted then DoLoginStart() end
        end)
        ScheduleLoginStart()
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        C_Timer.After(1.5, function()
            local inInstance = IsInInstance()
            CheckDMFZone()
            if inInstance then return end
            if currentIndex > 0 and #routeList > 0 then
                local playerMapID = C_Map.GetBestMapForUnit("player")
                local groupSet = GetZoneGroupSet(playerMapID)
                local hasHere = false
                for _, t in ipairs(routeList) do
                    if groupSet[t.mapID] and not IsLooted(t) then hasHere = true; break end
                end
                if hasHere then
                    local currentTarget = routeList[currentIndex]
                    local targetSet = currentTarget and GetZoneGroupSet(currentTarget.mapID) or {}
                    if not currentTarget or targetSet[playerMapID] then
                        local zoneName = PKT.ZONE_NAMES[playerMapID] or "this zone"
                        print(format(PKT_TAG .. " Entered %s \226\128\148 jumping to nearest treasure.", zoneName))
                        JumpToNearestInZone()
                    else
                        PKT.UpdateUI()
                    end
                else
                    local idx = FindNextIncomplete(1)
                    if idx then SetWaypointAt(idx) end
                end
            end
        end)
    elseif event == "SKILL_LINES_CHANGED" then
        RefreshProfessions()
    elseif event == "UNIT_QUEST_LOG_CHANGED" then
        if unit == "player" then CheckAutoAdvance() end
    elseif event == "QUEST_LOG_UPDATE" then
        if not loginStarted then
            ScheduleLoginStart()
        else
            CheckAutoAdvance()
        end
    elseif event == "LOOT_CLOSED" then
        autoAdvancePending = true
        C_Timer.After(0.8, function()
            autoAdvancePending = false
            CheckAutoAdvance()
        end)
    elseif event == "SUPER_TRACKING_CHANGED" then
        if currentIndex > 0 and currentNativeMapID then
            C_Timer.After(0.2, function()
                if currentIndex > 0 and currentNativeMapID then
                    local current = routeList[currentIndex]
                    if current and not IsLooted(current) then
                        SetNativeWaypoint(currentNativeMapID, currentNativeX, currentNativeY)
                    end
                end
            end)
        end
    end
end)
