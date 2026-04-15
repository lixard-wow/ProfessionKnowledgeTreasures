PKT = PKT or {}

local format  = string.format
local tconcat = table.concat

local C_YELLOW = "|cffffff00"
local C_GRAY   = "|cffaaaaaa"
local C_ORANGE = "|cffff9900"
local C_RED    = "|cffff4444"
local C_GOLD   = "|cffFFDD44"
local C_END    = "|r"

local trackerFrame

local function SetFontSize(fs, size)
    local face, _, flags = fs:GetFont()
    fs:SetFont(face, size, flags)
end

local function MakeButton(parent, label, width, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width, 24)
    btn:SetText(label)
    btn:SetScript("OnClick", onClick)
    return btn
end

local function CreatePKTFrame(name, w, h, strata)
    local f = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    f:SetSize(w, h)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata(strata or "MEDIUM")
    f:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0.05, 0.04, 0.02, 0.93)
    f:SetBackdropBorderColor(0.8, 0.6, 0.2, 0.9)
    return f
end

local function AddSeparator(parent, anchor, y, alpha)
    local s = parent:CreateTexture(nil, "OVERLAY")
    s:SetHeight(1)
    s:SetPoint(anchor .. "LEFT", 8, y)
    s:SetPoint(anchor .. "RIGHT", -8, y)
    s:SetColorTexture(0.8, 0.6, 0.2, alpha or 0.3)
end

local function CreateTrackerFrame()
    local f = CreatePKTFrame("PKTTrackerFrame", 320, 290, "MEDIUM")
    f:SetPoint("CENTER")

    local titleBar = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleBar:SetPoint("TOP", 0, -8)
    titleBar:SetText(C_GOLD .. "Profession Knowledge Treasures" .. C_END)

    local testBadgeBtn = CreateFrame("Button", nil, f)
    testBadgeBtn:SetPoint("TOPLEFT", 4, -4)
    testBadgeBtn:SetSize(60, 18)
    local testBadge = testBadgeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    testBadge:SetAllPoints()
    testBadge:SetTextColor(1, 0.2, 0.2)
    testBadge:SetText("")
    SetFontSize(testBadge, 12)
    testBadgeBtn:SetScript("OnClick", function()
        if PKT.testMode then PKT.ToggleTestProfUI() end
    end)
    f.testBadge = testBadge

    AddSeparator(f, "TOP", -32, 0.5)

    local treasureName = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    treasureName:SetPoint("TOPLEFT", 10, -44)
    treasureName:SetPoint("TOPRIGHT", -10, -44)
    treasureName:SetJustifyH("CENTER")
    treasureName:SetHeight(18)
    SetFontSize(treasureName, 14)
    f.treasureName = treasureName

    local zoneCoords = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    zoneCoords:SetPoint("TOP", 0, -74)
    zoneCoords:SetTextColor(0.9, 0.75, 0.4)
    SetFontSize(zoneCoords, 12)
    f.zoneCoords = zoneCoords

    local notes = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    notes:SetPoint("TOP", 0, -100)
    notes:SetTextColor(1, 1, 1)
    notes:SetWidth(290)
    notes:SetJustifyH("CENTER")
    SetFontSize(notes, 12)
    f.notes = notes

    local progress = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    progress:SetPoint("TOP", 0, -144)
    progress:SetTextColor(0.8, 0.8, 0.8)
    SetFontSize(progress, 12)
    f.progress = progress

    AddSeparator(f, "TOP", -158, 0.2)

    local profBreakdown = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    profBreakdown:SetPoint("TOPLEFT", 10, -168)
    profBreakdown:SetPoint("TOPRIGHT", -10, -168)
    profBreakdown:SetJustifyH("CENTER")
    profBreakdown:SetHeight(40)
    SetFontSize(profBreakdown, 12)
    f.profBreakdown = profBreakdown

    AddSeparator(f, "BOTTOM", 42, 0.3)

    local zoneIndicator = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    zoneIndicator:SetPoint("BOTTOMLEFT", 10, 46)
    zoneIndicator:SetPoint("BOTTOMRIGHT", -10, 46)
    zoneIndicator:SetJustifyH("CENTER")
    zoneIndicator:SetTextColor(0.9, 0.75, 0.4)
    SetFontSize(zoneIndicator, 12)
    f.zoneIndicator = zoneIndicator

    local btnW  = 54
    local btnGap = 3

    local prevBtn = MakeButton(f, "< Prev", btnW, function() PKT.GoPrev() end)
    prevBtn:SetPoint("BOTTOMLEFT", f, "BOTTOM", -(btnW * 2 + btnGap * 2 + btnW / 2), 10)

    local nearBtn = MakeButton(f, "Nearest", btnW, function() PKT.GoNearest() end)
    nearBtn:SetPoint("LEFT", prevBtn, "RIGHT", btnGap, 0)

    local firstBtn = MakeButton(f, "First", btnW, function() PKT.GoFirst() end)
    firstBtn:SetPoint("LEFT", nearBtn, "RIGHT", btnGap, 0)

    local nextBtn = MakeButton(f, "Next >", btnW, function() PKT.GoNext() end)
    nextBtn:SetPoint("LEFT", firstBtn, "RIGHT", btnGap, 0)

    local reloadBtn = MakeButton(f, "Reload", btnW, function() PKT.Reload() end)
    reloadBtn:SetPoint("LEFT", nextBtn, "RIGHT", btnGap, 0)

    local closeBtn = MakeButton(f, "X", 22, function() f:Hide() end)
    closeBtn:SetPoint("TOPRIGHT", 0, 0)

    f:Hide()
    return f
