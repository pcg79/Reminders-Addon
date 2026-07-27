local addonName, addon = ...

Reminders = LibStub("AceAddon-3.0"):NewAddon("Reminders", "AceConsole-3.0", "AceTimer-3.0")
Reminders:RegisterChatCommand("reminders", "CommandProcessor")

Reminders.version = (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)(addonName, "Version");

-- Globals
GUI = nil
RemindersDB = {}
local ForceEvaluate = false

-- Open the addon's options in a standalone AceConfigDialog window. Blizzard's
-- Settings.OpenToCategory now requires a numeric category id (not the addon
-- name), so we open our own dialog instead of the Blizzard Settings panel.
local function ShowInterfaceOptions()
    LibStub("AceConfigDialog-3.0"):Open(Reminders:GetName())
end

local function SetDefaultsIfUnset()
    if not RemindersDB.char.defaultDay then
        RemindersDB.char.defaultDay = Reminders:PerCharacterDefaults().defaultDay
    end

    if not RemindersDB.char.snoozeAmount then
        RemindersDB.char.snoozeAmount = Reminders:PerCharacterDefaults().snoozeAmount
    end
end

function Reminders:ChatMessage(message)
    print("|cffff0000Reminders|r: "..message)
end

function Reminders:debug(message)
  if not RemindersDB.char or RemindersDB.char.debug then
     Reminders:ChatMessage("[ " .. date("%x %X") .. " ][debug] "..message)
  end
end

function Reminders:CommandProcessor(input)
    local commands = {}
    Reminders:debug("input = " .. input)
    for token in input.gmatch(input, "[^ ]+") do
        Reminders:debug("token = " .. token)
        tinsert(commands, token)
    end

    local command = commands[1] or ""

    if command == "" or command == "toggle" then
        if GUI:IsVisible() then GUI:Hide() else GUI:Show() end
    elseif command == "open" or command == "show" then
        GUI:Show()
    elseif command == "reset" then
        StaticPopup_Show("REMINDERS_REMOVE_ALL_CONFIRM")
    elseif command == "eval" then
        Reminders:EvaluateReminders()
    elseif command == "debug" then
        RemindersDB.char.debug = not RemindersDB.char.debug
        local str = "off"
        if RemindersDB.char.debug then
            str = "on"
        end
        Reminders:ChatMessage("Debug logging is now " .. str)
    elseif command == "delete" then
        local id = commands[2]
        Reminders:debug("id = " .. id)

        Reminders:DeleteReminder(id)
    elseif command == "opt" or command == "opts" or command == "option" or command == "options" or command == "config" then
        ShowInterfaceOptions()
    else
        local usage = "|cffff0000Usage:|r\n\n"..
            "|cffffcc00/reminders|r - Toggles the Reminders UI open or closed\n"..
            "|cffffcc00/reminders (show|open)|r - Opens the Reminders UI\n"..
            "|cffffcc00/reminders eval|r - Forces an evaluation of your reminders\n"..
            "|cffffcc00/reminders debug|r - Toggles debugging for the app\n"..
            "|cffffcc00/reminders delete id|r - Deletes the reminder with the id.  Can get the id by turning on debugging.\n"..
            "|cffffcc00/reminders reset|r - Deletes all your reminders.  Use with caution.  Not reversible.\n"..
            "|cffffcc00/reminders help|r - This message"

        Reminders:ChatMessage(usage)
    end
end

function Reminders:ResetAll()
    Reminders:debug("resetting all")
    _G["RemindersDBG"] = Reminders:GlobalDefaults()
    _G["RemindersDBPC"] = Reminders:PerCharacterDefaults()

    RemindersDB.global = _G["RemindersDBG"]
    RemindersDB.char   = _G["RemindersDBPC"]

    -- Re-seed the roster with this character; nothing to migrate after a wipe.
    Reminders:CaptureCurrentCharacter()
    RemindersDB.char.migratedSchedule = true

    GUI = Reminders:CreateUI()
end

