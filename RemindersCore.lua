Reminders = LibStub("AceAddon-3.0"):NewAddon("Reminders", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
Reminders:RegisterChatCommand("reminders", "CommandProcessor")

-- Globals
GUI = nil
RemindersDB = {}

function chatMessage(message)
    print("Reminder: "..message)
end

function debug(message)
  if RemindersDB.char.debug then
     chatMessage("[debug] "..message)
  end
end

function Reminders:CommandProcessor(input)
    chatMessage("Command = "..input)

    if input == "" or input == "toggle" then
        if GUI:IsVisible() then GUI:Hide() else GUI:Show() end
    elseif input == "open" or input == "show" then
        GUI:Show()
    elseif input == "reset" then
        StaticPopup_Show("REMINDERS_REMOVE_ALL_CONFIRM")
    elseif input == "eval" then
        Reminders:EvaluateReminders()
    elseif input == "debug" then
        RemindersDB.char.debug = not RemindersDB.char.debug
        local str = "off"
        if RemindersDB.char.debug then
            str = "on"
        end
        chatMessage("Debug logging is now " .. str)
    else
        OutputLog("Usage:")
    end
end

function Reminders:ResetAll()
    debug("resetting all")
    RemindersDB.global = GlobalDefaults()
    RemindersDB.char = PerCharacterDefaults()
end

function Reminders:OnInitialize()
    local RemindersDBG = _G["RemindersDBG"]
    local RemindersDBPC = _G["RemindersDBPC"]

    if not RemindersDBG then
        RemindersDBG = GlobalDefaults()
        _G["RemindersDBG"] = RemindersDBG
    end

    if not RemindersDBPC then
        RemindersDBPC = PerCharacterDefaults()
        _G["RemindersDBPC"] = RemindersDBPC
    end

    RemindersDB.global = RemindersDBG
    RemindersDB.char   = RemindersDBPC
end

function Reminders:OnEnable()
    debug("OnEnable")

    Reminders:DebugPrintReminders()
    -- Reminders:CleanUpPlayerReminders()
    Reminders:EvaluateReminders()

    if not GUI then GUI = Reminders:CreateUI() end

    Reminders:LoadReminders(GUI)

    if GUI then GUI:Show() end
end

function Reminders:EvaluateReminders()
    local reminderMessages = {}

    for i, reminder in pairs(RemindersDB.global.reminders) do
        local reminder = Reminders:BuildReminder(reminder)
        local message  = reminder:Process()

        -- If Process returned a message, that means the reminder triggered.
        -- That also means nextRemindAt has changed so we need to update the reminder in the DB.
        if message ~= nil and message ~= "" then
            tinsert(reminderMessages, message)
            reminder:Save()
        end
    end

    -- If reminderMessages has at least one message, display them
    if next(reminderMessages) ~= nil then
        message(table.concat(reminderMessages, "\n"))
    end
end

function Reminders:AddReminder(text)
    local newReminder = Reminders:BuildReminder(ParseReminder(text))

    if not newReminder:IsValid() then
        -- TODO:  Print out "empty params" msg somewhere
        debug("Not a valid reminder")
        return
    end

    -- Don't save reminders where the message and reminder already exist
    for key, reminder in pairs(RemindersDB.global.reminders) do
        debug("[AddReminder] looping...")
        local reminder = Reminders:BuildReminder(reminder)
        if reminder:IsEqual(newReminder) then
            debug("Reminder with text '"..newReminder.message.."' and condition '"..newReminder.condition .."' and interval '"..newReminder.interval.."' already exists")
            -- TODO:  Print out "already added" msg somewhere
            return
        end
    end

    newReminder:Save()
    newReminder:SetNextRemindAt()

    Reminders:LoadReminders(GUI)
end

function Reminders:GetPlayerReminder(reminder_id)
    return RemindersDB.char.reminders[reminder_id]
end

function Reminders:SetPlayerReminder(reminder_id, value)
    debug("[SetPlayerReminder] reminder_id = "..reminder_id)
    debug("[SetPlayerReminder] value = "..(value or "nil"))
    RemindersDB.char.reminders[reminder_id] = value

    Reminders:DebugPrintReminders()
end

function Reminders:DeletePlayerReminder(reminder_id)
    Reminders:SetPlayerReminder(reminder_id, nil)
end


function ParseReminder(text)
    local array = {}
    for token in string.gmatch(text, "[^,]+") do
        tinsert(array, token:trim())
    end

    -- for k,v in pairs(array) do
    --     debug(k.." = "..v)
    -- end

    return { message = array[1], condition = array[2], interval = array[3] }
end

function Reminders:DebugPrintReminders()
    debug("Printing global reminders:")
    local reminders = RemindersDB.global.reminders
    for _, reminder in pairs(reminders) do
        local reminder = Reminders:BuildReminder(reminder)
        chatMessage(reminder:ToString())
    end

    debug("Printing profile reminders:")
    reminders = RemindersDB.char.reminders
    for key, remindAt in pairs(reminders) do
        chatMessage("[Profile Reminders] " .. key .. " = " .. remindAt)
    end
end

function GlobalDefaults()
    return {
        reminders = {},
        remindersCount = 0,
    }
end

function PerCharacterDefaults()
    return {
        reminders = {},
        debug = false,
    }
end
