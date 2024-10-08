local addonName, addon = ...

Reminders = LibStub("AceAddon-3.0"):NewAddon("Reminders", "AceConsole-3.0", "AceTimer-3.0")
Reminders:RegisterChatCommand("reminders", "CommandProcessor")

Reminders.version = (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)(addonName, "Version");

-- Globals
GUI = nil
RemindersDB = {}
ForceEvaluate = false

-- Calling it once just opens the option screen.  Calling it again
-- makes it actually go to the Reminders section.
local function ShowInterfaceOptions()
    Settings.OpenToCategory(Reminders:GetName())
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

        Delete(id)
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

-- When a reminder is deleted we delete it from the global reminders but we can't go through
-- all of the player's characters data and delete it.  So we'll just go through their reminders
-- and delete those that don't exist in the global list.  Performance is going to suck on big
-- lists, though.  Might have to revisit this.
function Reminders:CleanUpPlayerReminders()
    for id, _ in pairs(RemindersDB.char.reminders) do
        local globalReminder = RemindersDB.global.reminders[id]

        if globalReminder == nil then
            Reminders:debug("Reminder "..id.." doesn't exist in global list.  Deleting...")
            RemindersDB.char.reminders[id] = nil
        end
    end
end

function Reminders:GetPlayerReminder(reminder_id)
    return RemindersDB.char.reminders[reminder_id]
end

function Reminders:SetPlayerReminder(reminder_id, value)
    Reminders:debug("[SetPlayerReminder] reminder_id = "..reminder_id)

    if value then
        Reminders:debug("[SetPlayerReminder] value = " .. value .. " (aka " .. date("%X", value ) .. ")")
    else
        Reminders:debug("[SetPlayerReminder] Deleting reminder")
    end
    RemindersDB.char.reminders[reminder_id] = value
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
    reminders = RemindersDB.char.reminders
    for key, remindAt in pairs(reminders) do
        Reminders:debug("[Profile Reminders] " .. key .. " = " .. remindAt)
    end
end

function Reminders:GlobalDefaults()
    return {
        reminders = {},
        remindersCount = 0,
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
