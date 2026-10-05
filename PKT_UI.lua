local _, PKT = ...
local L = PKT.L
local W = PKT.W
local format = string.format
local floor = math.floor
local max = math.max

local TRACKER_WIDTH = 360
local sets = {}
local T
local pendingShow = false

local function SetTextColor(fs, c)
    fs:SetTextColor(c[1], c[2], c[3], c[4] or 1)
end

local function Code(c)
    return format("|cff%02x%02x%02x", floor(c[1] * 255 + 0.5), floor(c[2] * 255 + 0.5), floor(c[3] * 255 + 0.5))
end

local function Dim(c, alpha)
    return { c[1], c[2], c[3], alpha }
end

local function CurrentSet()
    T = PKT.GetTheme()
    local set = sets[T.key]
    if not set then
        set = {}
        sets[T.key] = set
    end
    return set
end

local function Inset()
    return T.style.innerFrame and 5 or 1
end

local function Snapshot()
    local list = PKT.GetRouteList()
    local snap = { list = list }
    local playerMapID = C_Map.GetBestMapForUnit("player")
    snap.zoneName = (playerMapID and PKT.ZONE_NAMES[playerMapID]) or L.UNKNOWN_ZONE
    local groupSet = PKT.GetZoneGroupSet(playerMapID)
    local here, firstElsewhere = 0, nil
    for _, t in ipairs(list) do
        if not PKT.IsLooted(t) then
            if groupSet[t.mapID] then
                here = here + 1
            elseif not firstElsewhere then
                firstElsewhere = t
            end
        end
    end
    snap.here = here
    if here == 0 and firstElsewhere and playerMapID then
        local portal = PKT.GetPortalSuggestion(playerMapID, firstElsewhere.mapID)
        if portal then
            snap.hint = format(L.HINT_TAKE, portal.name)
        else
            snap.hint = format(L.HINT_HEAD_TO, PKT.ZONE_NAMES[firstElsewhere.mapID] or L.UNKNOWN_SHORT)
        end
    end
    snap.remaining = PKT.CountRemaining(list)
    local t, idx, total = PKT.GetCurrent()
    snap.current, snap.total = t, total
    if t then
        local position = 0
        for i = 1, idx do
            if not PKT.IsLooted(list[i]) then position = position + 1 end
        end
        snap.position = position
    end
    if total == 0 then
        snap.state = "empty"
    elseif snap.remaining == 0 then
        snap.state = "done"
    elseif not t then
        snap.state = "idle"
    else
        snap.state = "active"
    end
    return snap
end

local function CardInfo(snap)
    if snap.state == "active" then
        local t = snap.current
        return {
            name = t.name,
            zone = PKT.ZONE_NAMES[t.mapID] or L.UNKNOWN,
            coords = format("%.1f, %.1f", t.x * 100, t.y * 100),
            notes = t.notes or "",
            profID = t.prof,
            profName = PKT.PROF_NAMES[t.prof] or "",
            position = format(L.ROUTE_POSITION, snap.position or 1, snap.remaining),
        }
    end
    if snap.state == "empty" then
        return { name = L.NO_PROFESSIONS, notes = L.NO_PROFESSIONS_HINT }
    end
    if snap.state == "done" then
        return { name = L.ALL_DONE_CONGRATS, notes = format(L.COLLECTED_ALL, snap.total) }
    end
    return { name = L.PRESS_FIRST, notes = L.PRESS_FIRST_HINT }
end

local function BuildLedgerCard(parent, width)
    local c = T.colors
    local card = CreateFrame("Frame", nil, parent)
    card:SetWidth(width)
    W.Box(card, c.surface, c.surfaceBorder, T.metrics.surfaceRadius)
    W.Brackets(card, c.accent)
    card.kicker = W.Text(card, T, "kicker", c.accent)
    card.kicker:SetPoint("TOPLEFT", 16, -14)
    card.kicker:SetText(L.NEXT_TREASURE_KICKER)
    card.profText = W.Text(card, T, "small", c.muted)
    card.profText:SetPoint("TOPRIGHT", -16, -13)
    card.rule = W.Line(card, c.line)
    card.rule:SetHeight(1)
    card.rule:SetPoint("LEFT", card.kicker, "RIGHT", 8, 0)
    card.rule:SetPoint("RIGHT", card.profText, "LEFT", -8, 0)
    card.name = W.Wrap(W.Text(card, T, "heading", c.heading), width - 32)
    card.pin = W.Icon(card, "icon_pin", 13, c.accent)
    card.loc = W.Text(card, T, "body", c.title)
    card.notes = W.Wrap(W.Text(card, T, "body", c.body), width - 32)
    function card:Update(info)
        local y = -14
        local active = info.zone ~= nil
        self.kicker:SetShown(active)
        self.profText:SetShown(active)
        self.rule:SetShown(active)
        if active then
            self.profText:SetText(info.profName)
            y = y - 18
        end
        self.name:SetText(info.name)
        self.name:ClearAllPoints()
        self.name:SetPoint("TOPLEFT", 16, y)
        y = y - self.name:GetStringHeight() - 6
        self.pin:SetShown(active)
        self.loc:SetShown(active)
        if active then
            self.pin:ClearAllPoints()
            self.pin:SetPoint("TOPLEFT", 16, y - 1)
            self.loc:ClearAllPoints()
            self.loc:SetPoint("TOPLEFT", 35, y)
            self.loc:SetText(format("%s  %s\194\183|r  %s", info.zone, Code(c.muted), info.coords))
            y = y - 20
        end
        self.notes:SetText(info.notes)
        self.notes:ClearAllPoints()
        self.notes:SetPoint("TOPLEFT", 16, y)
        y = y - self.notes:GetStringHeight() - 14
        self:SetHeight(-y)
    end
    return card
end

