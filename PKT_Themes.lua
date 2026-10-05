local _, PKT = ...
local L = PKT.L

local MEDIA = "Interface\\AddOns\\ProfessionKnowledgeTreasures\\Media\\"
local FONTS = MEDIA .. "Fonts\\"
PKT.TEX = MEDIA .. "Textures\\"

local function hex(s, a)
    return {
        tonumber(s:sub(2, 3), 16) / 255,
        tonumber(s:sub(4, 5), 16) / 255,
        tonumber(s:sub(6, 7), 16) / 255,
        a or 1,
    }
end
PKT.Hex = hex

local NON_LATIN = { ruRU = true, koKR = true, zhCN = true, zhTW = true }
local useGameFont = NON_LATIN[GetLocale()] == true

local CINZEL = FONTS .. "Cinzel-Bold.ttf"
local SOURCE = FONTS .. "SourceSans3-Regular.ttf"
local SOURCE_BOLD = FONTS .. "SourceSans3-Bold.ttf"
local BARLOW = FONTS .. "Barlow-Regular.ttf"
local BARLOW_SEMI = FONTS .. "Barlow-SemiBold.ttf"
local BARLOW_COND = FONTS .. "BarlowCondensed-Bold.ttf"

PKT.THEME_ORDER = { "ledger", "workbench", "house" }

PKT.THEMES = {
    ledger = {
        key = "ledger",
        name = L.THEME_LEDGER,
        desc = L.THEME_LEDGER_DESC,
        fonts = {
            title = { CINZEL, 14 },
            heading = { CINZEL, 19 },
            section = { CINZEL, 12 },
            body = { SOURCE, 13 },
            small = { SOURCE, 12 },
            strong = { SOURCE_BOLD, 12 },
            kicker = { SOURCE_BOLD, 11 },
            button = { SOURCE_BOLD, 12 },
        },
        colors = {
            window = hex("#1c1611"),
            windowBorder = hex("#5a4630"),
            line = hex("#3a2e22"),
            surface = hex("#241c15"),
            surfaceBorder = hex("#3a2e22"),
            surfaceHover = hex("#2e241b"),
            track = hex("#120e0b"),
            title = hex("#e9d9b4"),
            heading = hex("#f3e6c8"),
            text = hex("#efe6d6"),
            body = hex("#bfb19e"),
            muted = hex("#a8998a"),
            accent = hex("#c9a35a"),
            button = hex("#241c15"),
            buttonBorder = hex("#5a4630"),
            buttonHover = hex("#2e241b"),
            buttonText = hex("#e9d9b4"),
            primary = hex("#c9a35a"),
            primaryBorder = hex("#e2c07a"),
            primaryHover = hex("#d6b06a"),
            primaryText = hex("#1c1611"),
            iconButton = hex("#241c15"),
            iconButtonBorder = hex("#3a2e22"),
            icon = hex("#a8998a"),
            iconHover = hex("#e9d9b4"),
            good = hex("#9fc58a"),
            badge = hex("#d0614a"),
        },
        metrics = {
            windowRadius = 4,
            surfaceRadius = 4,
            buttonRadius = 4,
            buttonHeight = 30,
            iconButton = 26,
            headerHeight = 42,
            padding = 14,
            gap = 12,
            barHeight = 6,
        },
        style = {
            innerFrame = true,
            brackets = true,
            headerIcon = "icon_chest",
            titleText = L.TITLE_SHORT,
            settingsIcon = "icon_gear",
            kicker = true,
            progressHeader = true,
            progress = "bars",
            profChip = true,
            zoneBox = true,
            footerBar = false,
            roundClose = false,
            profColors = false,
        },
    },
    workbench = {
        key = "workbench",
        name = L.THEME_WORKBENCH,
        desc = L.THEME_WORKBENCH_DESC,
        fonts = {
            title = { BARLOW_COND, 17 },
            heading = { BARLOW_COND, 24 },
            section = { BARLOW_SEMI, 12 },
            body = { BARLOW, 13 },
            small = { BARLOW, 12 },
            strong = { BARLOW_SEMI, 12 },
            kicker = { BARLOW_SEMI, 11 },
            button = { BARLOW_SEMI, 13 },
        },
        colors = {
            window = hex("#171a1f"),
            windowBorder = hex("#2c323a"),
            header = hex("#1d2127"),
            line = hex("#2c323a"),
            surface = hex("#1d2127"),
            surfaceBorder = hex("#2c323a"),
            surfaceHover = hex("#262b32"),
            track = hex("#2a3038"),
            title = hex("#e8ebee"),
            heading = hex("#e8ebee"),
            text = hex("#e8ebee"),
            body = hex("#9aa3ad"),
            muted = hex("#9aa3ad"),
            accent = hex("#4fbf8f"),
            button = hex("#262b32"),
            buttonBorder = hex("#262b32"),
            buttonHover = hex("#30363f"),
            buttonText = hex("#e8ebee"),
            primary = hex("#2f8f68"),
            primaryBorder = hex("#2f8f68"),
            primaryHover = hex("#36a377"),
            primaryText = hex("#ffffff"),
            iconButton = hex("#262b32"),
            iconButtonBorder = hex("#262b32"),
            icon = hex("#c3cad2"),
            iconHover = hex("#ffffff"),
            good = hex("#4fbf8f"),
            badge = hex("#e0913a"),
        },
        metrics = {
            windowRadius = 10,
            surfaceRadius = 10,
            buttonRadius = 4,
            buttonHeight = 32,
            iconButton = 28,
            headerHeight = 46,
            padding = 14,
            gap = 12,
            barHeight = 6,
        },
        style = {
            headerFill = true,
            uppercaseTitle = true,
            titleText = L.TITLE_SHORT,
            headerCount = true,
            settingsIcon = "icon_sliders",
            stripe = true,
            pill = true,
            routePosition = true,
            coordBadge = true,
            progress = "pips",
            zoneDot = true,
            footerBar = true,
            iconNavButtons = true,
            roundClose = false,
            profColors = true,
        },
    },
    house = {
        key = "house",
        name = L.THEME_HOUSE,
        desc = L.THEME_HOUSE_DESC,
        fonts = {
            title = { SOURCE_BOLD, 15 },
            heading = { SOURCE_BOLD, 17 },
            section = { SOURCE_BOLD, 12 },
            body = { SOURCE, 13 },
            small = { SOURCE, 12 },
            strong = { SOURCE_BOLD, 12 },
            kicker = { SOURCE_BOLD, 11 },
            button = { SOURCE, 12 },
        },
        colors = {
            window = { 0.06, 0.06, 0.06, 0.98 },
            windowBorder = { 0.22, 0.22, 0.22, 1 },
            line = { 0.29, 0.29, 0.29, 1 },
            surface = hex("#161616"),
            surfaceBorder = { 0.22, 0.22, 0.22, 1 },
            surfaceHover = hex("#1f1f1f"),
            track = hex("#262626"),
            title = { 0.92, 0.91, 0.86, 1 },
            heading = { 0.92, 0.91, 0.86, 1 },
            text = { 0.92, 0.91, 0.86, 1 },
            body = { 0.70, 0.70, 0.70, 1 },
            muted = { 0.70, 0.70, 0.70, 1 },
            accent = { 0.78, 0.66, 0.22, 1 },
            button = hex("#161616"),
            buttonBorder = { 0.22, 0.22, 0.22, 1 },
            buttonHover = hex("#202020"),
            buttonText = { 0.92, 0.91, 0.86, 1 },
            primary = hex("#161616"),
            primaryBorder = { 0.78, 0.66, 0.22, 1 },
            primaryHover = hex("#202020"),
            primaryText = { 0.92, 0.91, 0.86, 1 },
            iconButton = hex("#161616"),
            iconButtonBorder = { 0.22, 0.22, 0.22, 1 },
            icon = { 0.70, 0.70, 0.70, 1 },
            iconHover = { 0.92, 0.91, 0.86, 1 },
            good = { 0.78, 0.66, 0.22, 1 },
            badge = hex("#d0614a"),
        },
        metrics = {
            windowRadius = 0,
            surfaceRadius = 0,
            buttonRadius = 0,
            buttonHeight = 28,
            iconButton = 24,
            headerHeight = 42,
            padding = 14,
            gap = 12,
            barHeight = 4,
        },
        style = {
            titleText = L.TITLE,
            settingsIcon = "icon_gear",
            iconTile = true,
            notesDivider = true,
            progress = "inline",
            zonePlain = true,
            footerBar = false,
            roundClose = true,
            profColors = false,
        },
    },
}

