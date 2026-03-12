PKT = PKT or {}

local frame

local function MakeButton(parent, label, width, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width, 24)
    btn:SetText(label)
    btn:SetScript("OnClick", onClick)
    return btn
end

local function CountRemaining(list)
    local n = 0
    for _, t in ipairs(list) do
        if not PKT.IsLooted(t) then n = n + 1 end
    end
    return n
end

local function CreateTrackerFrame()
    local f = CreateFrame("Frame", "PKTTrackerFrame", UIParent, "BackdropTemplate")
    f:SetSize(320, 240)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("MEDIUM")
    f:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0.05, 0.04, 0.02, 0.93)
    f:SetBackdropBorderColor(0.8, 0.6, 0.2, 0.9)

    local titleBar = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleBar:SetPoint("TOP", 0, -8)
    titleBar:SetText("|cffFFDD44Profession Knowledge Tracker|r")

    local sep = f:CreateTexture(nil, "OVERLAY")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", 8, -26)
    sep:SetPoint("TOPRIGHT", -8, -26)
    sep:SetColorTexture(0.8, 0.6, 0.2, 0.5)

    local treasureName = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    treasureName:SetPoint("TOPLEFT", 10, -36)
    treasureName:SetPoint("TOPRIGHT", -10, -36)
    treasureName:SetJustifyH("CENTER")
    treasureName:SetHeight(16)
    f.treasureName = treasureName

    local zoneCoords = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    zoneCoords:SetPoint("TOP", 0, -56)
    zoneCoords:SetTextColor(0.9, 0.75, 0.4)
    f.zoneCoords = zoneCoords

    local notes = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    notes:SetPoint("TOP", 0, -72)
    notes:SetTextColor(1, 0.7, 0.2)
    notes:SetWidth(280)
    notes:SetJustifyH("CENTER")
    f.notes = notes

    local progress = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    progress:SetPoint("TOP", 0, -90)
    progress:SetTextColor(0.8, 0.8, 0.8)
    f.progress = progress

    local sep2 = f:CreateTexture(nil, "OVERLAY")
    sep2:SetHeight(1)
    sep2:SetPoint("TOPLEFT", 8, -108)
    sep2:SetPoint("TOPRIGHT", -8, -108)
    sep2:SetColorTexture(0.8, 0.6, 0.2, 0.2)

    local profBreakdown = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    profBreakdown:SetPoint("TOPLEFT", 10, -116)
    profBreakdown:SetPoint("TOPRIGHT", -10, -116)
    profBreakdown:SetJustifyH("CENTER")
    profBreakdown:SetHeight(80)
    f.profBreakdown = profBreakdown

    local sep3 = f:CreateTexture(nil, "OVERLAY")
    sep3:SetHeight(1)
    sep3:SetPoint("BOTTOMLEFT", 8, 42)
    sep3:SetPoint("BOTTOMRIGHT", -8, 42)
    sep3:SetColorTexture(0.8, 0.6, 0.2, 0.3)

    local zoneIndicator = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    zoneIndicator:SetPoint("BOTTOMLEFT", 10, 46)
    zoneIndicator:SetPoint("BOTTOMRIGHT", -10, 46)
    zoneIndicator:SetJustifyH("CENTER")
    zoneIndicator:SetTextColor(0.9, 0.75, 0.4)
    f.zoneIndicator = zoneIndicator

    local btnY = 10
    local btnW = 54
    local btnGap = 3

    local prevBtn = MakeButton(f, "< Prev", btnW, function() PKT.GoPrev() end)
    prevBtn:SetPoint("BOTTOMLEFT", f, "BOTTOM", -(btnW * 2 + btnGap * 2 + btnW / 2), btnY)

    local nearBtn = MakeButton(f, "Nearest", btnW, function() PKT.GoNearest() end)
    nearBtn:SetPoint("LEFT", prevBtn, "RIGHT", btnGap, 0)

    local firstBtn = MakeButton(f, "First", btnW, function() PKT.GoFirst() end)
    firstBtn:SetPoint("LEFT", nearBtn, "RIGHT", btnGap, 0)

    local nextBtn = MakeButton(f, "Next >", btnW, function() PKT.GoNext() end)
    nextBtn:SetPoint("LEFT", firstBtn, "RIGHT", btnGap, 0)

    local reloadBtn = MakeButton(f, "Reload", btnW, function() PKT.Reload() end)
    reloadBtn:SetPoint("LEFT", nextBtn, "RIGHT", btnGap, 0)

    local closeBtn = MakeButton(f, "X", 22, function()
        f:Hide()
    end)
    closeBtn:SetPoint("TOPRIGHT", 0, 0)

    f:Hide()
    return f
end

