---@diagnostic disable: undefined-global
PKT = PKT or {}

local currentWaypointUID
local currentIndex = 0
local routeList = {}
local activeProfIDs = {}
local JumpToNearestInZone

local function HasProfession(skillLineID)
    local info = C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
    if info and info.skillLevel and info.skillLevel > 0 then return true end
    local slots = { GetProfessions() }
    for _, idx in ipairs(slots) do
        if idx then
            local _, _, _, _, _, _, lineID = GetProfessionInfo(idx)
            if lineID == skillLineID then return true end
            if info and info.parentProfessionID and info.parentProfessionID == lineID then return true end
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

local function DistSq(ax, ay, bx, by)
    return (ax - bx) ^ 2 + (ay - by) ^ 2
end

local function IsLooted(treasure)
    return C_QuestLog.IsQuestFlaggedCompleted(treasure.quest)
end
PKT.IsLooted = IsLooted

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
    local unlooted, looted = {}, {}
    for _, t in ipairs(treasures) do
        if IsLooted(t) then table.insert(looted, t)
        else table.insert(unlooted, t) end
    end
    local sorted = {}
    local cx, cy = startX, startY
    local exitX, exitY = startX, startY
    while #unlooted > 0 do
        local bestIdx, bestDist = 1, math.huge
        for i, t in ipairs(unlooted) do
            local d = DistSq(cx, cy, t.x, t.y)
            if d < bestDist then bestDist = d; bestIdx = i end
        end
        local best = table.remove(unlooted, bestIdx)
        table.insert(sorted, best)
        cx, cy = best.x, best.y
    end
    TwoOpt(sorted)
    if #sorted > 0 then exitX, exitY = sorted[#sorted].x, sorted[#sorted].y end
    for _, t in ipairs(looted) do table.insert(sorted, t) end
    return sorted, exitX, exitY
end

local function BuildRoute()
    routeList = {}
    activeProfIDs = {}
    local playerMapID, playerX, playerY = GetPlayerZoneAndPos()
    -- Resolve sub-zones to whichever group member appears in ZONE_ORDER
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
    for profID in pairs(PKT.PROF_NAMES) do
        if HasProfession(profID) then
            activeProfIDs[profID] = true
            local treasures = PKT.TREASURES[profID]
            if treasures then
                for _, t in ipairs(treasures) do
                    if not byZone[t.mapID] then byZone[t.mapID] = {} end
                    table.insert(byZone[t.mapID], t)
                end
            end
        end
    end
    local currentOrderIdx = 0
    for i, mapID in ipairs(PKT.ZONE_ORDER) do
        if mapID == playerZoneID then currentOrderIdx = i; break end
    end
    local zoneOrder = {}
    if playerZoneID and byZone[playerZoneID] then
        table.insert(zoneOrder, playerZoneID)
    end
    if currentOrderIdx > 0 then
        for i = currentOrderIdx + 1, #PKT.ZONE_ORDER do
            local mapID = PKT.ZONE_ORDER[i]
            if mapID ~= playerZoneID and byZone[mapID] then table.insert(zoneOrder, mapID) end
        end
        for i = 1, currentOrderIdx - 1 do
            local mapID = PKT.ZONE_ORDER[i]
            if mapID ~= playerZoneID and byZone[mapID] then table.insert(zoneOrder, mapID) end
        end
    else
        for _, mapID in ipairs(PKT.ZONE_ORDER) do
            if mapID ~= playerZoneID and byZone[mapID] then table.insert(zoneOrder, mapID) end
        end
    end
    local exitX, exitY = playerX, playerY
    for i, mapID in ipairs(zoneOrder) do
        if byZone[mapID] then
            local startX = (i == 1) and playerX or exitX
            local startY = (i == 1) and playerY or exitY
            local sorted, zExitX, zExitY = NearestNeighborSort(byZone[mapID], startX, startY)
            exitX, exitY = zExitX, zExitY
            for _, t in ipairs(sorted) do table.insert(routeList, t) end
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

local function SetNativeWaypoint(mapID, x, y)
    if not C_Map.SetUserWaypoint or not UiMapPoint then return false end
    local ok = pcall(function()
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromVector2D(mapID, CreateVector2D(x, y)))
        if C_SuperTrack then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
    end)
    return ok
end

local function ClearCurrentWaypoint()
    if C_Map.ClearUserWaypoint then C_Map.ClearUserWaypoint() end
    if currentWaypointUID and TomTom then
        TomTom:RemoveWaypoint(currentWaypointUID)
        currentWaypointUID = nil
    end
end

