Reminders = LibStub("AceAddon-3.0"):NewAddon("Reminders", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
Reminders:RegisterChatCommand("reminders", "CommandProcessor")

-- Globals
gui = nil

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
    if input == "" or input == "open" or input == "show" then
        gui:Show()
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
    self.db:ResetDB()
end


function Reminders:OnInitialize()
    debug("OnInit")

    self.db = LibStub("AceDB-3.0"):New("RemindersDB", dbDefaults(), true)
    self.db:RegisterDefaults(dbDefaults())

    AceGUI = LibStub("AceGUI-3.0")

    self.frameShown = false

    Reminders:DebugPrintReminders()

    if not gui then Reminders:CreateUI() end

    Reminders:LoadReminders()

    Reminders:EvaluateReminders()

    -- if gui then gui:Show() end
end

function Reminders:EvaluateReminders()
    local reminders = {}
    local reminderMessages = {}

    for _, reminder in pairs(self.db.global.reminders) do
        local reminder = Reminders:CreateReminder(reminder)
        local message  = reminder:Process()

        if message ~= nil and message ~= "" then
            tinsert(reminderMessages, message)
        end

        tinsert(reminders, reminder)
    end

    -- If reminderMessages has at least one message, display them
    -- And that means the nextRemindAt changed on at least one
    -- so we need to save that to the DB
    if next(reminderMessages) ~= nil then
        message(table.concat(reminderMessages, "\n"))

        self.db.global.reminders = reminders
    end
end

function Reminders:SaveReminder(text)
    debug("saving - "..text)
    local newReminder = Reminders:CreateReminder(ParseReminder(text))

    debug("message = "..(newReminder.message or "nil"))
    debug("condition = "..(newReminder.condition or "nil"))
    debug("interval = "..(newReminder.interval or "nil"))

    if not newReminder:IsValid() then
        -- TODO:  Print out "empty params" msg somewhere
        debug("Not a valid reminder")
        return
    end

    -- Don't save reminders where the message and reminder already exist
    for _, reminder in ipairs(self.db.global.reminders) do
        local reminder = Reminders:CreateReminder(reminder)
        if reminder:IsEqual(newReminder) then
            debug("Reminder with text '"..newReminder.message.."' and condition '"..newReminder.condition .."' and interval '"..newReminder.interval.."' already exists")
            -- TODO:  Print out "already added" msg somewhere
            return
        end
    end

    tinsert(self.db.global.reminders, newReminder)
    Reminders:LoadReminders()
end


function ParseReminder(text)
    local array = {}
    for token in string.gmatch(text, "[^,]+") do
        tinsert(array, token:trim())
    end

    for k,v in pairs(array) do
        debug(k.." = "..v)
    end

    return { message = array[1], condition = array[2], interval = array[3] }
end

function Reminders:DebugPrintReminders()
    reminders = self.db.global.reminders
    for _, reminder in pairs(reminders) do
        local reminder = Reminders:CreateReminder(reminder)
        chatMessage(reminder:ToString())
    end
end

function dbDefaults()
    return  {
      global = {
        reminders = {},
      }
    }
end