local function BuildWorkbenchCard(parent, width)
    local c = T.colors
    local card = CreateFrame("Frame", nil, parent)
    card:SetWidth(width)
    W.Box(card, c.surface, c.surfaceBorder, T.metrics.surfaceRadius)
    card.stripe = W.Line(card, c.accent, "ARTWORK")
    card.stripe:SetHeight(3)
    card.stripe:SetPoint("TOPLEFT", 10, -1)
    card.stripe:SetPoint("TOPRIGHT", -10, -1)
    card.pill = CreateFrame("Frame", nil, card)
    card.pill:SetHeight(20)
    W.Box(card.pill, Dim(c.accent, 0.18), Dim(c.accent, 0.18), 10)
    card.pillIcon = W.Icon(card.pill, "prof_alchemy", 12, c.accent)
    card.pillIcon:SetPoint("LEFT", 8, 0)
    card.pillText = W.Text(card.pill, T, "kicker", c.accent)
    card.pillText:SetPoint("LEFT", card.pillIcon, "RIGHT", 5, 0)
    card.posText = W.Text(card, T, "small", c.muted)
    card.posText:SetPoint("TOPRIGHT", -14, -17)
    card.name = W.Wrap(W.Text(card, T, "heading", c.heading), width - 28)
    card.pin = W.Icon(card, "icon_pin", 13, c.muted)
    card.loc = W.Text(card, T, "body", c.text)
    card.badge = CreateFrame("Frame", nil, card)
    card.badge:SetHeight(20)
    W.Box(card.badge, c.surfaceHover, c.surfaceHover, 4)
    card.badgeText = W.Text(card.badge, T, "small", c.text)
    card.badgeText:SetPoint("CENTER")
    card.notes = W.Wrap(W.Text(card, T, "body", c.body), width - 28)
    function card:Update(info)
        local active = info.zone ~= nil
        local color = PKT.ProfColor(T, info.profID)
        W.SetColor(self.stripe, active and color or c.line)
        self.pill:SetShown(active)
        self.posText:SetShown(active)
        local y = -14
        if active then
            W.SetColor(self.pill.boxFill, Dim(color, 0.18))
            W.SetColor(self.pill.boxBorder, Dim(color, 0.18))
            self.pillIcon:SetTexture(PKT.TEX .. (PKT.PROF_ICONS[info.profID] or "icon_chest"))
            W.SetColor(self.pillIcon, color)
            SetTextColor(self.pillText, color)
            self.pillText:SetText(info.profName)
            self.pill:SetWidth(8 + 12 + 5 + self.pillText:GetStringWidth() + 10)
            self.pill:ClearAllPoints()
            self.pill:SetPoint("TOPLEFT", 14, -13)
            self.posText:SetText(info.position)
            y = y - 28
        end
        self.name:SetText(info.name)
        self.name:ClearAllPoints()
        self.name:SetPoint("TOPLEFT", 14, y)
        y = y - self.name:GetStringHeight() - 8
        self.pin:SetShown(active)
        self.loc:SetShown(active)
        self.badge:SetShown(active)
        if active then
            self.pin:ClearAllPoints()
            self.pin:SetPoint("TOPLEFT", 14, y - 2)
            self.loc:ClearAllPoints()
            self.loc:SetPoint("TOPLEFT", 33, y - 1)
            self.loc:SetText(info.zone)
            self.badgeText:SetText(info.coords)
            self.badge:SetWidth(self.badgeText:GetStringWidth() + 14)
            self.badge:ClearAllPoints()
            self.badge:SetPoint("TOPRIGHT", -14, y + 2)
            y = y - 24
        end
        self.notes:SetText(info.notes)
        self.notes:ClearAllPoints()
        self.notes:SetPoint("TOPLEFT", 14, y)
        y = y - self.notes:GetStringHeight() - 14
        self:SetHeight(-y)
    end
    return card
end

local function BuildHouseCard(parent, width)
    local c = T.colors
    local card = CreateFrame("Frame", nil, parent)
    card:SetWidth(width)
    card.tile = CreateFrame("Frame", nil, card)
    card.tile:SetSize(44, 44)
    card.tile:SetPoint("TOPLEFT", 0, 0)
    W.Box(card.tile, c.surface, c.surfaceBorder, 0)
    card.tileIcon = W.Icon(card.tile, "icon_chest", 22, c.accent)
    card.tileIcon:SetPoint("CENTER")
    card.name = W.Wrap(W.Text(card, T, "heading", c.heading), width - 56)
    card.name:SetPoint("TOPLEFT", 56, -2)
    card.loc = W.Text(card, T, "body", c.muted)
    card.notes = W.Wrap(W.Text(card, T, "body", c.body), width)
    card.divider = W.Line(card, Dim(c.line, 0.6))
    card.divider:SetHeight(1)
    card.divider:SetPoint("LEFT", 0, 0)
    card.divider:SetPoint("RIGHT", 0, 0)
    function card:Update(info)
        local active = info.zone ~= nil
        self.tileIcon:SetTexture(PKT.TEX .. (active and PKT.PROF_ICONS[info.profID] or "icon_chest"))
        self.name:SetText(info.name)
        local top = self.name:GetStringHeight() + 4
        self.loc:SetShown(active)
        if active then
            self.loc:ClearAllPoints()
            self.loc:SetPoint("TOPLEFT", 56, -2 - top)
            self.loc:SetText(format("%s  %s%s|r", info.zone, Code(c.accent), info.coords))
            top = top + 18
        end
        local y = -max(48, top + 6)
        self.notes:SetText(info.notes)
        self.notes:ClearAllPoints()
        self.notes:SetPoint("TOPLEFT", 0, y)
        y = y - self.notes:GetStringHeight() - 12
        self.divider:ClearAllPoints()
        self.divider:SetPoint("TOPLEFT", 0, y)
        self.divider:SetPoint("TOPRIGHT", 0, y)
        self:SetHeight(-y + 1)
    end
    return card
end

local function BuildProgressRow(parent, width)
    local c, s = T.colors, T.style
    local row = CreateFrame("Frame", nil, parent)
    row:SetWidth(width)
    if s.progress == "bars" then
        row:SetHeight(26)
        local chip = CreateFrame("Frame", nil, row)
        chip:SetSize(26, 26)
        chip:SetPoint("LEFT", 0, 0)
        W.Box(chip, c.surface, c.windowBorder, "circle")
        row.icon = W.Icon(chip, "prof_alchemy", 14, c.accent)
        row.icon:SetPoint("CENTER")
        row.name = W.Text(row, T, "small", c.text)
        row.name:SetPoint("TOPLEFT", 36, -1)
        row.count = W.Text(row, T, "small", c.muted)
        row.count:SetPoint("TOPRIGHT", 0, -1)
        row.bar = W.Bar(row, T)
        row.bar:SetPoint("BOTTOMLEFT", 36, 1)
        row.bar:SetPoint("BOTTOMRIGHT", 0, 1)
    elseif s.progress == "pips" then
        row:SetHeight(24)
        row.name = W.Text(row, T, "strong", c.text)
        row.name:SetPoint("TOPLEFT", 0, 0)
        row.count = W.Text(row, T, "small", c.muted)
        row.count:SetPoint("TOPRIGHT", 0, 0)
        row.pips = W.Pips(row, T)
        row.pips:SetPoint("BOTTOMLEFT", 0, 0)
        row.pips:SetPoint("BOTTOMRIGHT", 0, 0)
    else
        row:SetHeight(16)
        row.name = W.Text(row, T, "small", c.text)
        row.name:SetPoint("LEFT", 0, 0)
        row.name:SetWidth(96)
        row.count = W.Text(row, T, "small", c.muted)
        row.count:SetPoint("RIGHT", 0, 0)
        row.count:SetWidth(36)
        row.count:SetJustifyH("RIGHT")
        row.bar = W.Bar(row, T)
        row.bar:SetPoint("LEFT", 104, 0)
        row.bar:SetPoint("RIGHT", -44, 0)
    end
    function row:Update(entry)
        local collected = entry.total - entry.remaining
        local color = PKT.ProfColor(T, entry.profID)
        self.name:SetText(entry.name)
        if self.icon then
            self.icon:SetTexture(PKT.TEX .. (PKT.PROF_ICONS[entry.profID] or "icon_chest"))
        end
        if self.pips then
            self.count:SetText(format(L.COUNT_OF, collected, entry.total))
            self.pips:SetPips(entry.total, collected, color)
        else
            self.count:SetText(format(s.progress == "bars" and L.COUNT_OF or L.COUNT_OF_SHORT, collected, entry.total))
            self.bar:SetProgress(entry.total > 0 and collected / entry.total or 0, color)
        end
    end
    return row
end

