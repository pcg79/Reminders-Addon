Reminders = LibStub("AceAddon-3.0"):NewAddon("Reminders", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
Reminders:RegisterChatCommand("reminders", "CommandProcessor")

-- Globals
GUI = nil
RemindersDB = nil

function chatMessage(message)
    print("Reminder: "..message)
end

function debug(message)
  --if addon.db.profile.debug then
  if true then
     chatMessage("[debug] "..message)
  end
end

debug("We're in")

debug(_G._VERSION)

function Reminders:CommandProcessor(input)
    debug("Command = "..input)
    if input == "" or input == "toggle" then
        if GUI:IsVisible() then GUI:Hide() else GUI:Show() end
    elseif input == "open" or input == "show" then
        GUI:Show()
    elseif input == "reset" then
        StaticPopup_Show("REMINDERS_REMOVE_ALL_CONFIRM")
    elseif input == "eval" then
        Reminders:EvaluateReminders()
    else
        OutputLog("Usage:")
    end
end

function Reminders:ResetAll()
    debug("resetting all")
    RemindersDB:ResetDB()
end

function Reminders:OnInitialize()
    debug("OnInit")

    RemindersDB = LibStub("AceDB-3.0"):New("RemindersDB", dbDefaults(), true)
    RemindersDB:RegisterDefaults(dbDefaults())
end

function Reminders:OnEnable()
    debug("OnEnable")

    Reminders:DebugPrintReminders()
    Reminders:EvaluateReminders()

    if not GUI then GUI = Reminders:CreateUI() end

    Reminders:LoadReminders(GUI)

    if GUI then GUI:Show() end
end

function Reminders:EvaluateReminders()
    local reminderMessages = {}

    for i, reminder in pairs(RemindersDB.global.reminders) do
        local reminder = Reminders:CreateReminder(reminder)
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
    local newReminder = Reminders:CreateReminder(ParseReminder(text))

    if not newReminder:IsValid() then
        -- TODO:  Print out "empty params" msg somewhere
        debug("Not a valid reminder")
        return
    end

    -- Don't save reminders where the message and reminder already exist
    for key, reminder in pairs(RemindersDB.global.reminders) do
        debug("[AddReminder] looping...")
        local reminder = Reminders:CreateReminder(reminder)
        if reminder:IsEqual(newReminder) then
            debug("Reminder with text '"..newReminder.message.."' and condition '"..newReminder.condition .."' and interval '"..newReminder.interval.."' already exists")
            -- TODO:  Print out "already added" msg somewhere
            return
        end
    end

    newReminder:SetNextRemindAt()

    newReminder:Save()
    Reminders:LoadReminders(GUI)
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
    debug("Printing reminders:")
    reminders = RemindersDB.global.reminders
    for _, reminder in pairs(reminders) do
        local reminder = Reminders:CreateReminder(reminder)
        chatMessage(reminder:ToString())
    end
end

function dbDefaults()
    return  {
        global = {
            reminders = {},
            remindersCount = 0,
        }
    }
end