local function UpdateProfBreakdown()
    local breakdown = PKT.GetProfBreakdown()
    if #breakdown == 0 then frame.profBreakdown:SetText(""); return end
    local lines = {}
    for _, entry in ipairs(breakdown) do
        if entry.remaining == 0 then
            table.insert(lines, string.format("|cff00ff00%s  Complete|r", entry.name))
        else
            table.insert(lines, string.format("|cffffff00%s|r  |cffaaaaaa%d / %d|r", entry.name, entry.remaining, entry.total))
        end
    end
    frame.profBreakdown:SetText(table.concat(lines, "\n"))
end

function PKT.UpdateUI()
    if not frame or not frame:IsShown() then return end
    local playerMapID = C_Map.GetBestMapForUnit("player")
    local zoneName = (playerMapID and PKT.ZONE_NAMES[playerMapID]) or "Unknown Zone"
    local hereRemaining = 0
    local zoneGroup = { playerMapID }
    if PKT.ZONE_GROUPS and playerMapID then
        for _, g in ipairs(PKT.ZONE_GROUPS) do
            for _, id in ipairs(g) do
                if id == playerMapID then zoneGroup = g; break end
            end
        end
    end
    local groupSet = {}
    for _, id in ipairs(zoneGroup) do groupSet[id] = true end
    for _, t in ipairs(PKT.GetRouteList()) do
        if groupSet[t.mapID] and not PKT.IsLooted(t) then hereRemaining = hereRemaining + 1 end
    end
    if hereRemaining > 0 then
        frame.zoneIndicator:SetText(string.format("You are in: |cffffff00%s|r  (%d treasure(s) here)", zoneName, hereRemaining))
    else
        local t2 = nil
        for _, item in ipairs(PKT.GetRouteList()) do
            if not PKT.IsLooted(item) and item.mapID ~= playerMapID then
                t2 = item
                break
            end
        end
        local portalHint = ""
        if t2 and playerMapID then
            local portal = PKT.GetPortalSuggestion(playerMapID, t2.mapID)
            if portal then
                portalHint = string.format("\n|cffff9900Take: %s|r", portal.name)
            else
                portalHint = string.format("\n|cffff9900Head to: %s|r", PKT.ZONE_NAMES[t2.mapID] or "?")
            end
        end
        frame.zoneIndicator:SetText(string.format("You are in: |cffffff00%s|r  |cff888888(none here)|r%s", zoneName, portalHint))
    end
    local list = PKT.GetRouteList()
    local remaining = CountRemaining(list)
    local t, _, total = PKT.GetCurrent()
    if total == 0 then
        frame.treasureName:SetText("|cffaaaaaa(No professions found - type /pkt reload)|r")
        frame.zoneCoords:SetText("")
        frame.notes:SetText("")
        frame.progress:SetText("")
        frame.profBreakdown:SetText("")
        return
    end
    if remaining == 0 then
        frame.treasureName:SetText("|cff00ff00All Done! Congratulations!|r")
        frame.zoneCoords:SetText("")
        frame.notes:SetText("")
        frame.progress:SetText(string.format("Collected all %d treasures", total))
        UpdateProfBreakdown()
        return
    end
    if not t then
        frame.treasureName:SetText("|cffaaaaaa(Press First or Next to begin)|r")
        frame.zoneCoords:SetText("")
        frame.notes:SetText("")
        frame.progress:SetText(string.format("|cffaaaaaa%d remaining of %d total|r", remaining, total))
        UpdateProfBreakdown()
        return
    end
    frame.treasureName:SetText("|cffffff00" .. t.name .. "|r")
    local targetZone = PKT.ZONE_NAMES[t.mapID] or "Unknown"
    frame.zoneCoords:SetText(string.format("%s  |cff88bbff%.1f, %.1f|r", targetZone, t.x * 100, t.y * 100))
    frame.notes:SetText(t.notes or "")
    frame.progress:SetText(string.format("|cffaaaaaa%d remaining of %d total|r", remaining, total))
    UpdateProfBreakdown()
end

function PKT.ShowUI()
    if not frame then frame = CreateTrackerFrame() end
    frame:Show()
    PKT.UpdateUI()
end

function PKT.ToggleUI()
    if not frame then frame = CreateTrackerFrame() end
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        PKT.UpdateUI()
    end
end

local dmfFrame
local dmfProfList = {}
local dmfProfIndex = 1

