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
    debug(input)
    if input == "" or input == "open" or input == "show" then
        gui:Show()
    elseif input == "reset" then
        debug("resetting")
        Reminders:ResetAll()
    else
        OutputLog("Usage:")
    end
end

function Reminders:ResetAll()
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

    -- Reminders:EvaluateReminders()

    if gui then gui:Show() end
end

function Reminders:EvaluateReminders()
    local reminders = self.db.global.reminders
    local reminderMessages = {}

    for _, reminder in pairs(reminders) do
        local message = Reminders:ProcessReminder(reminder)

        if message ~= nil and message ~= "" then
            tinsert(reminderMessages, message)
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
    local message, condition = ParseReminder(text)

    if message == nil or message == "" or condition == nil or condition == "" then
        -- TODO:  Print out "empty params" msg somewhere
        debug("message or condition was empty or nil")
        return
    end

    -- Don't save reminders where the message and reminder already exist
    for i, reminder in ipairs(self.db.global.reminders) do
        debug("i = "..i)
        -- debug("reminder = "..reminder)

        if reminder.message:lower() == message:lower() and data.condition:lower() == condition:lower() then
            debug("Reminder with text '"..message.."' and condition '"..condition .."' already exists")
            -- TODO:  Print out "already added" msg somewhere
            return
        end
    end

    tinsert(self.db.global.reminders, { message = message, condition = condition })
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

    return array[1], array[2]
end

function Reminders:DebugPrintReminders()
    reminders = self.db.global.reminders
    for _, reminder in pairs(reminders) do
        chatMessage(reminder.message .. " -> " .. reminder.condition)
    end
end

function dbDefaults()
    return  {
      global = {
        reminders = {},
      }
    }
end
