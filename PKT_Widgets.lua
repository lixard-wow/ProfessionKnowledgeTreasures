local _, PKT = ...
local W = {}
PKT.W = W

local function SetColor(tex, c)
    tex:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
end
W.SetColor = SetColor

function W.Shape(parent, layer, sublevel, radius)
    local t = parent:CreateTexture(nil, layer, nil, sublevel)
    if radius == "circle" then
        t:SetTexture(PKT.TEX .. "circle")
    elseif radius and radius > 0 then
        local big = radius >= 8
        local margin = big and 10 or 4
        t:SetTexture(PKT.TEX .. (big and "round10" or "round4"))
        t:SetTextureSliceMargins(margin, margin, margin, margin)
        t:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    else
        t:SetColorTexture(1, 1, 1, 1)
    end
    return t
end

function W.Box(frame, fill, border, radius, sublevel)
    sublevel = sublevel or 0
    local outer = W.Shape(frame, "BACKGROUND", sublevel, radius)
    outer:SetAllPoints()
    local inner = W.Shape(frame, "BACKGROUND", sublevel + 1, radius)
    inner:SetPoint("TOPLEFT", 1, -1)
    inner:SetPoint("BOTTOMRIGHT", -1, 1)
    SetColor(outer, border or fill)
    SetColor(inner, fill)
    frame.boxBorder, frame.boxFill = outer, inner
    return outer, inner
end

function W.HalfRounded(frame, color, radius, roundedEdge, height)
    local rounded = W.Shape(frame, "BACKGROUND", 3, radius)
    rounded:SetAllPoints()
    SetColor(rounded, color)
    if radius and radius ~= 0 then
        local flatEdge = roundedEdge == "TOP" and "BOTTOM" or "TOP"
        local square = W.Shape(frame, "BACKGROUND", 3, 0)
        square:SetPoint(flatEdge .. "LEFT", 0, 0)
        square:SetPoint(flatEdge .. "RIGHT", 0, 0)
        square:SetHeight(height / 2)
        SetColor(square, color)
    end
end

function W.Line(parent, color, layer)
    local t = parent:CreateTexture(nil, layer or "ARTWORK")
    t:SetColorTexture(1, 1, 1, 1)
    SetColor(t, color)
    return t
end

function W.HLine(parent, color, anchor, y, inset)
    local t = W.Line(parent, color)
    t:SetHeight(1)
    t:SetPoint(anchor .. "LEFT", inset or 0, y or 0)
    t:SetPoint(anchor .. "RIGHT", -(inset or 0), y or 0)
    return t
end

