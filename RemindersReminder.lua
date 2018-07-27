-- Globals
local R_EVERYONE   = "*"
local R_CLASS      = "class"
local R_PROFESSION = "profession"
local R_LEVEL      = "level"
local R_NAME       = "name"
local R_ILEVEL     = "ilevel"

local R_AND = "and"
local R_OR  = "or"


function CalculateNextRemindAt(self)
    local secondsInADay = 24 * 60 * 60
    local timeNow = time()
    local nextRemindAt = nil
    local interval = self.interval
    local timeUntilnextRemindAt = nil

    if interval == "daily" then
        timeUntilnextRemindAt = Reminders:GetQuestResetTime()
        nextRemindAt = timeNow + timeUntilnextRemindAt
    elseif interval == "weekly" then
        local nextQuestResetTime = timeNow + Reminders:GetQuestResetTime()
        local nextQuestResetTimeWDay = date("%w", nextQuestResetTime)

        -- We'll have to change this if server resets stop being on Tuesday.
        -- Also not sure how this'll handle internationalization.  I'm guessing poorly.
        -- Might have to change local time to PST, calculate time distance, then
        -- change back to local time.
        local tuesdayIndex = 2
        local numDaysUntilTuesday = (tuesdayIndex - nextQuestResetTimeWDay) % 7

        nextRemindAt = nextQuestResetTime + (numDaysUntilTuesday * secondsInADay)
        timeUntilnextRemindAt = nextRemindAt - timeNow
    elseif interval == "debug" then -- for debugging only (for now)
        timeUntilnextRemindAt = 30
        nextRemindAt = timeNow + timeUntilnextRemindAt
    end

    return { nextRemindAt = nextRemindAt, timeUntilnextRemindAt = timeUntilnextRemindAt }
end

function IsEqual(self, otherReminder)
    return self.message:lower() == otherReminder.message:lower() and
        self.condition:lower()  == otherReminder.condition:lower() and
        self.interval:lower()   == otherReminder.interval:lower()
end

function ToString(self)
    local nextRemindAt = Reminders:GetPlayerReminder(self.id)
    -- debug("[ToString] nextRemindAt = "..(nextRemindAt or "nil"))
    if nextRemindAt then
        nextRemindAt = date("%x %X", nextRemindAt)
    else
        nextRemindAt = "nil"
    end

    local reminderMessage = ""
    if RemindersDB.char.debug then
        reminderMessage = self.id .. " | " .. self.message .. " | " .. self.condition .. " | " .. self.interval .. " | " .. nextRemindAt
    else
        reminderMessage = "Reminding "
        if self.condition == "Everyone" then
            reminderMessage = reminderMessage .. "all characters "
        else
            reminderMessage = reminderMessage .. "characters where " .. self.condition
        end
        reminderMessage = reminderMessage .. " to " .. self.message .. " " .. self.interval
    end

    return reminderMessage
end

function Serialize(self)
    return {
        id = self.id,
        condition = self.condition,
        message = self.message,
        interval = self.interval
    }
end

function SetNextRemindAt(self)
    Reminders:SetPlayerReminder(self.id, self:CalculateNextRemindAt())
end

function SetAndScheduleNextReminder(self, timeUntilnextRemindAt)
    local nextRemindAt = nil
    if timeUntilnextRemindAt then
        nextRemindAt = timeUntilnextRemindAt + time()
    else
        local calculatedTimes = self:CalculateNextRemindAt()
        nextRemindAt = calculatedTimes.nextRemindAt
        timeUntilnextRemindAt = calculatedTimes.timeUntilnextRemindAt
    end

    if self.timer then
        chatMessage("[ " .. date("%X") .. " ] Timer for reminder " .. self.id .. " cancelled")
        Reminders:CancelTimer(self.timer)
    end
    -- The C_Timer wrapper is to work around a bug in C_Timer (which ScheduleTimer uses) where timers close
    -- to login trigger too fast.  http://www.wowinterface.com/forums/showthread.php?p=329035#post329035
    C_Timer.After(0, function()
        self.timer = Reminders:ScheduleTimer("EvaluateReminders", timeUntilnextRemindAt, self)
    end)

    chatMessage("[ " .. date("%X") .. " ] Timer scheduled for reminder " .. self.id .. ".")
    chatMessage("[ " .. date("%X") .. " ] It should fire in " .. timeUntilnextRemindAt .. " seconds (" .. nextRemindAt .. " aka " .. date("%X", nextRemindAt ) .. ")")

    Reminders:SetPlayerReminder(self.id, nextRemindAt)
end

function Evaluate(self)
    local message = self:Process()
    -- If Process returned a message, that means the reminder triggered.
    -- That also means nextRemindAt has changed so we need to update the reminder in the DB.
    if message and message ~= "" then
        self:Save()

        return {
            text = message,
            textHeight = 100,
            button = "Snooze",
            buttonLeft = 400,
            buttonBottom = -10,
            buttonClick = function(this, button)
                -- Because reminders are only checked on ui load, we'll just set the next
                -- remind time for a few seconds in the future and then it'll popup again
                -- on next reload.
                -- TODO: If I ever implement a timer or event-based reminder checking,
                -- change this to something like 5-10 minutes in the future.
                local snooze = 5
                self:SetAndScheduleNextReminder(snooze)
                chatMessage("Reminder for |cff32cd32" .. message .. "|r has been snoozed for " .. snooze .. " seconds")
            end
        }
    end
end

