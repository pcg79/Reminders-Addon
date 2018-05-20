Reminders = LibStub("AceAddon-3.0"):NewAddon("Reminders", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
RemindersConsole = LibStub("AceConsole-3.0")
Reminders:RegisterChatCommand("reminders", "CommandProcessor")

local R_CLASS      = "class"
local R_PROFESSION = "profession"
local R_LEVEL      = "level"
local R_NAME       = "name"

local R_AND = "and"
local R_OR  = "or"

-- Globals
gui = nil

local function chatMessage(message)
    RemindersConsole:Print("Reminder: "..message)
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

    if gui then gui:Show() end
end

function Reminders:EvaluateReminders()
    local reminders = self.db.global.reminders
    local reminderMessages = {}
    local timeNow = time()

    for _, reminder in pairs(reminders) do
        debug("time = "..timeNow)
        debug("reminder.nextRemindAt = "..reminder.nextRemindAt)
        if timeNow >= reminder.nextRemindAt then
            local message = Reminders:ProcessReminder(reminder)

            if message ~= nil and message ~= "" then
                tinsert(reminderMessages, message)

                -- We're showing this one so don't show it again until the next interval
                -- BUG: This isn't great. This means if you have > 1 toon this reminder
                -- would pertain to, you're only going to see it on the first to log in.
                -- Not sure how I'll go about fixing this.
                reminder.nextRemindAt = Reminders:CalculateNextRemindAt(reminder.interval)
            end
        end
    end

    for _, m in pairs(reminderMessages) do
        debug("m = "..m)
    end

    -- If reminderMessages has at least one message, display them
    if next(reminderMessages) ~= nil then
        message(table.concat(reminderMessages, "\n"))
    end
end

function Reminders:ProcessReminder(reminder)
    array = {}

    debug("message = "..reminder.message)
    debug("condition string = "..reminder.condition)

    if Reminders:EvaluateCondition(reminder.condition) then
        return reminder.message
    end
end

-- We build up a string to evaluate based on any conditions we find
-- then we evaluate the string as a whole.
function Reminders:EvaluateCondition(condition)
    if string.match(condition, "\*") then
        return true
    end

    -- Go through each condition
    -- name
    -- level
    -- class
    -- profession
    local evalString = ""
    local tokens = {}
    local tokenCount = 0
    for token in string.gmatch(condition, "[^ ]+") do
        tokenCount = tokenCount + 1
        tokens[tokenCount] = token
    end

    debug("tokenCount = "..tokenCount)

    local toSkip = 0
    for i=1, tokenCount do
        debug("i = "..i)

        if toSkip <= 0 then
            local token = tokens[i]:lower()
            debug("token = "..token)
            local count = 0

            if token == R_NAME then
                count = count + 1
                local operation = tokens[i+count]
                count = count + 1
                local name = tokens[i+count]

                debug("(name) operation = "..operation)
                debug("name = "..name)

                local playerName = UnitName("player")

                debug("playerName = "..playerName)

                evalString = evalString.." "..tostring(playerName == name)

            elseif token == R_LEVEL then
                count = count + 1
                local operation = tokens[i+count]
                count = count + 1
                local level = tokens[i+count]

                if operation == "=" then
                    operation = "=="
                end

                debug("(level) operation = "..operation)
                debug("level = "..level)

                local playerLevel = UnitLevel("player")
                local levelStmt = "return "..playerLevel..operation..level

                debug("stmt: "..levelStmt)

                local levelFunc = assert(loadstring(levelStmt))
                local result, errorMsg = levelFunc();

                debug("sum = "..tostring(result))

                evalString = evalString.." "..tostring(result)

            elseif token == R_CLASS then
                count = count + 1
                local operation = tokens[i+count]
                count = count + 1
                local class = tokens[i+count]

                debug("(class) operation = "..operation)
                debug("class = "..class)

                local playerClass = UnitClass("player")

                debug("playerClass = "..playerClass)

                evalString = evalString.." "..tostring(playerClass == class)

            elseif token == R_PROFESSION then
                count = count + 1
                local operation = tokens[i+count]
                count = count + 1
                local profession = tokens[i+count]:lower()

                debug("(profession) operation = "..operation)
                debug("profession = "..profession)

                local prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions()

                local prof1Name = GetProfessionNameByIndex(prof1) or ""
                local prof2Name = GetProfessionNameByIndex(prof2) or ""


                debug("prof1Name = "..(prof1Name or "nil"))
                debug("prof2Name = "..(prof2Name or "nil"))
                debug("archaeology = "..(archaeology or "nil"))
                debug("fishing = "..(fishing or "nil"))
                debug("cooking = "..(cooking or "nil"))
                debug("firstAid = "..(firstAid or "nil"))

                local profResult = (profession == prof1Name:lower() or profession == prof2Name:lower()) or
                   (profession == "archaeology" and archaeology ~= nil) or
                   (profession == "fishing" and fishing ~= nil) or
                   (profession == "cooking" and cooking ~= nil) or
                   (profession == "firstaid" and firstAid ~= nil)

                evalString = evalString.." "..tostring(profResult)

            elseif token == R_AND then
                evalString = evalString.." and"
            elseif token == R_OR then
                evalString = evalString.." or"
            end

            toSkip = count
        else
            toSkip = toSkip - 1
        end
    end

    if evalString == "" then
        return false
    else
        evalString = "return "..evalString

        debug("evalString: "..evalString)

        local evalFunc = assert(loadstring(evalString))
        local result, errorMsg = evalFunc();

        debug("end result = "..tostring(result))

        return result
    end
end

function GetProfessionNameByIndex(profIndex)
    if profIndex == nil or profIndex == "" then
        return
    end
    local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier, specializationIndex, specializationOffset = GetProfessionInfo(profIndex)
    return name
end

function Reminders:SaveReminder(text)
    debug("saving - "..text)
    local newReminder = ParseReminder(text)
    newReminder = Reminders:MergeDefaults(newReminder)

    debug("message = "..(newReminder.message or "nil"))
    debug("condition = "..(newReminder.condition or "nil"))
    debug("interval = "..(newReminder.interval or "nil"))

    if not Reminders:ValidReminder(newReminder) then
        -- TODO:  Print out "empty params" msg somewhere
        debug("Not a valid reminder")
        return
    end

    -- Don't save reminders where the message and reminder already exist
    for i, reminder in ipairs(self.db.global.reminders) do
        if Reminders:IsEqual(newReminder, reminder) then
            debug("Reminder with text '"..newReminder.message.."' and condition '"..newReminder.condition .."' and interval '"..newReminder.interval.."' already exists")
            -- TODO:  Print out "already added" msg somewhere
            return
        end
    end

    newReminder.nextRemindAt = Reminders:CalculateNextRemindAt(interval)
    tinsert(self.db.global.reminders, newReminder)
    Reminders:LoadReminders()
end

function Reminders:CalculateNextRemindAt(interval)
    local secondsInADay = 24 * 60 * 60
    local timeNow = time()
    local nextRemindAt = nil

    debug("[CalculateNextRemindAt] interval = "..interval)
    if interval == "daily" then
        debug("it's daily")
        nextRemindAt = timeNow + Reminders:GetQuestResetTime()
    elseif interval == "weekly" then
        debug("it's weekly")
        local nextQuestResetTime = timeNow + Reminders:GetQuestResetTime()
        local nextQuestResetTimeWDay = date("%w", nextQuestResetTime)

        -- We'll have to change this if server resets stop being on Tuesday.
        -- Also not sure how this'll handle internationalization.  I'm guessing poorly.
        -- Might have to change local time to PST, calculate time distance, then
        -- change back to local time.
        local numDaysUntilTuesday = 7 - ((5 + nextQuestResetTimeWDay) % 7) % 7

        nextRemindAt = nextQuestResetTime + (numDaysUntilTuesday * secondsInADay)
    elseif interval == "now" then -- for debugging only (for now)
        debug("it's now now")
        nextRemindAt = timeNow
    end

    return nextRemindAt
end

function Reminders:GetQuestResetTime()
    -- It seems GetQuestResetTime() gives you one second before the actual reset.
    -- So add 1 to get the actual reset.
    return GetQuestResetTime() + 1
end

function ParseReminder(text)
    local array = {}
    for token in string.gmatch(text, "[^,]+") do
        tinsert(array, token:trim())
    end

    for k,v in pairs(array) do
        debug(k.." = "..v)
    end

    return { message = array[1], condition = array[2], interval = array[3] or "daily" }
end

function Reminders:DebugPrintReminders()
    reminders = self.db.global.reminders
    for _, reminder in pairs(reminders) do
        chatMessage(reminder.message .. " -> " .. reminder.condition .. " -> " .. reminder.interval)
    end
end

function Reminders:IsEqual(reminder1, reminder2)
    return reminder1.message:lower() == reminder2.message:lower() and
        reminder1.condition:lower() == reminder2.condition:lower() and
        reminder1.interval:lower() == reminder2.interval:lower()
end

-- TODO: Add additional validations here like are condition and interval valid
function Reminders:ValidReminder(reminder)
    return reminder.message ~= nil and reminder.message ~= "" and
        reminder.condition ~= nil and reminder.condition ~= "" and
        reminder.interval ~= nil and reminder.interval ~= ""
end

function Reminders:MergeDefaults(reminder)
    local reminderDefaults = {
        interval = "daily"
    }

    for key, value in pairs(reminderDefaults) do
        reminder[key] = reminder[key] or value
    end

    return reminder
end

function dbDefaults()
    return  {
      global = {
        reminders = {},
      }
    }
end