local function BuildZone(parent, width)
    local c, s = T.colors, T.style
    local zone = CreateFrame("Frame", nil, parent)
    zone:SetWidth(width)
    local textLeft, textWidth, top = 0, width, 0
    if s.zoneBox then
        W.Box(zone, c.surface, c.surfaceBorder, T.metrics.surfaceRadius)
        zone.icon = W.Icon(zone, "icon_pin", 14, c.accent)
        zone.icon:SetPoint("TOPLEFT", 12, -10)
        textLeft, textWidth, top = 34, width - 46, -10
        zone.count = W.Text(zone, T, "strong", c.accent)
        zone.count:SetPoint("TOPRIGHT", -12, -10)
    elseif s.zoneDot then
        zone.dot = W.Shape(zone, "ARTWORK", 0, "circle")
        zone.dot:SetSize(8, 8)
        zone.dot:SetPoint("TOPLEFT", 0, -4)
        textLeft, textWidth = 16, width - 16
    end
    zone.text = W.Text(zone, T, "small", c.body)
    zone.text:SetPoint("TOPLEFT", textLeft, top)
    zone.hint = W.Wrap(W.Text(zone, T, "strong", c.accent), textWidth)
    function zone:Update(snap)
        local zoneName = Code(c.heading) .. snap.zoneName .. "|r"
        if s.zoneBox then
            self.text:SetText(format(L.YOU_ARE_IN, zoneName))
            self.count:SetText(snap.here > 0 and format(L.HERE_COUNT, snap.here) or L.NONE_HERE)
            SetTextColor(self.count, snap.here > 0 and c.accent or c.muted)
        else
            local key = snap.here > 0 and L.IN_ZONE_HERE or L.IN_ZONE_NONE
            self.text:SetText(format(key, zoneName, snap.here))
            if self.dot then W.SetColor(self.dot, snap.here > 0 and c.good or c.muted) end
        end
        local h = 16
        self.hint:SetShown(snap.hint ~= nil)
        if snap.hint then
            self.hint:SetText(snap.hint)
            self.hint:ClearAllPoints()
            self.hint:SetPoint("TOPLEFT", textLeft, top - 18)
            h = h + 4 + self.hint:GetStringHeight()
        end
        self:SetHeight(h - top * 2)
    end
    return zone
end

local function BuildFooter(f, width)
    local c, m, s = T.colors, T.metrics, T.style
    local footer = CreateFrame("Frame", nil, f)
    footer:SetWidth(width)
    local defs = {
        { label = L.BTN_PREV, onClick = function() PKT.GoPrev() end, icon = "icon_chevron_left", tip = L.TIP_PREV },
        { label = L.BTN_NEAREST, onClick = function() PKT.GoNearest() end },
        { label = L.BTN_FIRST, onClick = function() PKT.GoFirst() end },
        { label = L.BTN_RELOAD, onClick = function() PKT.Reload() end, icon = "icon_reload", tip = L.TIP_RELOAD },
        { label = L.BTN_NEXT, onClick = function() PKT.GoNext() end, primary = true },
    }
    local gap = s.footerBar and 6 or 6
    if s.footerBar then
        footer:SetHeight(m.buttonHeight + 24)
        W.HalfRounded(footer, c.header, m.windowRadius, "BOTTOM", m.buttonHeight + 24)
        W.HLine(footer, c.line, "TOP", 0, 0)
        local iconW = 36
        local flexTotal = width - 24 - iconW * 2 - gap * 4
        local x = 12
        for _, d in ipairs(defs) do
            local b
            if s.iconNavButtons and d.icon then
                b = W.IconButton(footer, T, d.icon, d.onClick, d.tip, false, m.buttonHeight)
                b:SetWidth(iconW)
            else
                b = W.Button(footer, T, d.label, d.primary, d.onClick)
                local share = d.primary and 1.4 or 1
                b:SetWidth(floor(flexTotal * share / 3.4))
            end
            b:SetPoint("LEFT", x, 0)
            x = x + b:GetWidth() + gap
        end
    else
        footer:SetHeight(m.buttonHeight)
        local bw = (width - gap * 4) / 5
        for i, d in ipairs(defs) do
            local b = W.Button(footer, T, d.label, d.primary, d.onClick)
            b:SetWidth(bw)
            b:SetPoint("LEFT", (i - 1) * (bw + gap), 0)
        end
    end
    return footer
end

local function BuildTracker()
    local c, m, s = T.colors, T.metrics, T.style
    local f = W.Window(T, TRACKER_WIDTH, 420, "MEDIUM", true)
    local header = W.Header(f, T, s.titleText, {
        { key = "minimize", icon = "icon_minus", tooltip = L.TIP_MINIMIZE, onClick = function() PKT.SetMinimized(true) end },
        { key = "settings", icon = s.settingsIcon, tooltip = L.TIP_SETTINGS, onClick = function() PKT.ToggleSettingsUI() end },
        { key = "close", icon = "icon_close", tooltip = L.TIP_CLOSE, round = s.roundClose, onClick = function() PKT.StopTracking(); PKT.HideUI() end },
    })
    f.badge = W.Text(header, T, "kicker", c.badge)
    f.badge:SetPoint("LEFT", header.title, "RIGHT", 8, 0)
    f.badge:SetText(L.TEST_BADGE)
    if s.headerCount then
        f.headerCount = W.Text(header, T, "small", c.muted)
        f.headerCount:SetPoint("RIGHT", header.leftmostButton, "LEFT", -10, 0)
    end
    local inset = Inset()
    local pad = m.padding
    local inner = TRACKER_WIDTH - inset * 2 - pad * 2
    if s.brackets then
        f.card = BuildLedgerCard(f, inner)
    elseif s.stripe then
        f.card = BuildWorkbenchCard(f, inner)
    else
        f.card = BuildHouseCard(f, inner)
    end
    if s.progressHeader then
        f.progressTitle = W.Text(f, T, "section", c.title)
        f.progressTitle:SetText(L.PROGRESS)
        f.progressCount = W.Text(f, T, "small", c.muted)
    end
    f.rows = {}
    f.zone = BuildZone(f, inner)
    f.footer = BuildFooter(f, s.footerBar and (TRACKER_WIDTH - inset * 2) or inner)
    if s.footerBar then
        f.footer:SetPoint("BOTTOMLEFT", inset, inset)
    else
        f.footer:SetPoint("BOTTOMLEFT", inset + pad, inset + pad)
    end
    f.inner, f.pad, f.inset = inner, pad, inset
    return f
end