function W.Text(parent, T, role, color, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    PKT.ApplyFont(fs, T, role)
    local c = color or T.colors.text
    fs:SetTextColor(c[1], c[2], c[3], c[4] or 1)
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetWordWrap(false)
    return fs
end

function W.Wrap(fs, width)
    fs:SetWordWrap(true)
    fs:SetNonSpaceWrap(true)
    if width then fs:SetWidth(width) end
    return fs
end

function W.Icon(parent, name, size, color, layer, sublevel)
    local t = parent:CreateTexture(nil, layer or "ARTWORK", nil, sublevel)
    t:SetTexture(PKT.TEX .. name)
    t:SetSize(size, size)
    SetColor(t, color)
    return t
end

local function ShowTooltip(self)
    if not self.tooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(self.tooltip, 1, 1, 1)
    GameTooltip:Show()
end

local function HideTooltip(self)
    if self.tooltip then GameTooltip:Hide() end
end

function W.Button(parent, T, label, primary, onClick)
    local c = T.colors
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(T.metrics.buttonHeight)
    local fill = primary and c.primary or c.button
    local hover = primary and c.primaryHover or c.buttonHover
    local border = primary and c.primaryBorder or c.buttonBorder
    W.Box(b, fill, border, T.metrics.buttonRadius)
    b.text = W.Text(b, T, "button", primary and c.primaryText or c.buttonText)
    b.text:SetPoint("CENTER", 0, 0)
    b.text:SetJustifyH("CENTER")
    b.text:SetText(label)
    b.fillColor, b.hoverColor = fill, hover
    b:SetScript("OnEnter", function(self)
        SetColor(self.boxFill, self.hoverColor)
        ShowTooltip(self)
    end)
    b:SetScript("OnLeave", function(self)
        SetColor(self.boxFill, self.fillColor)
        HideTooltip(self)
    end)
    b:SetScript("OnMouseDown", function(self) self.text:SetPoint("CENTER", 0, -1) end)
    b:SetScript("OnMouseUp", function(self) self.text:SetPoint("CENTER", 0, 0) end)
    b:SetScript("OnClick", onClick)
    return b
end

function W.IconButton(parent, T, iconName, onClick, tooltip, round, size)
    local c = T.colors
    size = size or T.metrics.iconButton
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(size, size)
    W.Box(b, c.iconButton, c.iconButtonBorder, round and "circle" or T.metrics.buttonRadius)
    b.icon = W.Icon(b, iconName, math.floor(size * 0.5 + 0.5), c.icon)
    b.icon:SetPoint("CENTER")
    b.tooltip = tooltip
    b:SetScript("OnEnter", function(self)
        SetColor(self.icon, c.iconHover)
        SetColor(self.boxFill, c.surfaceHover)
        ShowTooltip(self)
    end)
    b:SetScript("OnLeave", function(self)
        SetColor(self.icon, c.icon)
        SetColor(self.boxFill, c.iconButton)
        HideTooltip(self)
    end)
    b:SetScript("OnClick", onClick)
    return b
end

function W.SetIconButtonIcon(b, iconName)
    b.icon:SetTexture(PKT.TEX .. iconName)
end

function W.Bar(parent, T)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetHeight(T.metrics.barHeight)
    local radius = 0
    if T.key == "ledger" then
        W.Box(bar, T.colors.track, T.colors.line, radius)
    else
        local track = W.Shape(bar, "BACKGROUND", 0, radius)
        track:SetAllPoints()
        SetColor(track, T.colors.track)
    end
    bar.fill = W.Shape(bar, "ARTWORK", 0, radius)
    bar.fill:SetPoint("TOPLEFT", 0, 0)
    bar.fill:SetPoint("BOTTOMLEFT", 0, 0)
    bar.value = 0
    local function Layout(self)
        local w = self:GetWidth()
        if self.value <= 0 or w <= 0 then
            self.fill:Hide()
            return
        end
        self.fill:Show()
        self.fill:SetWidth(math.max(self.value * w, T.metrics.barHeight))
    end
    bar:SetScript("OnSizeChanged", Layout)
    function bar:SetProgress(value, color)
        self.value = math.min(math.max(value or 0, 0), 1)
        SetColor(self.fill, color or T.colors.accent)
        Layout(self)
    end
    return bar
end

function W.Pips(parent, T)
    local pips = CreateFrame("Frame", nil, parent)
    pips:SetHeight(T.metrics.barHeight)
    pips.items = {}
    pips.total, pips.filled = 0, 0
    pips.color = T.colors.accent
    local gap = 3
    local function Layout(self)
        local w = self:GetWidth()
        local n = self.total
        for i, t in ipairs(self.items) do t:SetShown(i <= n) end
        if n == 0 or w <= 0 then return end
        local pw = (w - gap * (n - 1)) / n
        for i = 1, n do
            local t = self.items[i]
            t:ClearAllPoints()
            t:SetPoint("TOPLEFT", (i - 1) * (pw + gap), 0)
            t:SetSize(pw, T.metrics.barHeight)
            SetColor(t, i <= self.filled and self.color or T.colors.track)
        end
    end
    pips:SetScript("OnSizeChanged", Layout)
    function pips:SetPips(total, filled, color)
        self.total, self.filled, self.color = total, filled, color or T.colors.accent
        for i = #self.items + 1, total do
            self.items[i] = W.Shape(self, "ARTWORK", 0, 0)
        end
        Layout(self)
    end
    return pips
end

function W.Radio(parent, T, label, onClick)
    local c = T.colors
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(22)
    local ring = W.Shape(b, "ARTWORK", 0, "circle")
    ring:SetSize(16, 16)
    ring:SetPoint("LEFT", 0, 0)
    SetColor(ring, c.windowBorder)
    local hole = W.Shape(b, "ARTWORK", 1, "circle")
    hole:SetSize(14, 14)
    hole:SetPoint("CENTER", ring)
    SetColor(hole, c.surface)
    b.dot = W.Shape(b, "ARTWORK", 2, "circle")
    b.dot:SetSize(8, 8)
    b.dot:SetPoint("CENTER", ring)
    SetColor(b.dot, c.accent)
    b.text = W.Text(b, T, "body", c.text)
    b.text:SetPoint("LEFT", ring, "RIGHT", 8, 0)
    b.text:SetText(label)
    b:SetWidth(24 + b.text:GetStringWidth() + 8)
    function b:SetChecked(on)
        self.dot:SetShown(on)
        SetColor(ring, on and c.accent or c.windowBorder)
    end
    b:SetScript("OnClick", onClick)
    return b
end

function W.Toggle(parent, T, label, onClick)
    local b = W.Button(parent, T, label, false, onClick)
    function b:SetSelected(on)
        self.selected = on
        SetColor(self.boxBorder, on and T.colors.accent or T.colors.buttonBorder)
        local tc = on and T.colors.accent or T.colors.buttonText
        self.text:SetTextColor(tc[1], tc[2], tc[3], tc[4] or 1)
    end
    return b
end

function W.Brackets(frame, color, size, thickness)
    size, thickness = size or 10, thickness or 2
    local corners = {
        { "TOPLEFT", 1, -1 }, { "TOPRIGHT", -1, -1 },
        { "BOTTOMLEFT", 1, 1 }, { "BOTTOMRIGHT", -1, 1 },
    }
    for _, c in ipairs(corners) do
        local point, sx, sy = c[1], c[2], c[3]
        local h = W.Line(frame, color, "OVERLAY")
        h:SetSize(size, thickness)
        h:SetPoint(point, frame, point, -sx, -sy)
        local v = W.Line(frame, color, "OVERLAY")
        v:SetSize(thickness, size)
        v:SetPoint(point, frame, point, -sx, -sy)
    end
end

local DEFAULT_POSITION_KEY = "trackerPos"

function W.SavePosition(frame)
    local left, top = frame:GetLeft(), frame:GetTop()
    if not left or not top or not PKT_SavedVars then return end
    PKT_SavedVars[frame.positionKey or DEFAULT_POSITION_KEY] = { left = left, top = top }
end

function W.RestorePosition(frame)
    local pos = PKT_SavedVars and PKT_SavedVars[frame.positionKey or DEFAULT_POSITION_KEY]
    frame:ClearAllPoints()
    if pos then
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
    end
end

function W.Window(T, width, height, strata, savesPosition)
    local c, m = T.colors, T.metrics
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(width, height)
    f:SetFrameStrata(strata or "MEDIUM")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    if savesPosition then
        f.positionKey = type(savesPosition) == "string" and savesPosition or DEFAULT_POSITION_KEY
    end
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if self.positionKey then W.SavePosition(self) end
    end)
    W.Box(f, c.window, c.windowBorder, m.windowRadius)
    if T.style.innerFrame then
        local ring = W.Shape(f, "BACKGROUND", 2, m.windowRadius)
        ring:SetPoint("TOPLEFT", 4, -4)
        ring:SetPoint("BOTTOMRIGHT", -4, 4)
        SetColor(ring, c.line)
        local fill = W.Shape(f, "BACKGROUND", 3, m.windowRadius)
        fill:SetPoint("TOPLEFT", 5, -5)
        fill:SetPoint("BOTTOMRIGHT", -5, 5)
        SetColor(fill, c.window)
    end
    f:Hide()
    return f