end

local function UpdateProfBreakdown()
    local breakdown = PKT.GetProfBreakdown()
    if #breakdown == 0 then trackerFrame.profBreakdown:SetText(""); return end
    local lines = {}
    for _, entry in ipairs(breakdown) do
        if entry.remaining == 0 then
            lines[#lines + 1] = format("|cff44cc44%s  Complete|r", entry.name)
        else
            lines[#lines + 1] = format(C_YELLOW .. "%s" .. C_END .. "  " .. C_GRAY .. "%d / %d" .. C_END, entry.name, entry.remaining, entry.total)
        end
    end
    trackerFrame.profBreakdown:SetText(tconcat(lines, "\n"))
end

function PKT.UpdateUI()
    if not trackerFrame or not trackerFrame:IsShown() then return end
    trackerFrame.testBadge:SetText(PKT.testMode and "[TEST]" or "")
    local playerMapID = C_Map.GetBestMapForUnit("player")
    local zoneName    = (playerMapID and PKT.ZONE_NAMES[playerMapID]) or "Unknown Zone"
    local groupSet    = PKT.GetZoneGroupSet(playerMapID)
    local hereRemaining = 0
    for _, t in ipairs(PKT.GetRouteList()) do
        if groupSet[t.mapID] and not PKT.IsLooted(t) then hereRemaining = hereRemaining + 1 end
    end
    if hereRemaining > 0 then
        trackerFrame.zoneIndicator:SetText(format("You are in: " .. C_YELLOW .. "%s" .. C_END .. "  (%d treasure(s) here)", zoneName, hereRemaining))
    else
        local t2
        for _, item in ipairs(PKT.GetRouteList()) do
            if not PKT.IsLooted(item) and not groupSet[item.mapID] then
                t2 = item
                break
            end
        end
        local portalHint = ""
        if t2 and playerMapID then
            local portal = PKT.GetPortalSuggestion(playerMapID, t2.mapID)
            if portal then
                portalHint = format("\n" .. C_ORANGE .. "Take: %s" .. C_END, portal.name)
            else
                portalHint = format("\n" .. C_ORANGE .. "Head to: %s" .. C_END, PKT.ZONE_NAMES[t2.mapID] or "?")
            end
        end
        trackerFrame.zoneIndicator:SetText(format("You are in: " .. C_YELLOW .. "%s" .. C_END .. "  |cff888888(none here)|r%s", zoneName, portalHint))
    end
    local list      = PKT.GetRouteList()
    local remaining = PKT.CountRemaining(list)
    local t, _, total = PKT.GetCurrent()
    if total == 0 then
        trackerFrame.treasureName:SetText(C_GRAY .. "(No professions found - type /pkt reload)" .. C_END)
        trackerFrame.zoneCoords:SetText("")
        trackerFrame.notes:SetText("")
        trackerFrame.progress:SetText("")
        trackerFrame.profBreakdown:SetText("")
        return
    end
    if remaining == 0 then
        trackerFrame.treasureName:SetText("|cff44cc44All Done! Congratulations!|r")
        trackerFrame.zoneCoords:SetText("")
        trackerFrame.notes:SetText("")
        trackerFrame.progress:SetText(format("Collected all %d treasures", total))
        UpdateProfBreakdown()
        return
    end
    if not t then
        trackerFrame.treasureName:SetText(C_GRAY .. "(Press First or Next to begin)" .. C_END)
        trackerFrame.zoneCoords:SetText("")
        trackerFrame.notes:SetText("")
        trackerFrame.progress:SetText(format(C_GRAY .. "%d remaining of %d total" .. C_END, remaining, total))
        UpdateProfBreakdown()
        return
    end
    trackerFrame.treasureName:SetText(C_YELLOW .. t.name .. C_END)
    local targetZone = PKT.ZONE_NAMES[t.mapID] or "Unknown"
    trackerFrame.zoneCoords:SetText(format("%s  |cff88bbff%.1f, %.1f|r", targetZone, t.x * 100, t.y * 100))
    trackerFrame.notes:SetText(t.notes or "")
    trackerFrame.progress:SetText(format(C_GRAY .. "%d remaining of %d total" .. C_END, remaining, total))
    UpdateProfBreakdown()
end

function PKT.ShowUI()
    if not trackerFrame then return end
    trackerFrame:Show()
    PKT.UpdateUI()
end

function PKT.ToggleUI()
    if not trackerFrame then return end
    if trackerFrame:IsShown() then
        trackerFrame:Hide()
    else
        trackerFrame:Show()
        PKT.UpdateUI()
    end
end

local dmfFrame

local function BuildDMFContent(q)
    if not q then return C_GRAY .. "(No data for this profession.)" .. C_END end
    local lines = {}
    lines[#lines + 1] = "|cffffff00Vendor:|r " .. q.vendor
    lines[#lines + 1] = format(C_GRAY .. "(Darkmoon Island  ~%.0f, %.0f  \226\128\148 coords approx)" .. C_END, q.x * 100, q.y * 100)
    lines[#lines + 1] = ""
    if q.needed and #q.needed > 0 then
        lines[#lines + 1] = "|cff00ccffBring With You:|r"
        for _, item in ipairs(q.needed) do
            lines[#lines + 1] = format("  |cffaaaaaa\226\128\162|r %dx %s", item.count, item.name)
            lines[#lines + 1] = format("    |cff999999%s|r", item.tip)
        end
    else
        lines[#lines + 1] = "|cff00ccffBring With You:|r |cff999999nothing \226\128\148 all provided|r"
    end
    lines[#lines + 1] = ""
    if q.provided and #q.provided > 0 then
        lines[#lines + 1] = "|cff44cc44Vendor Provides:|r"
        for _, p in ipairs(q.provided) do
            lines[#lines + 1] = "  |cffaaaaaa\226\128\162|r " .. p
        end
        lines[#lines + 1] = ""
    end
    lines[#lines + 1] = C_GOLD .. "How To Complete:" .. C_END
    for i, step in ipairs(q.steps) do
        lines[#lines + 1] = format(C_YELLOW .. "%d." .. C_END .. " %s", i, step)
    end
    return tconcat(lines, "\n")
end

local function UpdateDMFContent()
    if not dmfFrame then return end
    dmfFrame.testBadge:SetText(PKT.testMode and "[TEST]" or "")
    if #dmfFrame.profList == 0 then
        dmfFrame.profName:SetText(C_GRAY .. "(No professions \226\128\148 try /pkt reload)" .. C_END)
        dmfFrame.content:SetText("No Darkmoon Faire profession quests found.")
        return
    end
    local entry = dmfFrame.profList[dmfFrame.profIndex]
    local doneText = entry.done and "|cff44cc44[Done this Faire]|r" or (C_YELLOW .. "[Available]" .. C_END)
    dmfFrame.profName:SetText(entry.name .. "  " .. doneText)
    dmfFrame.content:SetText(BuildDMFContent(entry.quest))
end

local function CreateDMFFrame()
    local f = CreatePKTFrame("PKTDMFFrame", 390, 410, "HIGH")
    f:SetPoint("CENTER", 0, 0)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -8)
    title:SetText(C_GOLD .. "Darkmoon Faire Knowledge Quests" .. C_END)

    local testBadge = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    testBadge:SetPoint("TOPLEFT", 6, -6)
    testBadge:SetTextColor(1, 0.2, 0.2)
    testBadge:SetText("")
    SetFontSize(testBadge, 12)
    f.testBadge = testBadge

    local closeBtn = MakeButton(f, "X", 22, function() f:Hide() end)
    closeBtn:SetPoint("TOPRIGHT", 0, 0)

    AddSeparator(f, "TOP", -26, 0.5)

    local profName = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profName:SetPoint("TOPLEFT", 10, -34)
    profName:SetPoint("TOPRIGHT", -10, -34)
    profName:SetJustifyH("CENTER")
    profName:SetHeight(18)
    SetFontSize(profName, 14)
    f.profName = profName

    AddSeparator(f, "TOP", -58, 0.3)

    local content = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    content:SetPoint("TOPLEFT", 12, -66)
    content:SetPoint("BOTTOMRIGHT", -12, 42)
    content:SetJustifyH("LEFT")
    content:SetJustifyV("TOP")
    SetFontSize(content, 12)
    f.content = content

    AddSeparator(f, "BOTTOM", 42, 0.3)

    local btnW  = 70
    local btnGap = 3

    local prevBtn = MakeButton(f, "< Prev", btnW, function()
        if #f.profList == 0 then return end
        f.profIndex = f.profIndex - 1
        if f.profIndex < 1 then f.profIndex = #f.profList end
        UpdateDMFContent()
    end)
    prevBtn:SetPoint("BOTTOM", f, "BOTTOM", -(btnW / 2 + btnGap), 10)

    local nextBtn = MakeButton(f, "Next >", btnW, function()
        if #f.profList == 0 then return end
        f.profIndex = f.profIndex + 1
        if f.profIndex > #f.profList then f.profIndex = 1 end
        UpdateDMFContent()
    end)
    nextBtn:SetPoint("BOTTOM", f, "BOTTOM", (btnW / 2 + btnGap), 10)

    f.profList  = {}
    f.profIndex = 1
    f:Hide()
    return f
end

local function EnsureDMFFrame()
    if not dmfFrame then dmfFrame = CreateDMFFrame() end
end

function PKT.ShowDMFUI()
    EnsureDMFFrame()
    dmfFrame.profList = PKT.GetActiveDMFProfs()
    if dmfFrame.profIndex > #dmfFrame.profList then dmfFrame.profIndex = 1 end
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

local ldb = LibStub("LibDataBroker-1.1"):NewDataObject("ProfessionKnowledgeTreasures", {
    type = "launcher",
    text = "PKT",
    icon = "Interface\\AddOns\\ProfessionKnowledgeTreasures\\wow_treasure_minimap_icon_32",
    OnClick = function(_, button)
        if button == "LeftButton" then
            PKT.ToggleUI()
        elseif button == "RightButton" then
            PKT.ToggleDMFUI()
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("Profession Knowledge Treasures", 1, 0.82, 0)
        tooltip:AddLine("Left-click: toggle tracker", 1, 1, 1)
        tooltip:AddLine("Right-click: Darkmoon Faire quests", 1, 1, 1)
    end,
})

local testProfFrame

local function CreateTestProfFrame()
    local f = CreatePKTFrame("PKTTestProfFrame", 240, 230, "MEDIUM")
    f:SetPoint("LEFT", trackerFrame, "RIGHT", 6, 0)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -8)
    title:SetText(C_RED .. "Test Professions" .. C_END)
    SetFontSize(title, 14)

    local closeBtn = MakeButton(f, "X", 22, function() f:Hide() end)
    closeBtn:SetPoint("TOPRIGHT", 0, 0)

    AddSeparator(f, "TOP", -24, 0.5)

    local sortedProfs = {}
    for profID, name in pairs(PKT.PROF_NAMES) do
        sortedProfs[#sortedProfs + 1] = { id = profID, name = name }
    end
    table.sort(sortedProfs, function(a, b) return a.name < b.name end)

    local btnW   = 106
    local btnH   = 20
    local startY = -32
    local half   = math.ceil(#sortedProfs / 2)
    f.profButtons = {}
    for i, entry in ipairs(sortedProfs) do
        local col = (i <= half) and 0 or 1
        local row = (i <= half) and (i - 1) or (i - half - 1)
        local btn = MakeButton(f, entry.name, btnW, function()
            PKT.testProfs[entry.id] = PKT.testProfs[entry.id] and nil or true
            PKT.Reload()
            PKT.UpdateUI()
            PKT.RefreshTestProfButtons()
        end)
        btn:SetPoint("TOPLEFT", 8 + col * (btnW + 4), startY - row * (btnH + 4))
        btn:SetSize(btnW, btnH)
        btn._profName = entry.name
        f.profButtons[entry.id] = btn
    end

    AddSeparator(f, "BOTTOM", 36, 0.3)

    local allBtn = MakeButton(f, "All", btnW, function()
        for profID in pairs(PKT.PROF_NAMES) do PKT.testProfs[profID] = true end
        PKT.Reload()
        PKT.UpdateUI()
        PKT.RefreshTestProfButtons()
    end)
    allBtn:SetPoint("BOTTOMLEFT", 8, 8)

    local noneBtn = MakeButton(f, "None", btnW, function()
        PKT.testProfs = {}
        PKT.Reload()
        PKT.UpdateUI()
        PKT.RefreshTestProfButtons()
    end)
    noneBtn:SetPoint("BOTTOMRIGHT", -8, 8)

    f:Hide()
    return f
end

function PKT.RefreshTestProfButtons()
    if not testProfFrame or not testProfFrame.profButtons then return end
    for profID, btn in pairs(testProfFrame.profButtons) do
        if PKT.testProfs[profID] then
            btn:SetText(C_YELLOW .. btn._profName .. C_END)
        else
            btn:SetText("|cff888888" .. btn._profName .. C_END)
        end
    end
end

function PKT.ShowTestProfUI()
    if not testProfFrame then testProfFrame = CreateTestProfFrame() end
    testProfFrame:Show()
    PKT.RefreshTestProfButtons()
end

function PKT.HideTestProfUI()
    if testProfFrame then testProfFrame:Hide() end
end

function PKT.ToggleTestProfUI()
    if not testProfFrame then testProfFrame = CreateTestProfFrame() end
    if testProfFrame:IsShown() then
        testProfFrame:Hide()
    else
        testProfFrame:Show()
        PKT.RefreshTestProfButtons()
    end
end

function PKT.InitUI()
    PKT_SavedVars = PKT_SavedVars or {}
    PKT_SavedVars.minimap = PKT_SavedVars.minimap or { hide = false, minimapPos = 225 }
    trackerFrame = CreateTrackerFrame()
    local icon = LibStub("LibDBIcon-1.0")
    icon:Register("ProfessionKnowledgeTreasures", ldb, PKT_SavedVars.minimap)
    local iconButton = icon:GetMinimapButton("ProfessionKnowledgeTreasures")
    if iconButton and iconButton.icon then
        iconButton.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    end
end