local function UpdateTracker(f)
    local m, s = T.metrics, T.style
    local snap = Snapshot()
    f.badge:SetShown(PKT.testMode)
    if f.headerCount then f.headerCount:SetText(format(L.LEFT_COUNT, snap.remaining)) end
    local x = f.inset + f.pad
    local y = f.inset + m.headerHeight + f.pad
    f.card:Update(CardInfo(snap))
    f.card:ClearAllPoints()
    f.card:SetPoint("TOPLEFT", x, -y)
    y = y + f.card:GetHeight() + m.gap
    local breakdown = PKT.GetProfBreakdown()
    if f.progressTitle then
        f.progressTitle:SetShown(#breakdown > 0)
        f.progressCount:SetShown(#breakdown > 0)
        if #breakdown > 0 then
            local collected, total = 0, 0
            for _, e in ipairs(breakdown) do
                collected = collected + e.total - e.remaining
                total = total + e.total
            end
            f.progressTitle:ClearAllPoints()
            f.progressTitle:SetPoint("TOPLEFT", x, -y)
            f.progressCount:SetText(format(L.COLLECTED_OF, collected, total))
            f.progressCount:ClearAllPoints()
            f.progressCount:SetPoint("TOPRIGHT", -x, -y)
            y = y + 22
        end
    end
    for i, entry in ipairs(breakdown) do
        local row = f.rows[i]
        if not row then
            row = BuildProgressRow(f, f.inner)
            f.rows[i] = row
        end
        row:Show()
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", x, -y)
        row:Update(entry)
        y = y + row:GetHeight() + 10
    end
    for i = #breakdown + 1, #f.rows do f.rows[i]:Hide() end
    if #breakdown > 0 then y = y + 2 end
    f.zone:Update(snap)
    f.zone:ClearAllPoints()
    f.zone:SetPoint("TOPLEFT", x, -y)
    y = y + f.zone:GetHeight() + m.gap
    local bottom = s.footerBar and (f.footer:GetHeight() + f.inset) or (f.footer:GetHeight() + f.pad + f.inset)
    f:SetHeight(floor(y + bottom + 0.5))
end

local function BuildMini()
    local c, s = T.colors, T.style
    local f = W.Window(T, TRACKER_WIDTH, 50, "MEDIUM", true)
    local inset = Inset()
    f.icon = W.Icon(f, "icon_chest", 18, c.accent)
    f.icon:SetPoint("LEFT", inset + 12, 0)
    f.expand = W.IconButton(f, T, "icon_chevron_down", function() PKT.SetMinimized(false) end, L.TIP_EXPAND)
    f.expand:SetPoint("RIGHT", -inset - 10, 0)
    f.next = W.IconButton(f, T, "icon_chevron_right", function() PKT.GoNext() end, L.TIP_NEXT)
    f.next:SetPoint("RIGHT", f.expand, "LEFT", -6, 0)
    local textWidth = TRACKER_WIDTH - inset * 2 - 12 - 18 - 10 - 10 - T.metrics.iconButton * 2 - 6 - 10
    f.name = W.Text(f, T, "strong", c.heading)
    f.name:SetPoint("TOPLEFT", inset + 40, -9)
    f.name:SetWidth(textWidth)
    PKT.ApplyFont(f.name, T, s.stripe and "section" or "strong")
    f.sub = W.Text(f, T, "small", c.muted)
    f.sub:SetPoint("TOPLEFT", f.name, "BOTTOMLEFT", 0, -3)
    f.sub:SetWidth(textWidth)
    return f
end

local function UpdateMini(f)
    local c = T.colors
    local snap = Snapshot()
    local t = snap.current
    f.next:SetShown(snap.state == "active" or snap.state == "idle")
    if snap.state == "active" then
        local color = PKT.ProfColor(T, t.prof)
        f.icon:SetTexture(PKT.TEX .. (PKT.PROF_ICONS[t.prof] or "icon_chest"))
        W.SetColor(f.icon, color)
        f.name:SetText(t.name)
        f.sub:SetText(format("%s  %s%.1f, %.1f|r  \194\183  %s", PKT.ZONE_NAMES[t.mapID] or L.UNKNOWN, Code(c.accent), t.x * 100, t.y * 100, format(L.LEFT_COUNT, snap.remaining)))
    else
        f.icon:SetTexture(PKT.TEX .. "icon_chest")
        W.SetColor(f.icon, c.accent)
        local info = CardInfo(snap)
        f.name:SetText(info.name)
        if snap.state == "done" then
            f.sub:SetText(L.MINI_ALL_DONE)
        elseif snap.state == "idle" then
            f.sub:SetText(format(L.MINI_IDLE, snap.remaining))
        else
            f.sub:SetText(info.notes)
        end
    end
end

local function EnsureTracker(set)
    if not set.tracker then set.tracker = BuildTracker() end
    if not set.mini then set.mini = BuildMini() end
end

local function TrackerVisible(set)
    return (set.tracker and set.tracker:IsShown()) or (set.mini and set.mini:IsShown())
end

local function VisibleTrackerFrame(set)
    if set.tracker and set.tracker:IsShown() then return set.tracker end
    if set.mini and set.mini:IsShown() then return set.mini end
end

function PKT.UpdateUI()
    local set = sets[PKT.GetTheme().key]
    if not set then return end
    T = PKT.GetTheme()
    if set.tracker and set.tracker:IsShown() then UpdateTracker(set.tracker) end
    if set.mini and set.mini:IsShown() then UpdateMini(set.mini) end
end

function PKT.ShowUI()
    if not PKT.HasChosenTheme() then
        PKT.ShowThemePicker(true)
        return
    end
    local set = CurrentSet()
    EnsureTracker(set)
    local minimized = PKT_SavedVars.minimized == true
    local show = minimized and set.mini or set.tracker
    local hide = minimized and set.tracker or set.mini
    hide:Hide()
    W.RestorePosition(show)
    show:Show()
    PKT.UpdateUI()
end

function PKT.HideUI()
    local set = sets[PKT.GetTheme().key]
    if not set then return end
    if set.tracker then set.tracker:Hide() end
    if set.mini then set.mini:Hide() end
end

function PKT.ToggleUI()
    local set = sets[PKT.GetTheme().key]
    if set and TrackerVisible(set) then
        PKT.HideUI()
    else
        PKT.ShowUI()
    end
end

function PKT.SetMinimized(on)
    PKT_SavedVars.minimized = on and true or false
    local set = CurrentSet()
    local visible = VisibleTrackerFrame(set)
    if visible then W.SavePosition(visible) end
    if visible or on == false then PKT.ShowUI() end
end

function PKT.ToggleMinimized()
    PKT.SetMinimized(not PKT_SavedVars.minimized)
end

local function BuildDMFContent(q, current)
    local c = T.colors
    if not q then return Code(c.muted) .. L.DMF_NO_DATA .. "|r" end
    local head, muted, accent = Code(c.title), Code(c.muted), Code(c.accent)
    local lines = {}
    lines[#lines + 1] = head .. L.DMF_VENDOR .. "|r  " .. q.vendor
    lines[#lines + 1] = muted .. format(L.DMF_COORDS, q.x * 100, q.y * 100) .. "|r"
    lines[#lines + 1] = " "
    lines[#lines + 1] = accent .. L.DMF_BRING .. "|r"
    if q.needed and #q.needed > 0 then
        for _, item in ipairs(q.needed) do
            lines[#lines + 1] = "  " .. format(L.DMF_BRING_ITEM, item.count, item.name)
            lines[#lines + 1] = "    " .. muted .. item.tip .. "|r"
        end
    else
        lines[#lines + 1] = "  " .. muted .. L.DMF_BRING_NOTHING .. "|r"
    end
    if q.provided and #q.provided > 0 then
        lines[#lines + 1] = " "
        lines[#lines + 1] = accent .. L.DMF_PROVIDES .. "|r"
        for _, p in ipairs(q.provided) do
            lines[#lines + 1] = "  " .. p
        end
    end
    lines[#lines + 1] = " "
    lines[#lines + 1] = accent .. L.DMF_HOW_TO .. "|r"
    for i, step in ipairs(q.steps) do
        local line = format(L.DMF_STEP, i, step)
        if i == current then line = accent .. line .. "|r" end
        lines[#lines + 1] = line
    end
    return table.concat(lines, "\n")
end

local dmf = { profList = {}, profIndex = 1, steps = {} }

local function DMFEntry()
    return dmf.profList[dmf.profIndex]
end

local function DMFStepNumber(entry)
    return math.min(dmf.steps[entry.profID] or 1, #entry.quest.steps)
end

local function DMFSwitch(dir)
    local count = #dmf.profList
    if count == 0 then return end
    dmf.profIndex = (dmf.profIndex - 1 + dir) % count + 1
    PKT.UpdateDMFUI()
end

local function DMFAdvance(dir)
    local entry = DMFEntry()
    if not entry then return end
    local count = #entry.quest.steps
    local step = DMFStepNumber(entry)
    if entry.done then step = dir > 0 and count or 1 end
    step = step + dir
    if step > count then
        if dmf.profIndex >= #dmf.profList then return end
        dmf.profIndex = dmf.profIndex + 1
        dmf.steps[DMFEntry().profID] = 1
    elseif step < 1 then
        if dmf.profIndex <= 1 then return end
        dmf.profIndex = dmf.profIndex - 1
        local previous = DMFEntry()
        dmf.steps[previous.profID] = #previous.quest.steps
    else
        dmf.steps[entry.profID] = step
    end
    PKT.UpdateDMFUI()
end

local function BuildDMF()
    local c, m = T.colors, T.metrics
    local width = 400
    local f = W.Window(T, width, 440, "HIGH", "dmfPos")
    W.Header(f, T, L.DMF_TITLE, {
        { key = "minimize", icon = "icon_minus", tooltip = L.TIP_MINIMIZE, onClick = function() PKT.SetDMFMinimized(true) end },
        { key = "close", icon = "icon_close", tooltip = L.TIP_CLOSE, round = T.style.roundClose, onClick = function() f:Hide() end },
    })
    f.badge = W.Text(f.header, T, "kicker", c.badge)
    f.badge:SetPoint("LEFT", f.header.title, "RIGHT", 8, 0)
    f.badge:SetText(L.TEST_BADGE)
    local inset, pad = Inset(), m.padding
    local inner = width - inset * 2 - pad * 2
    f.profName = W.Text(f, T, "heading", c.heading)
    f.profName:SetPoint("TOPLEFT", inset + pad, -(inset + m.headerHeight + pad))
    f.status = W.Text(f, T, "strong", c.accent)
    f.status:SetPoint("TOPRIGHT", -(inset + pad), -(inset + m.headerHeight + pad + 4))
    f.content = W.Wrap(W.Text(f, T, "body", c.text), inner)
    f.content:SetSpacing(2)
    local prev = W.Button(f, T, L.BTN_PREV, false, function() DMFSwitch(-1) end)
    local nextBtn = W.Button(f, T, L.BTN_NEXT, true, function() DMFSwitch(1) end)
    prev:SetWidth(90)
    nextBtn:SetWidth(90)
    prev:SetPoint("BOTTOMRIGHT", f, "BOTTOM", -4, inset + pad)
    nextBtn:SetPoint("BOTTOMLEFT", f, "BOTTOM", 4, inset + pad)
    f.page = W.Text(f, T, "small", c.muted)
    f.page:SetPoint("BOTTOMRIGHT", -(inset + pad), inset + pad + 8)
    f.inset, f.pad = inset, pad
    return f
end

local function BuildDMFMini()
    local c, m = T.colors, T.metrics
    local width = 380
    local f = W.Window(T, width, 90, "HIGH", "dmfPos")
    local inset, size = Inset(), m.iconButton
    local rowTop = inset + 8
    f.icon = W.Icon(f, "icon_chest", 18, c.accent)
    f.icon:SetPoint("TOPLEFT", inset + 12, -(rowTop + floor((size - 18) / 2)))
    local close = W.IconButton(f, T, "icon_close", function() f:Hide() end, L.TIP_CLOSE, T.style.roundClose)
    close:SetPoint("TOPRIGHT", -(inset + 8), -rowTop)
    local expand = W.IconButton(f, T, "icon_chevron_down", function() PKT.SetDMFMinimized(false) end, L.TIP_EXPAND)
    expand:SetPoint("RIGHT", close, "LEFT", -5, 0)
    f.next = W.IconButton(f, T, "icon_chevron_right", function() DMFAdvance(1) end, L.TIP_NEXT_STEP)
    f.next:SetPoint("RIGHT", expand, "LEFT", -5, 0)
    f.prev = W.IconButton(f, T, "icon_chevron_left", function() DMFAdvance(-1) end, L.TIP_PREV_STEP)
    f.prev:SetPoint("RIGHT", f.next, "LEFT", -5, 0)
    f.title = W.Text(f, T, "section", c.heading)
    f.title:SetPoint("TOPLEFT", inset + 40, -(rowTop + floor((size - 14) / 2)))
    f.title:SetWidth(width - (inset + 40) - (inset + 8) - size * 4 - 15 - 8)
    f.stepLabel = W.Text(f, T, "kicker", c.accent)
    f.stepLabel:SetPoint("TOPLEFT", inset + 14, -(rowTop + size + 8))
    f.body = W.Wrap(W.Text(f, T, "body", c.text), width - (inset + 14) * 2)
    f.inset, f.size, f.rowTop = inset, size, rowTop
    return f
end

local function UpdateDMFFull(f)
    local c, m = T.colors, T.metrics
    f.badge:SetShown(PKT.testMode)
    local top = f.inset + m.headerHeight + f.pad
    local entry = DMFEntry()
    if not entry then
        f.profName:SetText(L.DMF_NO_PROFS)
        f.status:SetText("")
        f.content:SetText(L.DMF_NONE_FOUND)
        f.page:SetText("")
    else
        f.profName:SetText(entry.name)
        f.status:SetText(entry.done and L.DMF_DONE or L.DMF_AVAILABLE)
        SetTextColor(f.status, entry.done and c.good or c.accent)
        f.content:SetText(BuildDMFContent(entry.quest, not entry.done and DMFStepNumber(entry) or nil))
        f.page:SetText(format(L.COUNT_OF, dmf.profIndex, #dmf.profList))
    end
    local nameH = f.profName:GetStringHeight()
    f.content:ClearAllPoints()
    f.content:SetPoint("TOPLEFT", f.inset + f.pad, -(top + nameH + 12))
    f:SetHeight(floor(top + nameH + 12 + f.content:GetStringHeight() + 20 + m.buttonHeight + f.pad + f.inset + 0.5))
end

local function UpdateDMFMini(f)
    local c = T.colors
    local entry = DMFEntry()
    f.prev:SetShown(entry ~= nil)
    f.next:SetShown(entry ~= nil)
    if not entry then
        f.icon:SetTexture(PKT.TEX .. "icon_chest")
        W.SetColor(f.icon, c.accent)
        f.title:SetText(L.DMF_TITLE)
        f.stepLabel:SetText("")
        f.body:SetText(L.DMF_NONE_FOUND)
    else
        local color = PKT.ProfColor(T, entry.profID)
        f.icon:SetTexture(PKT.TEX .. (PKT.PROF_ICONS[entry.profID] or "icon_chest"))
        W.SetColor(f.icon, color)
        f.title:SetText(entry.name)
        if entry.done then
            f.stepLabel:SetText(L.DMF_DONE)
            SetTextColor(f.stepLabel, c.good)
            f.body:SetText(L.DMF_QUEST_DONE)
        else
            local step = DMFStepNumber(entry)
            f.stepLabel:SetText(format(L.DMF_STEP_OF, step, #entry.quest.steps))
            SetTextColor(f.stepLabel, color)
            f.body:SetText(entry.quest.steps[step])
        end
    end
    local bodyTop = f.rowTop + f.size + 8 + 18
    f.body:ClearAllPoints()
    f.body:SetPoint("TOPLEFT", f.inset + 14, -bodyTop)
    f:SetHeight(floor(bodyTop + f.body:GetStringHeight() + 14 + f.inset + 0.5))
end

function PKT.UpdateDMFUI()
    local set = sets[PKT.GetTheme().key]
    if not set then return end
    T = PKT.GetTheme()
    if set.dmf and set.dmf:IsShown() then UpdateDMFFull(set.dmf) end
    if set.dmfMini and set.dmfMini:IsShown() then UpdateDMFMini(set.dmfMini) end
end

function PKT.ShowDMFUI()
    if not PKT.HasChosenTheme() then return end
    local set = CurrentSet()
    if not set.dmf then set.dmf = BuildDMF() end
    if not set.dmfMini then set.dmfMini = BuildDMFMini() end
    dmf.profList = PKT.GetActiveDMFProfs()
    if dmf.profIndex > #dmf.profList then dmf.profIndex = 1 end
    local minimized = PKT_SavedVars.dmfMinimized == true
    local show = minimized and set.dmfMini or set.dmf
    local hide = minimized and set.dmf or set.dmfMini
    hide:Hide()
    W.RestorePosition(show)
    show:Show()
    PKT.UpdateDMFUI()
end

local function VisibleDMFFrame(set)
    if set.dmf and set.dmf:IsShown() then return set.dmf end
    if set.dmfMini and set.dmfMini:IsShown() then return set.dmfMini end
end

function PKT.SetDMFMinimized(on)
    PKT_SavedVars.dmfMinimized = on and true or false
    local set = sets[PKT.GetTheme().key]
    local visible = set and VisibleDMFFrame(set)
    if visible then
        W.SavePosition(visible)
        PKT.ShowDMFUI()
    end
end

function PKT.HideDMFUI()
    local set = sets[PKT.GetTheme().key]
    if not set then return end
    if set.dmf then set.dmf:Hide() end
    if set.dmfMini then set.dmfMini:Hide() end
end

function PKT.IsDMFShown()
    local set = sets[PKT.GetTheme().key]
    return set ~= nil and VisibleDMFFrame(set) ~= nil
end

function PKT.ToggleDMFUI()
    if PKT.IsDMFShown() then PKT.HideDMFUI() else PKT.ShowDMFUI() end
end

local WAYPOINT_OPTIONS = {
    { key = "both",   label = L.WAYPOINT_BOTH },
    { key = "native", label = L.WAYPOINT_NATIVE },
    { key = "tomtom", label = L.WAYPOINT_TOMTOM },
    { key = "none",   label = L.WAYPOINT_NONE },
}

local function AnchorBesideTracker(f)
    local set = sets[T.key]
    local anchor = set and VisibleTrackerFrame(set)
    f:ClearAllPoints()
    if anchor then
        f:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 8, 0)
    else
        f:SetPoint("CENTER", 0, 0)
    end
end

local function BuildSettings()
    local c, m = T.colors, T.metrics
    local width = 300
    local f = W.Window(T, width, 400, "HIGH", false)
    W.Header(f, T, L.SETTINGS_TITLE, {
        { key = "close", icon = "icon_close", tooltip = L.TIP_CLOSE, round = T.style.roundClose, onClick = function() f:Hide() end },
    })
    local inset, pad = Inset(), m.padding
    local x = inset + pad
    local inner = width - x * 2
    local y = inset + m.headerHeight + pad
    local function Section(label)
        local t = W.Text(f, T, "section", c.title)
        t:SetPoint("TOPLEFT", x, -y)
        t:SetText(label)
        y = y + 22
    end
    local function Divider()
        y = y + 4
        local line = W.Line(f, c.line)
        line:SetHeight(1)
        line:SetPoint("TOPLEFT", x, -y)
        line:SetPoint("TOPRIGHT", -x, -y)
        y = y + 14
    end
    Section(L.APPEARANCE)
    f.lookText = W.Text(f, T, "body", c.body)
    f.lookText:SetPoint("TOPLEFT", x, -y)
    y = y + 22
    local look = W.Button(f, T, L.CHANGE_LOOK, false, function()
        f:Hide()
        PKT.ShowThemePicker(false)
    end)
    look:SetWidth(150)
    look:SetPoint("TOPLEFT", x, -y)
    y = y + m.buttonHeight + 8
    Divider()
    Section(L.WAYPOINT_SYSTEM)
    f.radios = {}
    for _, opt in ipairs(WAYPOINT_OPTIONS) do
        local radio = W.Radio(f, T, opt.label, function()
            PKT_SavedVars.waypointSystem = opt.key
            f:Refresh()
            PKT.OnWaypointSystemChanged(opt.key)
        end)
        radio:SetPoint("TOPLEFT", x + 2, -y)
        radio.key = opt.key
        f.radios[#f.radios + 1] = radio
        y = y + 26
    end
    Divider()
    Section(L.PROFESSIONS_LABEL)
    local profBtn = W.Button(f, T, L.SELECT_MANUALLY, false, function()
        f:Hide()
        PKT.ShowManualProfUI(f)
    end)
    profBtn:SetWidth(150)
    profBtn:SetPoint("TOPLEFT", x, -y)
    y = y + m.buttonHeight + 8
    local hint = W.Wrap(W.Text(f, T, "small", c.muted), inner)
    hint:SetPoint("TOPLEFT", x, -y)
    hint:SetText(L.PROF_HINT)
    y = y + hint:GetStringHeight() + pad + inset
    f:SetHeight(floor(y + 0.5))
    function f:Refresh()
        self.lookText:SetText(format(L.CURRENT_LOOK, Code(c.accent) .. T.name .. "|r"))
        local current = PKT.GetWaypointSystem()
        for _, r in ipairs(self.radios) do r:SetChecked(r.key == current) end
    end
    f:SetScript("OnShow", f.Refresh)
    return f
end

function PKT.ToggleSettingsUI()
    if not PKT.HasChosenTheme() then
        PKT.ShowThemePicker(false)
        return
    end
    local set = CurrentSet()
    if not set.settings then set.settings = BuildSettings() end
    if set.settings:IsShown() then
        set.settings:Hide()
    else
        AnchorBesideTracker(set.settings)
        set.settings:Show()
    end
end

local function SortedProfs()
    local list = {}
    for profID, name in pairs(PKT.PROF_NAMES) do
        list[#list + 1] = { id = profID, name = name }
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

local function BuildProfPicker(title, help, onToggle, leftLabel, onLeft, rightLabel, onRight)
    local c, m = T.colors, T.metrics
    local width = 270
    local f = W.Window(T, width, 300, "HIGH", false)
    W.Header(f, T, title, {
        { key = "close", icon = "icon_close", tooltip = L.TIP_CLOSE, round = T.style.roundClose, onClick = function() f:Hide() end },
    })
    local inset, pad = Inset(), m.padding
    local x = inset + pad
    local inner = width - x * 2
    local y = inset + m.headerHeight + pad
    if help then
        local h = W.Wrap(W.Text(f, T, "small", c.muted), inner)
        h:SetPoint("TOPLEFT", x, -y)
        h:SetText(help)
        y = y + h:GetStringHeight() + 12
    end
    local gap = 6
    local bw = (inner - gap) / 2
    local bh = m.buttonHeight - 4
    f.buttons = {}
    local profs = SortedProfs()
    for i, p in ipairs(profs) do
        local b = W.Toggle(f, T, p.name, function() onToggle(p.id) end)
        b:SetSize(bw, bh)
        local col, row = (i - 1) % 2, floor((i - 1) / 2)
        if i == #profs and #profs % 2 == 1 then
            b:SetPoint("TOPLEFT", x + (inner - bw) / 2, -(y + row * (bh + gap)))
        else
            b:SetPoint("TOPLEFT", x + col * (bw + gap), -(y + row * (bh + gap)))
        end
        f.buttons[p.id] = b
    end
    y = y + math.ceil(#profs / 2) * (bh + gap) + 8
    local left = W.Button(f, T, leftLabel, false, onLeft)
    left:SetSize(bw, m.buttonHeight)
    left:SetPoint("TOPLEFT", x, -y)
    local right = W.Button(f, T, rightLabel, true, onRight or function() f:Hide() end)
    right:SetSize(bw, m.buttonHeight)
    right:SetPoint("TOPRIGHT", -x, -y)
    y = y + m.buttonHeight + pad + inset
    f:SetHeight(floor(y + 0.5))
    return f
end

function PKT.RefreshTestProfButtons()
    local set = sets[PKT.GetTheme().key]
    local f = set and set.testProf
    if not f then return end
    for profID, b in pairs(f.buttons) do b:SetSelected(PKT.testProfs[profID] == true) end
end

local function EnsureTestProf()
    local set = CurrentSet()
    if not set.testProf then
        set.testProf = BuildProfPicker(L.TEST_PROFS_TITLE, nil,
            function(profID)
                PKT.testProfs[profID] = not PKT.testProfs[profID] or nil
                PKT.Reload()
                PKT.UpdateUI()
                PKT.RefreshTestProfButtons()
            end,
            L.BTN_ALL, function()
                for profID in pairs(PKT.PROF_NAMES) do PKT.testProfs[profID] = true end
                PKT.Reload()
                PKT.UpdateUI()
                PKT.RefreshTestProfButtons()
            end,
            L.BTN_NONE, function()
                PKT.testProfs = {}
                PKT.Reload()
                PKT.UpdateUI()
                PKT.RefreshTestProfButtons()
            end)
    end
    return set.testProf
end

function PKT.ShowTestProfUI()
    if not PKT.HasChosenTheme() then return end
    local f = EnsureTestProf()
    AnchorBesideTracker(f)
    f:Show()
    PKT.RefreshTestProfButtons()
end

function PKT.HideTestProfUI()
    local set = sets[PKT.GetTheme().key]
    if set and set.testProf then set.testProf:Hide() end
end

function PKT.ToggleTestProfUI()
    local set = sets[PKT.GetTheme().key]
    if set and set.testProf and set.testProf:IsShown() then
        PKT.HideTestProfUI()
    else
        PKT.ShowTestProfUI()
    end
end

function PKT.RefreshManualProfButtons()
    local set = sets[PKT.GetTheme().key]
    local f = set and set.manualProf
    if not f then return end
    local manual = PKT.GetManualProfs()
    for profID, b in pairs(f.buttons) do b:SetSelected(manual[profID] == true) end
end

local function EnsureManualProf()
    local set = CurrentSet()
    if not set.manualProf then
        set.manualProf = BuildProfPicker(L.SELECT_PROFS_TITLE, L.MANUAL_HELP,
            function(profID)
                local manual = PKT.GetManualProfs()
                local selected = manual[profID] == true
                if not selected then
                    local count = 0
                    for _, on in pairs(manual) do if on then count = count + 1 end end
                    if count >= 2 then
                        UIErrorsFrame:AddMessage(L.MAX_TWO_PROFS, 1, 0.2, 0.2)
                        return
                    end
                end
                PKT.SetManualProf(profID, not selected)
                PKT.Reload()
                if #PKT.GetRouteList() > 0 then PKT.ShowUI() end
                PKT.RefreshManualProfButtons()
            end,
            L.BTN_CLEAR, function()
                for profID in pairs(PKT.PROF_NAMES) do PKT.SetManualProf(profID, false) end
                PKT.Reload()
                if #PKT.GetRouteList() > 0 then PKT.ShowUI() else PKT.UpdateUI() end
                PKT.RefreshManualProfButtons()
            end,
            L.BTN_DONE, nil)
    end
    return set.manualProf
end

function PKT.ShowManualProfUI(anchorTo)
    if not PKT.HasChosenTheme() then return end
    local f = EnsureManualProf()
    f:ClearAllPoints()
    local point, relativeTo, relativePoint, px, py
    if anchorTo then point, relativeTo, relativePoint, px, py = anchorTo:GetPoint() end
    if point then
        f:SetPoint(point, relativeTo, relativePoint, px, py)
    else
        f:SetPoint("CENTER", 0, 0)
    end
    f:Show()
    PKT.RefreshManualProfButtons()
end

function PKT.HideManualProfUI()
    local set = sets[PKT.GetTheme().key]
    if set and set.manualProf then set.manualProf:Hide() end
end

function PKT.ToggleManualProfUI()
    local set = sets[PKT.GetTheme().key]
    if set and set.manualProf and set.manualProf:IsShown() then
        PKT.HideManualProfUI()
    else
        PKT.ShowManualProfUI()
    end
end

local function BuildPreview(parent, PT, width, height)
    local c, s = PT.colors, PT.style
    local p = CreateFrame("Frame", nil, parent)
    p:SetSize(width, height)
    W.Box(p, c.window, c.windowBorder, PT.metrics.windowRadius)
    local headerH = 30
    if s.headerFill then
        local band = CreateFrame("Frame", nil, p)
        band:SetPoint("TOPLEFT", 1, -1)
        band:SetPoint("TOPRIGHT", -1, -1)
        band:SetHeight(headerH - 1)
        W.HalfRounded(band, c.header, PT.metrics.windowRadius, "TOP", headerH - 1)
    end
    local rule = W.Line(p, c.line)
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT", 1, -headerH)
    rule:SetPoint("TOPRIGHT", -1, -headerH)
    local x = 10
    if s.headerIcon then
        local icon = W.Icon(p, s.headerIcon, 13, c.accent)
        icon:SetPoint("TOPLEFT", 10, -9)
        x = 28
    end
    local title = W.Text(p, PT, "title", c.title)
    PKT.ApplyFont(title, { fonts = { title = { PT.fonts.title[1], PT.fonts.title[2] - 3 } } }, "title")
    title:SetPoint("TOPLEFT", x, -9)
    title:SetText(s.uppercaseTitle and L.TITLE_SHORT:upper() or L.TITLE_SHORT)
    local close = W.Icon(p, "icon_close", 10, c.icon)
    close:SetPoint("TOPRIGHT", -10, -10)
    local card = CreateFrame("Frame", nil, p)
    card:SetPoint("TOPLEFT", 10, -(headerH + 10))
    card:SetPoint("TOPRIGHT", -10, -(headerH + 10))
    card:SetHeight(52)
    if s.brackets then
        W.Box(card, c.surface, c.surfaceBorder, PT.metrics.surfaceRadius)
        W.Brackets(card, c.accent, 7, 2)
    elseif s.stripe then
        W.Box(card, c.surface, c.surfaceBorder, 6)
        local stripe = W.Line(card, PKT.ProfColor(PT, 2906), "ARTWORK")
        stripe:SetHeight(3)
        stripe:SetPoint("TOPLEFT", 6, -1)
        stripe:SetPoint("TOPRIGHT", -6, -1)
    else
        local tile = CreateFrame("Frame", nil, card)
        tile:SetSize(30, 30)
        tile:SetPoint("TOPLEFT", 0, -4)
        W.Box(tile, c.surface, c.surfaceBorder, 0)
        local ti = W.Icon(tile, "prof_alchemy", 16, c.accent)
        ti:SetPoint("CENTER")
    end
    local nameX = s.iconTile and 40 or 10
    local name = W.Text(card, PT, "heading", c.heading)
    PKT.ApplyFont(name, { fonts = { heading = { PT.fonts.heading[1], PT.fonts.heading[2] - 4 } } }, "heading")
    name:SetPoint("TOPLEFT", nameX, -9)
    name:SetText(L.PREVIEW_TREASURE)
    local zone = W.Text(card, PT, "small", c.body)
    zone:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
    zone:SetText(L.PREVIEW_ZONE .. "  " .. Code(c.accent) .. "47.8, 51.6|r")
    local progress
    if s.progress == "pips" then
        progress = W.Pips(p, PT)
    else
        progress = W.Bar(p, PT)
    end
    progress:SetPoint("TOPLEFT", card, "BOTTOMLEFT", 0, -12)
    progress:SetPoint("TOPRIGHT", card, "BOTTOMRIGHT", 0, -12)
    p.progress = progress
    local button = W.Button(p, PT, L.BTN_NEXT, true, nil)
    button:SetHeight(24)
    button:SetWidth(70)
    button:EnableMouse(false)
    button:SetPoint("BOTTOMRIGHT", -10, 10)
    local ghost = W.Button(p, PT, L.BTN_PREV, false, nil)
    ghost:SetHeight(24)
    ghost:SetWidth(60)
    ghost:EnableMouse(false)
    ghost:SetPoint("RIGHT", button, "LEFT", -6, 0)
    p:SetScript("OnShow", function(self)
        if s.progress == "pips" then
            self.progress:SetPips(8, 3, PKT.ProfColor(PT, 2906))
        else
            self.progress:SetProgress(0.375, c.accent)
        end
    end)
    return p
end

local function BuildPicker(firstRun)
    local c, m = T.colors, T.metrics
    local cardW, gap, pad = 214, 12, 20
    local width = cardW * 3 + gap * 2 + pad * 2
    local f = W.Window(T, width, 420, "DIALOG", false)
    f:SetPoint("CENTER", 0, 40)
    local buttons = {}
    if not firstRun then
        buttons[1] = { key = "close", icon = "icon_close", tooltip = L.TIP_CLOSE, round = T.style.roundClose, onClick = function() f:Hide() end }
    end
    W.Header(f, T, L.PICKER_TITLE, buttons)
    local inset = Inset()
    local y = inset + m.headerHeight + 16
    local sub = W.Wrap(W.Text(f, T, "body", c.body), width - pad * 2)
    sub:SetPoint("TOPLEFT", pad, -y)
    sub:SetText(L.PICKER_SUBTITLE)
    y = y + sub:GetStringHeight() + 16
    f.cards = {}
    local tallest = 0
    for i, key in ipairs(PKT.THEME_ORDER) do
        local PT = PKT.THEMES[key]
        local card = CreateFrame("Frame", nil, f)
        card:SetWidth(cardW)
        card:SetPoint("TOPLEFT", pad + (i - 1) * (cardW + gap), -y)
        W.Box(card, c.surface, c.surfaceBorder, m.surfaceRadius)
        local preview = BuildPreview(card, PT, cardW - 20, 150)
        preview:SetPoint("TOP", 0, -10)
        local name = W.Text(card, T, "section", c.title)
        name:SetPoint("TOPLEFT", 12, -172)
        name:SetText(PT.name)
        local desc = W.Wrap(W.Text(card, T, "small", c.muted), cardW - 24)
        desc:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -6)
        desc:SetText(PT.desc)
        local cy = 172 + 20 + desc:GetStringHeight() + 14
        local use = W.Button(card, T, L.PICKER_USE, true, function() PKT.SetTheme(key) end)
        use:SetPoint("TOPLEFT", 12, -cy)
        use:SetPoint("TOPRIGHT", -12, -cy)
        card.use = use
        card.current = W.Text(card, T, "strong", c.accent)
        card.current:SetPoint("CENTER", use, "CENTER")
        card.current:SetText(L.PICKER_CURRENT)
        card.key = key
        local h = cy + m.buttonHeight + 12
        tallest = max(tallest, h)
        f.cards[i] = card
    end
    for _, card in ipairs(f.cards) do card:SetHeight(tallest) end
    f:SetHeight(floor(y + tallest + pad + inset + 0.5))
    function f:Refresh()
        local chosen = PKT.HasChosenTheme() and PKT_SavedVars.theme
        for _, card in ipairs(self.cards) do
            local isCurrent = card.key == chosen
            card.use:SetShown(not isCurrent)
            card.current:SetShown(isCurrent)
            W.SetColor(card.boxBorder, isCurrent and c.accent or c.surfaceBorder)
        end
    end
    return f
end

function PKT.ShowThemePicker(firstRun)
    if firstRun then pendingShow = true end
    local set = CurrentSet()
    local key = firstRun and "picker_first" or "picker"
    if not set[key] then set[key] = BuildPicker(firstRun) end
    set[key]:Refresh()
    set[key]:Show()
end

function PKT.SetTheme(key)
    if not PKT.THEMES[key] then return end
    local old = sets[PKT.GetTheme().key]
    local wasVisible, dmfShown = pendingShow, false
    if old then
        local visible = VisibleTrackerFrame(old)
        if visible then
            W.SavePosition(visible)
            wasVisible = true
        end
        local dmfFrame = VisibleDMFFrame(old)
        dmfShown = dmfFrame ~= nil
        if dmfFrame then W.SavePosition(dmfFrame) end
        for _, frame in pairs(old) do frame:Hide() end
    end
    pendingShow = false
    PKT_SavedVars.theme = key
    T = PKT.GetTheme()
    if wasVisible then PKT.ShowUI() end
    if dmfShown then PKT.ShowDMFUI() end
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
        elseif button == "MiddleButton" then
            PKT.ToggleSettingsUI()
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine(L.LDB_TITLE, 1, 0.82, 0)
        tooltip:AddLine(L.LDB_LEFT, 1, 1, 1)
        tooltip:AddLine(L.LDB_RIGHT, 1, 1, 1)
        tooltip:AddLine(L.LDB_MIDDLE, 1, 1, 1)
    end,
})

function PKT.InitUI()
    PKT_SavedVars = PKT_SavedVars or {}
    PKT_SavedVars.minimap = PKT_SavedVars.minimap or { hide = false, minimapPos = 225 }
    if PKT_SavedVars.waypointSystem == nil then PKT_SavedVars.waypointSystem = "both" end
    PKT_CharVars = PKT_CharVars or {}
    PKT_CharVars.manualProfs = PKT_CharVars.manualProfs or {}
    T = PKT.GetTheme()
    local icon = LibStub("LibDBIcon-1.0")
    icon:Register("ProfessionKnowledgeTreasures", ldb, PKT_SavedVars.minimap)
    local iconButton = icon:GetMinimapButton("ProfessionKnowledgeTreasures")
    if iconButton and iconButton.icon then
        iconButton.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    end
end