local function BuildDMFContent(q)
    if not q then return "|cffaaaaaa(No data for this profession.)|r" end
    local lines = {}
    lines[#lines+1] = "|cffffff00Vendor:|r " .. q.vendor
    lines[#lines+1] = string.format("|cffaaaaaa(Darkmoon Island  ~%.0f, %.0f  — coords approx)|r", q.x * 100, q.y * 100)
    lines[#lines+1] = ""
    if q.needed and #q.needed > 0 then
        lines[#lines+1] = "|cff00ccffBring With You:|r"
        for _, item in ipairs(q.needed) do
            lines[#lines+1] = string.format("  |cffaaaaaa•|r %dx %s", item.count, item.name)
            lines[#lines+1] = string.format("    |cff777777%s|r", item.tip)
        end
    else
        lines[#lines+1] = "|cff00ccffBring With You:|r |cff777777nothing — all provided|r"
    end
    lines[#lines+1] = ""
    if q.provided and #q.provided > 0 then
        lines[#lines+1] = "|cff00ff00Vendor Provides:|r"
        for _, p in ipairs(q.provided) do
            lines[#lines+1] = "  |cffaaaaaa•|r " .. p
        end
        lines[#lines+1] = ""
    end
    lines[#lines+1] = "|cffFFDD44How To Complete:|r"
    for i, step in ipairs(q.steps) do
        lines[#lines+1] = string.format("|cffffff00%d.|r %s", i, step)
    end
    return table.concat(lines, "\n")
end

local function UpdateDMFContent()
    if not dmfFrame then return end
    if #dmfProfList == 0 then
        dmfFrame.profName:SetText("|cffaaaaaa(No professions — try /pkt reload)|r")
        dmfFrame.content:SetText("No Darkmoon Faire profession quests found.")
        return
    end
    local entry = dmfProfList[dmfProfIndex]
    local doneText = entry.done and "|cff00ff00[Done this Faire]|r" or "|cffffff00[Available]|r"
    dmfFrame.profName:SetText(entry.name .. "  " .. doneText)
    dmfFrame.content:SetText(BuildDMFContent(entry.quest))
end

local function CreateDMFFrame()
    local f = CreateFrame("Frame", "PKTDMFFrame", UIParent, "BackdropTemplate")
    f:SetSize(390, 410)
    f:SetPoint("CENTER", 0, 0)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("HIGH")
    f:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0.05, 0.04, 0.02, 0.93)
    f:SetBackdropBorderColor(0.8, 0.6, 0.2, 0.9)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -8)
    title:SetText("|cffFFDD44Darkmoon Faire Knowledge Quests|r  |cffaaaaaa(+2 per profession)|r")

    local closeBtn = MakeButton(f, "X", 22, function() f:Hide() end)
    closeBtn:SetPoint("TOPRIGHT", 0, 0)

    local sep1 = f:CreateTexture(nil, "OVERLAY")
    sep1:SetHeight(1)
    sep1:SetPoint("TOPLEFT", 8, -28)
    sep1:SetPoint("TOPRIGHT", -8, -28)
    sep1:SetColorTexture(0.8, 0.6, 0.2, 0.5)

    local prevBtn = MakeButton(f, "< Prev", 60, function()
        if #dmfProfList == 0 then return end
        dmfProfIndex = dmfProfIndex - 1
        if dmfProfIndex < 1 then dmfProfIndex = #dmfProfList end
        UpdateDMFContent()
    end)
    prevBtn:SetPoint("TOPLEFT", 8, -33)

    local profName = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profName:SetPoint("TOP", 0, -42)
    profName:SetWidth(230)
    profName:SetJustifyH("CENTER")
    f.profName = profName

    local nextBtn = MakeButton(f, "Next >", 60, function()
        if #dmfProfList == 0 then return end
        dmfProfIndex = dmfProfIndex + 1
        if dmfProfIndex > #dmfProfList then dmfProfIndex = 1 end
        UpdateDMFContent()
    end)
    nextBtn:SetPoint("TOPRIGHT", -8, -33)

    local sep2 = f:CreateTexture(nil, "OVERLAY")
    sep2:SetHeight(1)
    sep2:SetPoint("TOPLEFT", 8, -62)
    sep2:SetPoint("TOPRIGHT", -8, -62)
    sep2:SetColorTexture(0.8, 0.6, 0.2, 0.3)

    local content = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    content:SetPoint("TOPLEFT", 12, -70)
    content:SetPoint("TOPRIGHT", -12, -70)
    content:SetHeight(310)
    content:SetJustifyH("LEFT")
    content:SetJustifyV("TOP")
    f.content = content

    f:Hide()
    return f
end

local function EnsureDMFFrame()
    if not dmfFrame then dmfFrame = CreateDMFFrame() end
end

function PKT.ShowDMFUI()
    EnsureDMFFrame()
    dmfProfList = PKT.GetActiveDMFProfs()
    if dmfProfIndex > #dmfProfList then dmfProfIndex = 1 end
    UpdateDMFContent()
    dmfFrame:Show()
end

function PKT.HideDMFUI()
    if dmfFrame then dmfFrame:Hide() end
end

function PKT.IsDMFShown()
    return dmfFrame and dmfFrame:IsShown()
end

function PKT.ToggleDMFUI()
    EnsureDMFFrame()
    if dmfFrame:IsShown() then dmfFrame:Hide()
    else PKT.ShowDMFUI() end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then frame = CreateTrackerFrame() end
end)