end

function W.Header(f, T, title, buttons)
    local c, m, s = T.colors, T.metrics, T.style
    local inset = s.innerFrame and 5 or 1
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", inset, -inset)
    header:SetPoint("TOPRIGHT", -inset, -inset)
    header:SetHeight(m.headerHeight)
    if s.headerFill then
        W.HalfRounded(header, c.header, m.windowRadius, "TOP", m.headerHeight)
    end
    W.HLine(header, s.innerFrame and c.line or c.line, "BOTTOM", 0, 0)
    local left = 14
    if s.headerIcon then
        local icon = W.Icon(header, s.headerIcon, 18, c.accent)
        icon:SetPoint("LEFT", 12, 0)
        left = 38
    end
    header.title = W.Text(header, T, "title", c.title)
    header.title:SetPoint("LEFT", left, 0)
    header.title:SetText(s.uppercaseTitle and title:upper() or title)
    local anchor = header
    local anchorPoint = "RIGHT"
    local x = -10
    header.buttons = {}
    for i = #buttons, 1, -1 do
        local def = buttons[i]
        local btn = W.IconButton(header, T, def.icon, def.onClick, def.tooltip, def.round)
        btn:SetPoint("RIGHT", anchor, anchorPoint, x, 0)
        anchor, anchorPoint, x = btn, "LEFT", -6
        header.buttons[def.key or i] = btn
    end
    header.leftmostButton = anchor ~= header and anchor or nil
    f.header = header
    return header
end
