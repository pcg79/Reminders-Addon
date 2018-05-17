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

    Reminders:PrintReminders()


    if not gui then Reminders:CreateUI() end

    Reminders:LoadReminders()

    Reminders:EvaluateReminders()

    gui:Show()
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

    if next(reminderMessages) ~= nil then
        message(table.concat(reminderMessages, "\n"))
    end
end

function Reminders:ProcessReminder(reminder)
    array = {}
    debug("reminder = "..reminder)
    for token in string.gmatch(reminder, "[^,]+") do
        tinsert(array, token:trim())
    end

    for k,v in pairs(array) do
        debug(k.." = "..v)
    end

    local message   = array[1]
    local condition = array[2]

    debug("message = "..message)
    debug("condition string = "..condition)

    if type(condition) == "string" and Reminders:EvaluateCondition(condition) then
        return message
    else
    end
end

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


                debug("prof1Name = "..prof1Name)
                debug("prof2Name = "..(prof2Name or "nil"))
                debug("archaeology = "..(archaeology or "false"))
                debug("fishing = "..(fishing or "nil"))
                debug("cooking = "..(cooking))
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

function Reminders:LoadReminders()
    offset = 0
    for _, reminder in pairs(self.db.global.reminders) do
        local reminderItem = CreateFrame("Button", nil, reminderList)

        -- reminderItem:SetText(reminder)
        reminderItem:SetPoint("TOPLEFT", 10, -(25 + offset))
        reminderItem:SetHeight(20)
        reminderItem:SetWidth(100)

        reminderItem.text = reminderItem:CreateFontString(reminder.."Text", "ARTWORK", "NumberFontNormalSmall")
        reminderItem.text:SetSize(100, 10)
        reminderItem.text:SetJustifyH("LEFT")
        reminderItem.text:SetPoint("TOPLEFT", 5, -3)
        reminderItem.text:SetText(reminder)

        -- reminderItem.text:SetTextColor(0.67, 0.83, 0.48)


        -- reminderText = reminderItem:CreateFontString(reminder.."Text", "ARTWORK", "NumberFontNormalSmall")
        -- reminderText:SetSize(29, 10)
        -- reminderText:SetJustifyH("LEFT")
        -- reminderText:SetPoint("TOPLEFT", reminderItem.icon, 1, -3)
        -- reminderText:SetText(reminder)

        reminderItem:SetScript("OnClick", function(self)
            debug("clicked - ")
        end)
        offset = offset + 20
    end
end

function Reminders:OnEvent()
    debug('Reminder Loaded')
end

function Reminders:CloseFrame(widget, event)
    debug("closing")
    AceGUI:Release(widget)
    self.frameShown = false
end

function Reminders:SaveReminder(text)
    debug("saving - "..text)
    table.insert(self.db.global.reminders, text)
end

function Reminders:PrintReminders()
    reminders = self.db.global.reminders
    for _, reminder in pairs(reminders) do
        chatMessage(reminder)
    end
end

function dbDefaults()
    return  {
      global = {
        reminders = {},
      }
    }
end
