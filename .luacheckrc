-- luacheck config for the Reminders addon.
-- WoW runs Lua 5.1; we whitelist the WoW API and the addon's intentional globals.

std = "lua51"
max_line_length = false

-- The point of this config is global-scope hygiene (the 1xx codes), so we gate
-- on those and ignore benign style noise.
ignore = {
    "2..",  -- unused variables / arguments / loop variables
    "3..",  -- unused or redundant values
    "4..",  -- redefining / shadowing (locals, args, loop vars, upvalues)
    "542",  -- empty if branch
}

exclude_files = {
    "Libs/",
}

-- Globals this addon intentionally defines.
globals = {
    "RemindersDBG",   -- SavedVariables (must be a real global)
    "RemindersDBPC",  -- SavedVariablesPerCharacter (must be a real global)
    "Reminders",      -- AceAddon object, shared across files
    "GUI",            -- shared across files (candidate for phase 2 namespacing)
    "RemindersDB",    -- shared across files (candidate for phase 2 namespacing)
    "SCROLLWIDTH",    -- shared across files (candidate for phase 2 namespacing)
    "SCROLLHEIGHT",   -- shared across files (candidate for phase 2 namespacing)
    "StaticPopupDialogs", -- WoW global table the addon registers a dialog into
}

-- WoW API + global aliases the addon reads.
read_globals = {
    "LibStub",
    "CreateFrame", "UIParent", "GameTooltip",
    "C_Timer", "C_AddOns", "GetAddOnMetadata",
    "UnitName", "UnitClass", "UnitLevel", "UnitAffectingCombat", "GetRealmName",
    "GetAverageItemLevel", "GetProfessions", "GetProfessionInfo",
    "GetQuestResetTime",
    "IsAltKeyDown", "IsControlKeyDown",
    "StaticPopup_Show", "STATICPOPUPS_NUMDIALOGS",
    "Settings", "BackdropTemplateMixin",
    "loadstring", "time", "date", "floor", "tinsert", "strsub", "wipe",
    -- Font objects
    "GameFontHighlight", "GameFontHighlightSmall", "GameFontNormal",
    "GameFontNormalSmall", "GameFontDisable", "GameFontDisableSmall",
    "NumberFontNormalSmall",
}