-- Does this toon qualify for this reminder?
--     If they do, does this toon already have this reminder?
--         If they do, we'll check their own personal next remind at and remind (and resave) if required
--         If they don't, we'll remind and save this reminder to their personal DB.
--     If they don't qualify for this reminder, do they already have the reminder in their personal DB?
--         If they do, delete it from their personal DB.
--         If they don't, that's ok, do nothing.
function Process(self)
    local timeNow = time()
    local playerReminder = Reminders:GetPlayerReminder(self.id)
    local shouldRemind = false

    if self:EvaluateCondition() then
        debug("[Process] eval true for "..self.id)
        if playerReminder then
            debug("[Process] player has reminder " .. self.id .. " already")
            debug("timeNow = " .. timeNow)
            debug("playerReminder = " .. playerReminder)
            if timeNow >= playerReminder then
                shouldRemind = true
            end
        else -- This toon has never seen this reminder but they quality for it
            -- We could make this a config setting.  "Remind first time immediately"
            debug("[Process] player does NOT have reminder already")
            shouldRemind = true
        end

        self:SetAndScheduleNextReminder()

        if shouldRemind then
            return self.message
        end
    elseif playerReminder then
        -- The toon once qualified for this reminder but doesn't any more so let's delete it
        Reminders:DeletePlayerReminder(self.id)
    end
end

function Save(self)
    if not self.id then
        RemindersDB.global.remindersCount = RemindersDB.global.remindersCount + 1
        self.id = "r"..RemindersDB.global.remindersCount
    end

    debug("Saving id " .. self.id)

    RemindersDB.global.reminders[self.id] = self:Serialize()
end

function Delete(self)
    local id = nil
    if type(self) == "table" then
        id = self.id
    elseif type(self) == "string" then
        id = self
    end
    debug("Deleting id " .. id)

    RemindersDB.global.reminders[id] = nil
end

function Reminders:BuildReminder(params)
    local self = {}
    self.message = params.message
    self.condition = params.condition
    self.interval = (params.interval or "daily")
    self.id = params.id
    self.timer = params.timer

    self.IsEqual = IsEqual
    self.ToString = ToString
    -- self.SetNextRemindAt = SetNextRemindAt
    self.SetAndScheduleNextReminder = SetAndScheduleNextReminder
    self.CalculateNextRemindAt = CalculateNextRemindAt
    self.Process = Process
    self.EvaluateCondition = EvaluateCondition
    self.Save = Save
    self.Delete = Delete
    self.DeletePlayerReminder = DeletePlayerReminder
    self.Serialize = Serialize
    self.Evaluate = Evaluate

    return self
end

function Reminders:GetQuestResetTime()
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


-- We build up a string to evaluate based on any conditions we find
-- then we evaluate the string as a whole.
function EvaluateCondition(self)
    local condition = self.condition

    -- debug("[EvaluateCondition] id = " .. self.id .. ", condition = " .. condition)

    -- Go through each condition
    -- everyone
    -- name
    -- level
    -- class
    -- profession
    -- ilevel
    local evalString = ""
    local tokens = {}
    local tokenCount = 0
    for token in string.gmatch(condition, "[^ ]+") do
        tokenCount = tokenCount + 1
        tokens[tokenCount] = token
    end

    local toSkip = 0
    for i=1, tokenCount do

        if toSkip <= 0 then
            local token = tokens[i]:lower()
            local count = 0

            if token == R_EVERYONE then
                return true
            elseif token == R_NAME then
                count = count + 1
                local operation = tokens[i+count]
                count = count + 1
                local name = tokens[i+count]
                local playerName = UnitName("player")

                evalString = evalString.." "..tostring(playerName == name)

            elseif token == R_LEVEL then
                count = count + 1
                local operation = tokens[i+count]
                count = count + 1
                local level = tokens[i+count]

                -- TODO: This isn't necessary any more.  Change the operation to just be "=="
                if operation == "=" then
                    operation = "=="
                end

                local playerLevel = UnitLevel("player")
                local levelStmt = "return "..playerLevel..operation..level
                local levelFunc = assert(loadstring(levelStmt))
                local result, errorMsg = levelFunc()

                evalString = evalString.." "..tostring(result)

            elseif token == R_CLASS then
                count = count + 1
                local operation = tokens[i+count]
                count = count + 1
                local class = tokens[i+count]
                local playerClass = UnitClass("player")

                evalString = evalString.." "..tostring(playerClass == class)

            elseif token == R_PROFESSION then
                count = count + 1
                local operation = tokens[i+count]
                count = count + 1
                local profession = tokens[i+count]:lower()
                local prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions()

                local prof1Name = GetProfessionNameByIndex(prof1) or ""
                local prof2Name = GetProfessionNameByIndex(prof2) or ""

                local profResult = (profession == prof1Name:lower() or profession == prof2Name:lower()) or
                   (profession == "archaeology" and archaeology ~= nil) or
                   (profession == "fishing" and fishing ~= nil) or
                   (profession == "cooking" and cooking ~= nil) or
                   (profession == "firstaid" and firstAid ~= nil)

                evalString = evalString.." "..tostring(profResult)

            elseif token == R_ILEVEL then
                count = count + 1
                local operation = tokens[i+count]

                -- TODO: This isn't necessary any more.  Change the operation to just be "=="
                if operation == "=" then
                    operation = "=="
                end
                count = count + 1
                local ilevel = tokens[i+count]
                local playerILevel = GetAverageItemLevel()
                local ilevelStmt = "return "..playerILevel..operation..ilevel
                local ilevelFunc = assert(loadstring(ilevelStmt))
                local result, errorMsg = ilevelFunc()

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

        local evalFunc = assert(loadstring(evalString))
        local result, errorMsg = evalFunc()

        return result
    end
end
