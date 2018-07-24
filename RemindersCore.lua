Reminders = LibStub("AceAddon-3.0"):NewAddon("Reminders", "AceConsole-3.0")
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
    local commands = {}
    debug("input = " .. input)
    for token in input.gmatch(input, "[^ ]+") do
        debug("token = " .. token)
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
        chatMessage("Debug logging is now " .. str)
    elseif command == "delete" then
        local id = commands[2]
        debug("id = " .. id)

        Delete(id)
    else
        chatMessage("Usage:")
    end
end

function Reminders:ResetAll()
    debug("resetting all")
    _G["RemindersDBG"] = GlobalDefaults()
    _G["RemindersDBPC"] = PerCharacterDefaults()

    RemindersDB.global = _G["RemindersDBG"]
    RemindersDB.char   = _G["RemindersDBPC"]

    GUI = Reminders:CreateUI()
end

function Reminders:OnInitialize()
    if not _G["RemindersDBG"] then
        _G["RemindersDBG"] = GlobalDefaults()
    end

    if not RemindersDBPC then
        _G["RemindersDBPC"] = PerCharacterDefaults()
    end

    RemindersDB.global = _G["RemindersDBG"]
    RemindersDB.char   = _G["RemindersDBPC"]
end

function Reminders:OnEnable()
    debug("OnEnable")

    Reminders:DebugPrintReminders()

    Reminders:EvaluateReminders()
    Reminders:CleanUpPlayerReminders()

    if not GUI then GUI = Reminders:CreateUI() end

    Reminders:LoadReminders(GUI)

    if RemindersDB.char.debug then GUI:Show() end
end

function Reminders:EvaluateReminders()
    local reminderMessages = {}

    for i, reminder in pairs(RemindersDB.global.reminders) do
        local reminder = Reminders:BuildReminder(reminder)
        local message  = reminder:Process()

        -- If Process returned a message, that means the reminder triggered.
        -- That also means nextRemindAt has changed so we need to update the reminder in the DB.
        if message ~= nil and message ~= "" then
            tinsert(reminderMessages, { text = message })
            reminder:Save()
        end
    end

    -- If reminderMessages has at least one message, display them
    if next(reminderMessages) ~= nil then
        Reminders:DisplayReminders({
            title = "Reminder!",
            font = "Fonts\\FRIZQT__.TTF",
            fontHeight = 16,
            width = 552,
            imageHeight = 256,
            reminders = reminderMessages
        })
    end
end

-- When a reminder is deleted we delete it from the global reminders but we can't go through
-- all of the player's characters data and delete it.  So we'll just go through their reminders
-- and delete those that don't exist in the global list.  Performance is going to suck on big
-- lists, though.  Might have to revisit this.
function Reminders:CleanUpPlayerReminders()
    for id, _ in pairs(RemindersDB.char.reminders) do
        local globalReminder = RemindersDB.global.reminders[id]

        if globalReminder == nil then
            debug("Reminder "..id.." doesn't exist in global list.  Deleting...")
            RemindersDB.char.reminders[id] = nil
        end
    end
end

function Reminders:AddReminder(text)
    local newReminder = Reminders:BuildReminder(ParseReminder(text))

    if not newReminder:IsValid() then
        -- TODO:  Print out "empty params" msg somewhere
        debug("[Error] Not a valid reminder")
        return
    end

    -- Don't save reminders where the message and reminder already exist
    for key, reminder in pairs(RemindersDB.global.reminders) do
        debug("[AddReminder] looping...")
        local reminder = Reminders:BuildReminder(reminder)
        if reminder:IsEqual(newReminder) then
            debug("[Error] Reminder with text '"..newReminder.message.."' and condition '"..newReminder.condition .."' and interval '"..newReminder.interval.."' already exists")
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
