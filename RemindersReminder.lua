-- Globals
local R_CLASS      = "class"
local R_PROFESSION = "profession"
local R_LEVEL      = "level"
local R_NAME       = "name"
local R_ILVL       = "ilvl"
local R_ILEVEL     = "ilevel"

local R_AND = "and"
local R_OR  = "or"


function CalculateNextRemindAt(self)
    local secondsInADay = 24 * 60 * 60
    local timeNow = time()
    local nextRemindAt = nil
    local interval = self.interval

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
        local tuesdayIndex = 2
        local numDaysUntilTuesday = (tuesdayIndex - nextQuestResetTimeWDay) % 7

        nextRemindAt = nextQuestResetTime + (numDaysUntilTuesday * secondsInADay)
    elseif interval == "now" then -- for debugging only (for now)
        debug("it's now now")
        nextRemindAt = timeNow
    end

    return nextRemindAt
end

function IsEqual(self, otherReminder)
    return self.message:lower() == otherReminder.message:lower() and
        self.condition:lower()  == otherReminder.condition:lower() and
        self.interval:lower()   == otherReminder.interval:lower()
end

function IsValid(self)
    return self.message ~= nil and self.message ~= "" and
        self.condition ~= nil and self.condition ~= "" and
        self.interval ~= nil and self.interval ~= ""
end

function ToString(self)
    return self.message .. " | " .. self.condition .. " | " .. self.interval .. " | " .. date("%x %X", self.nextRemindAt)
end

function SetNextRemindAt(self)
    self.nextRemindAt = self:CalculateNextRemindAt()
end

function Process(self)
    local timeNow = time()

    debug("message = "..self.message)
    debug("condition string = "..self.condition)

    debug("timeNow >= self.nextRemindAt -> "..tostring(timeNow >= self.nextRemindAt))
    debug("self:EvaluateCondition() => "..tostring(self:EvaluateCondition()))
    if timeNow >= self.nextRemindAt and self:EvaluateCondition() then
        debug("[Process] here")
        -- We're showing this one so don't show it again until the next interval
        -- BUG: This isn't great. This means if you have > 1 toon this reminder
        -- would pertain to, you're only going to see it on the first to log in.
        -- Not sure how I'll go about fixing this.
        self:SetNextRemindAt()

        return self.message
    end
end

function Reminders:CreateReminder(params)
    local self = {}
    self.message = params.message
    self.condition = params.condition
    self.interval = (params.interval or "daily")
    self.nextRemindAt = params.nextRemindAt

    self.IsEqual = IsEqual
    self.IsValid = IsValid
    self.ToString = ToString
    self.SetNextRemindAt = SetNextRemindAt
    self.CalculateNextRemindAt = CalculateNextRemindAt
    self.Process = Process
    self.EvaluateCondition = EvaluateCondition

    if self.nextRemindAt == nil then
        self:SetNextRemindAt()
    end

    return self
end


function Reminders:GetQuestResetTime()
    debug("[GetQuestResetTime] mine")
    -- It seems GetQuestResetTime() gives you one second before the actual reset.
    -- So add 1 to get the actual reset.
    return _G.GetQuestResetTime() + 1
end

local function GetProfessionNameByIndex(profIndex)
    if profIndex == nil or profIndex == "" then
        return
    end
    local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier, specializationIndex, specializationOffset = GetProfessionInfo(profIndex)
    return name
end


function EvaluateCondition(self)
-- We build up a string to evaluate based on any conditions we find
-- then we evaluate the string as a whole.
    local condition = self.condition

    debug("[EvaluateCondition] condition = "..condition)
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

                debug("level result = "..tostring(result))

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

            elseif token == R_ILEVEL or token == R_ILVL then
                count = count + 1
                local operation = tokens[i+count]
                count = count + 1
                local ilevel = tokens[i+count]

                debug("(ilevel) operation = "..operation)
                debug("ilevel = "..ilevel)

                local playerILevel = GetAverageItemLevel()

                local ilevelStmt = "return "..playerILevel..operation..ilevel

                debug("stmt: "..ilevelStmt)

                local ilevelFunc = assert(loadstring(ilevelStmt))
                local result, errorMsg = ilevelFunc();

                debug("ilevel result = "..tostring(result))

                evalString = evalString.." "..tostring(result)

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