local function SetWaypointAt(index)
    ClearCurrentWaypoint()
    local t = routeList[index]
    if not t then return end
    currentIndex = index
    local playerMapID = C_Map.GetBestMapForUnit("player")
    local sameGroup = false
    if playerMapID ~= t.mapID then
        local group = GetZoneGroup(playerMapID)
        for _, id in ipairs(group) do
            if id == t.mapID then sameGroup = true; break end
        end
    end
    local portal = (playerMapID ~= t.mapID) and not sameGroup and PKT.GetPortalSuggestion(playerMapID, t.mapID)
    if portal then
        SetNativeWaypoint(portal.mapID, portal.x, portal.y)
        if TomTom then
            currentWaypointUID = TomTom:AddWaypoint(portal.mapID, portal.x, portal.y, {
                title = string.format("[PKT] %s", portal.name),
                from = "ProfessionKnowledgeTracker",
                persistent = false, minimap = true, world = true, crazy = true,
            })
        end
        print(string.format("|cff00ccff[PKT]|r Take |cffff9900%s|r → |cffffff00%s|r in |cffaaaaaa%s|r (%.1f, %.1f)",
            portal.name, t.name, PKT.ZONE_NAMES[t.mapID] or "?", t.x * 100, t.y * 100))
    else
        SetNativeWaypoint(t.mapID, t.x, t.y)
        if TomTom then
            currentWaypointUID = TomTom:AddWaypoint(t.mapID, t.x, t.y, {
                title = string.format("[PKT] %s", t.name),
                from = "ProfessionKnowledgeTracker",
                persistent = false, minimap = true, world = true, crazy = true,
            })
        end
        local zoneName = PKT.ZONE_NAMES[t.mapID] or "Unknown"
        print(string.format("|cff00ccff[PKT]|r Next: |cffffff00%s|r in |cffaaaaaa%s|r (%.1f, %.1f)%s",
            t.name, zoneName, t.x * 100, t.y * 100,
            t.notes and ("|cffff9900  [" .. t.notes .. "]|r") or ""))
    end
    PKT.UpdateUI()
end

local autoAdvancePending = false
local function CheckAutoAdvance()
    if autoAdvancePending then return end
    if #routeList == 0 or currentIndex == 0 then
        PKT.UpdateUI()
        return
    end
    local current = routeList[currentIndex]
    if current and not IsLooted(current) then
        PKT.UpdateUI()
        return
    end
    if not JumpToNearestInZone() then
        local next = FindNextIncomplete(1)
        if next then
            SetWaypointAt(next)
        else
            ClearCurrentWaypoint()
            currentIndex = 0
            PKT.UpdateUI()
            print("|cff00ff00[PKT]|r All profession knowledge treasures collected! Grats!")
        end
    end
end

JumpToNearestInZone = function()
    local playerMapID, playerX, playerY = GetPlayerZoneAndPos()
    if not playerMapID or #routeList == 0 then return false end
    local group = GetZoneGroup(playerMapID)
    local groupSet = {}
    for _, id in ipairs(group) do groupSet[id] = true end
    local bestIdx, bestDist = nil, math.huge
    for i, t in ipairs(routeList) do
        if groupSet[t.mapID] and not IsLooted(t) then
            local d = DistSq(playerX, playerY, t.x, t.y)
            if d < bestDist then bestDist = d; bestIdx = i end
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

function PKT.GetPortalSuggestion(fromMapID, toMapID)
    if not fromMapID or not toMapID then return nil end
    local fromGroup = GetZoneGroup(fromMapID)
    local toGroup = GetZoneGroup(toMapID)
    local fromSet, toSet = {}, {}
    for _, id in ipairs(fromGroup) do fromSet[id] = true end
    for _, id in ipairs(toGroup) do toSet[id] = true end
    if toSet[fromMapID] then return nil end
    if IsFlyable(fromMapID, toMapID) then return nil end
    for _, portal in ipairs(PKT.PORTALS) do
        if fromSet[portal.mapID] and toSet[portal.dest] and IsPortalUnlocked(portal) then
            return portal
        end
    end
    local hubMapID = nil
    if PKT.ZONE_TRANSIT then
        for _, id in ipairs(fromGroup) do
            if PKT.ZONE_TRANSIT[id] then
                hubMapID = PKT.ZONE_TRANSIT[id]
                break
            end
        end
    end
    local _, px, py = GetPlayerZoneAndPos()
    if hubMapID then
        local hubGroup = GetZoneGroup(hubMapID)
        local hubSet = {}
        for _, id in ipairs(hubGroup) do hubSet[id] = true end
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
            local best, bestDist = nil, math.huge
            for _, portal in ipairs(PKT.PORTALS) do
                if fromSet[portal.mapID] and hubSet[portal.dest] and IsPortalUnlocked(portal) then
                    local d = DistSq(px, py, portal.x, portal.y)
                    if d < bestDist then bestDist = d; best = portal end
                end
            end
            if best then return best end
        end
        for _, portal in ipairs(PKT.PORTALS) do
            if hubSet[portal.mapID] and toSet[portal.dest] and IsPortalUnlocked(portal) then
                return portal
            end
        end
    end
    local best, bestDist = nil, math.huge
    for _, portal in ipairs(PKT.PORTALS) do
        if fromSet[portal.mapID] and IsPortalUnlocked(portal) then
            local d = DistSq(px, py, portal.x, portal.y)
            if d < bestDist then bestDist = d; best = portal end
        end
    end
    return best
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
        table.insert(result, { name = PKT.PROF_NAMES[profID], remaining = remaining, total = total })
    end
    table.sort(result, function(a, b) return a.name < b.name end)
    return result