function Reminders:OnInitialize()
    Reminders:debug("Initializing...")

    if not _G["RemindersDBG"] then
        _G["RemindersDBG"] = Reminders:GlobalDefaults()
    end

    if not RemindersDBPC then
        _G["RemindersDBPC"] = Reminders:PerCharacterDefaults()
    end

    RemindersDB.global = _G["RemindersDBG"]
    RemindersDB.char   = _G["RemindersDBPC"]

    SetDefaultsIfUnset()

    -- Ensure the account-wide roster exists for accounts created before #21.
    if not RemindersDB.global.characters then
        RemindersDB.global.characters = {}
    end

    -- Snapshot this character into the roster, then one-time migrate its
    -- schedule out of the per-character SavedVariables (which other characters
    -- can't read) into the account-wide roster entry. (#21)
    Reminders:CaptureCurrentCharacter()
    if not RemindersDB.char.migratedSchedule then
        local current = Reminders:CurrentCharacter()
        for id, nextRemindAt in pairs(RemindersDB.char.reminders or {}) do
            current.reminders[id] = nextRemindAt
        end
        RemindersDB.char.migratedSchedule = true
    end

    Reminders:debug("Done Initializing")
end

function Reminders:OnEnable()
    Reminders:debug("Enabling...")
    Reminders:CreateOptions()

    Reminders:EvaluateReminders()
    Reminders:CleanUpPlayerReminders()

    Reminders:debug("Creating UI")

    GUI = Reminders:CreateUI()

    Reminders:RegisterEvents()

    Reminders:LoadReminders(GUI)

    if RemindersDB.char.debug then GUI:Show() end

    -- Show the changelog once after the addon updates (#55)
    Reminders:MaybeShowWhatsNewOnLogin()

    Reminders:debug("Done Enabling")
end

function Reminders:RegisterEvents()
    GUI:RegisterEvent("PLAYER_REGEN_ENABLED")
    GUI:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_REGEN_ENABLED" then
            Reminders:debug("Out of combat")
            if Reminders:ShouldForceEvaluate() then
                Reminders:debug("...and we should force eval")
                Reminders:CancelEvaluateAfterCombat()
                Reminders:EvaluateReminders()
            end
        end
    end)
end

function Reminders:BuildAndDisplayReminders(messages)
    if next(messages) then
        Reminders:DisplayInlinePopup({
            title = "Reminder!",
            font = "Fonts\\FRIZQT__.TTF",
            fontHeight = 16,
            width = 552,
            imageHeight = 256,
            reminders = messages,
            relPoint = "BOTTOMRIGHT",
            x = -400,
            y = 200,
        })
    end
end

function Reminders:ShouldForceEvaluate()
    return ForceEvaluate
end

function Reminders:EvaluateAfterCombat()
    ForceEvaluate = true
end

function Reminders:CancelEvaluateAfterCombat()
    ForceEvaluate = false
end

function Reminders:EvaluateReminders()
    if UnitAffectingCombat("player") then
        Reminders:debug("In combat, not showing reminder")
        Reminders:EvaluateAfterCombat()
        return
    end

    local reminderMessages = {}

    for i, reminder in pairs(RemindersDB.global.reminders) do
        local reminder = Reminders:BuildReminder(reminder)
        local messageTable = reminder:Evaluate()

        if messageTable then
            tinsert(reminderMessages, messageTable)
        end
    end

    Reminders:BuildAndDisplayReminders(reminderMessages)
end

-- Drop scheduled next-remind times for reminders that no longer exist. Now that
-- schedules live account-wide (#21) we can prune every character's entries, not
-- just the current one.
function Reminders:CleanUpPlayerReminders()
    for _, char in pairs(RemindersDB.global.characters) do
        for id, _ in pairs(char.reminders) do
            if RemindersDB.global.reminders[id] == nil then
                Reminders:debug("Reminder "..id.." doesn't exist in global list.  Deleting...")
                char.reminders[id] = nil
            end
        end
    end
end

-- Build a stable, canonical identity for the current character. UnitName("player")
-- can return a realm-suffixed name on connected realms (and inconsistently so),
-- which would create duplicate roster entries for one character. So we always
-- derive the key ourselves as "Name-Realm" from the bare name plus GetRealmName.
-- The bare name is kept separately for matching name/Self conditions. (#21)
local function CurrentCharacterIdentity()
    local name = UnitName("player") or "Unknown"
    name = name:match("^[^-]+") or name -- strip any "-Realm" suffix; character names have no hyphens
    local realm = GetRealmName() or "Unknown"
    return name, realm, name .. "-" .. realm
end

function Reminders:CurrentCharacterKey()
    local _, _, key = CurrentCharacterIdentity()
    return key
end

-- Returns the account-wide roster entry for the current character, creating a
-- bare one if needed. Kept cheap (no attribute lookups) since it's called on
-- every schedule read/write; full attribute capture happens in
-- CaptureCurrentCharacter at login.
function Reminders:CurrentCharacter()
    local name, realm, key = CurrentCharacterIdentity()
    local char = RemindersDB.global.characters[key]
    if not char then
        char = { name = name, realm = realm, reminders = {} }
        RemindersDB.global.characters[key] = char
    end
    if not char.reminders then
        char.reminders = {}
    end
    return char
end

-- Snapshot the current character's attributes into the roster so other
-- characters can reason about it while it's offline. Called once at login. (#21)
function Reminders:CaptureCurrentCharacter()
    local name, realm = CurrentCharacterIdentity()
    local char = Reminders:CurrentCharacter()
    char.name = name
    char.realm = realm
    char.class = UnitClass("player")
    char.level = UnitLevel("player")
    char.ilevel = GetAverageItemLevel()

    local professions = {}
    local prof1, prof2 = GetProfessions()
    for _, index in ipairs({ prof1, prof2 }) do
        local name = GetProfessionInfo(index)
        if name then
            tinsert(professions, name)
        end
    end
    char.professions = professions

    char.lastSeen = time()
    return char
end

function Reminders:GetPlayerReminder(reminder_id)
    return Reminders:CurrentCharacter().reminders[reminder_id]
end

function Reminders:SetPlayerReminder(reminder_id, value)
    Reminders:debug("[SetPlayerReminder] reminder_id = "..reminder_id)

    if value then
        Reminders:debug("[SetPlayerReminder] value = " .. value .. " (aka " .. date("%X", value ) .. ")")
    else
        Reminders:debug("[SetPlayerReminder] Deleting reminder")
    end
    Reminders:CurrentCharacter().reminders[reminder_id] = value
end

function Reminders:DeletePlayerReminder(reminder_id)
    Reminders:SetPlayerReminder(reminder_id, nil)
end

function Reminders:DebugPrintReminders()
    Reminders:debug("Printing global reminders:")
    local reminders = RemindersDB.global.reminders
    for _, reminder in pairs(reminders) do
        local reminder = Reminders:BuildReminder(reminder)
        Reminders:debug("[Global Reminders] " .. reminder:ToString())
    end

    Reminders:debug("Printing profile reminders:")
    reminders = Reminders:CurrentCharacter().reminders
    for key, remindAt in pairs(reminders) do
        Reminders:debug("[Profile Reminders] " .. key .. " = " .. remindAt)
    end
end

function Reminders:GlobalDefaults()
    return {
        reminders = {},
        remindersCount = 0,
        -- Account-wide roster keyed by character name. Each entry caches that
        -- character's attributes plus its per-reminder next-remind times, which
        -- used to live in the per-character SavedVariables (unreadable from other
        -- characters). Storing them here is what lets one character surface
        -- another's reminders. (#21)
        characters = {},
    }
end

function Reminders:PerCharacterDefaults()
    return {
        reminders = {},
        debug = false,
        defaultDay = 3, -- Tuesday
        snoozeAmount = 10,
    }
end

function Reminders:ResetCharacterOptions()
    local defaults = Reminders:PerCharacterDefaults()

    RemindersDB.char.debug = defaults.debug
    RemindersDB.char.defaultDay = defaults.defaultDay
end


function Reminders:DayList()
    return {
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
    }
end