PKT.PROF_ICONS = {
    [2906] = "prof_alchemy",
    [2907] = "prof_blacksmithing",
    [2909] = "prof_enchanting",
    [2910] = "prof_engineering",
    [2912] = "prof_herbalism",
    [2913] = "prof_inscription",
    [2914] = "prof_jewelcrafting",
    [2915] = "prof_leatherworking",
    [2916] = "prof_mining",
    [2917] = "prof_skinning",
    [2918] = "prof_tailoring",
}

PKT.PROF_COLORS = {
    [2906] = hex("#4fbf8f"),
    [2907] = hex("#e0793f"),
    [2909] = hex("#a98cf0"),
    [2910] = hex("#e0a03a"),
    [2912] = hex("#86cf5a"),
    [2913] = hex("#6fa8e8"),
    [2914] = hex("#e8709f"),
    [2915] = hex("#c79a68"),
    [2916] = hex("#9fb0c2"),
    [2917] = hex("#d9b45f"),
    [2918] = hex("#e07c7c"),
}

function PKT.GetTheme()
    local key = PKT_SavedVars and PKT_SavedVars.theme
    return PKT.THEMES[key] or PKT.THEMES.house
end

function PKT.HasChosenTheme()
    return PKT_SavedVars ~= nil and PKT.THEMES[PKT_SavedVars.theme] ~= nil
end

function PKT.ProfColor(T, profID)
    if T.style.profColors and profID and PKT.PROF_COLORS[profID] then
        return PKT.PROF_COLORS[profID]
    end
    return T.colors.accent
end

function PKT.ApplyFont(fs, T, role)
    local spec = T.fonts[role] or T.fonts.body
    if useGameFont then
        fs:SetFont(STANDARD_TEXT_FONT, spec[2], "")
    elseif not fs:SetFont(spec[1], spec[2], "") then
        fs:SetFont(STANDARD_TEXT_FONT, spec[2], "")
    end
end