end

function PKT.GoNext()
    local idx = FindNextIncomplete(currentIndex + 1)
    if idx then SetWaypointAt(idx)
    else print("|cff00ccff[PKT]|r No more incomplete treasures ahead.") end
end

function PKT.GoPrev()
    local idx = FindPrevIncomplete(currentIndex - 1)
    if idx then SetWaypointAt(idx)
    else print("|cff00ccff[PKT]|r No more incomplete treasures before this one.") end
end

function PKT.GoFirst()
    local idx = FindNextIncomplete(1)
    if idx then SetWaypointAt(idx)
    else print("|cff00ff00[PKT]|r All done!") end
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
            table.insert(result, { profID = profID, name = PKT.PROF_NAMES[profID], quest = q, done = done })
        end
    end
    table.sort(result, function(a, b) return a.name < b.name end)
    return result
end

function PKT.Reload()
    BuildRoute()
    local remaining = 0
    for _, t in ipairs(routeList) do
        if not IsLooted(t) then remaining = remaining + 1 end
    end
    if remaining == 0 then
        PKT.UpdateUI()
        print("|cff00ff00[PKT]|r All profession knowledge treasures already collected!")
        return
    end
    if not JumpToNearestInZone() then
        local idx = FindNextIncomplete(1)
        if idx then SetWaypointAt(idx) end
    end
    print(string.format("|cff00ccff[PKT]|r Route built: |cffffff00%d|r remaining of |cffaaaaaa%d|r total.",
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
    elseif cmd == "dmf"     then PKT.ToggleDMFUI()
    elseif cmd == "mapid"   then
        local mapID = C_Map.GetBestMapForUnit("player")
        local mapInfo = mapID and C_Map.GetMapInfo(mapID)
        local subName = mapInfo and mapInfo.name or "?"
        print(string.format("|cff00ccff[PKT]|r Current mapID: |cffffff00%d|r (%s)", mapID or 0, subName))
    elseif cmd == "list"    then
        local count = 0
        for i, t in ipairs(routeList) do
            if not IsLooted(t) then
                count = count + 1
                local zoneName = PKT.ZONE_NAMES[t.mapID] or "?"
                print(string.format("|cff00ccff[PKT]|r %d. |cffffff00%s|r - %s (%.1f, %.1f)",
                    i, t.name, zoneName, t.x * 100, t.y * 100))
            end
        end
        if count == 0 then print("|cff00ff00[PKT]|r All done!") end
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
            print("|cff00ccff[PKT]|r |cffFFDD44Darkmoon Faire|r detected — showing knowledge quests.")
        end
    else
        if dmfAutoOpened and PKT.IsDMFShown() then PKT.HideDMFUI() end
        dmfAutoOpened = false
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
eventFrame:RegisterEvent("LOOT_CLOSED")

eventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(3, function()
            BuildRoute()
            local remaining = 0
            for _, t in ipairs(routeList) do
                if not IsLooted(t) then remaining = remaining + 1 end
            end
            if remaining > 0 then
                print(string.format("|cff00ccff[PKT]|r %d profession knowledge treasure(s) remaining.",
                    remaining))
                PKT.ShowUI()
            end
            PKT.UpdateUI()
            CheckDMFZone()
            C_Timer.NewTicker(3, function()
                CheckAutoAdvance()
            end)
        end)
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        C_Timer.After(1.5, function()
            CheckDMFZone()
            if currentIndex > 0 and #routeList > 0 then
                local playerMapID = C_Map.GetBestMapForUnit("player")
                local group = GetZoneGroup(playerMapID)
                local groupSet = {}
                for _, id in ipairs(group) do groupSet[id] = true end
                local hasHere = false
                for _, t in ipairs(routeList) do
                    if groupSet[t.mapID] and not IsLooted(t) then hasHere = true; break end
                end
                if hasHere then
                    local currentTarget = routeList[currentIndex]
                    local targetGroup = currentTarget and GetZoneGroup(currentTarget.mapID)
                    local targetSet = {}
                    if targetGroup then for _, id in ipairs(targetGroup) do targetSet[id] = true end end
                    if not currentTarget or targetSet[playerMapID] then
                        local zoneName = PKT.ZONE_NAMES[playerMapID] or "this zone"
                        print(string.format("|cff00ccff[PKT]|r Entered %s — jumping to nearest treasure.", zoneName))
                        JumpToNearestInZone()
                    else
                        PKT.UpdateUI()
                    end
                else
                    local next = FindNextIncomplete(1)
                    if next then SetWaypointAt(next) end
                end
            end
        end)
    elseif event == "UNIT_QUEST_LOG_CHANGED" then
        if unit == "player" then CheckAutoAdvance() end
    elseif event == "QUEST_LOG_UPDATE" then
        CheckAutoAdvance()
    elseif event == "LOOT_CLOSED" then
        autoAdvancePending = true
        C_Timer.After(0.8, function()
            autoAdvancePending = false
            CheckAutoAdvance()
        end)
    end
end)
