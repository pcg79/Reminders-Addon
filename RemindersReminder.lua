-- Globals
local R_EVERYONE   = "*"
local R_CLASS      = "class"
local R_PROFESSION = "profession"
local R_LEVEL      = "level"
local R_NAME       = "name"
local R_ILEVEL     = "ilevel"

local R_AND = "and"
local R_OR  = "or"

local remindersTimers = {}

local function CalculateNextRemindAt(self)
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

local function IsEqual(self, otherReminder)
    return self.message:lower() == otherReminder.message:lower() and
        self.condition:lower()  == otherReminder.condition:lower() and
        self.interval:lower()   == otherReminder.interval:lower()
end

local function ToString(self)
    local nextRemindAt = Reminders:GetPlayerReminder(self.id)
    -- Reminders:debug("[ToString] nextRemindAt = "..(nextRemindAt or "nil"))
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

local function Serialize(self)
    return {
        id = self.id,
        condition = self.condition,
        message = self.message,
        interval = self.interval
    }
end

local function CancelReminderTimer(id)
    Reminders:debug("Timer cancelled for reminder " .. id)

    Reminders:CancelTimer(remindersTimers[id])
    remindersTimers[id] = nil
end

local function SetAndScheduleNextReminder(self, timeUntilnextRemindAt)
    local nextRemindAt = Reminders:GetPlayerReminder(self.id)
    local timeNow = time()

    if timeUntilnextRemindAt then
        timeUntilnextRemindAt = floor(timeUntilnextRemindAt)
        -- Snoozed so set for time + snoozed time
        nextRemindAt = timeUntilnextRemindAt + timeNow
    elseif nextRemindAt and nextRemindAt > timeNow then
        -- Toon already has an entry for this reminder and it's in the future
        -- so set for that amount of time
        timeUntilnextRemindAt = nextRemindAt - timeNow
    else
        -- No reminder yet or it was in the past.  Recalcuate correct next
        -- remind time
        local calculatedTimes = self:CalculateNextRemindAt()
        nextRemindAt = calculatedTimes.nextRemindAt
        timeUntilnextRemindAt = calculatedTimes.timeUntilnextRemindAt
    end

    if remindersTimers[self.id] then
        CancelReminderTimer(self.id)
    end
    -- The C_Timer wrapper is to work around a bug in C_Timer (which ScheduleTimer uses) where timers close
    -- to login trigger too fast.  http://www.wowinterface.com/forums/showthread.php?p=329035#post329035
    C_Timer.After(0, function()
        remindersTimers[self.id] = Reminders:ScheduleTimer("EvaluateReminders", timeUntilnextRemindAt, self)
    end)

    Reminders:debug("Timer scheduled for reminder " .. self.id .. ".")
    Reminders:debug("It should fire in " .. timeUntilnextRemindAt .. " seconds (" .. nextRemindAt .. " aka " .. date("%X", nextRemindAt ) .. ")")

    Reminders:SetPlayerReminder(self.id, nextRemindAt)
end

local function Evaluate(self)
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
                local snooze = 10
                if RemindersDB.char.debug then
                    snooze = .1667
                end
                self:SetAndScheduleNextReminder(snooze * 60)
                Reminders:ChatMessage("Reminder for |cff32cd32" .. message .. "|r has been snoozed for " .. snooze .. " minutes")
                this:SetText("Snoozed!")
                this:Disable()
            end
        }
    end
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
local function EvaluateCondition(self)
    local condition = self.condition

    -- Reminders:debug("[EvaluateCondition] id = " .. self.id .. ", condition = " .. condition)

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
                local prof1, prof2, archaeology, fishing, cooking = GetProfessions()

                local prof1Name = GetProfessionNameByIndex(prof1) or ""
                local prof2Name = GetProfessionNameByIndex(prof2) or ""

                local profResult = (profession == prof1Name:lower() or profession == prof2Name:lower()) or
                   (profession == "archaeology" and archaeology ~= nil) or
                   (profession == "fishing" and fishing ~= nil) or
                   (profession == "cooking" and cooking ~= nil)

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


-- Does this toon qualify for this reminder?
--     If they do, does this toon already have this reminder?
--         If they do, we'll check their own personal next remind at and remind (and resave) if required
--         If they don't, we'll remind and save this reminder to their personal DB.
--     If they don't qualify for this reminder, do they already have the reminder in their personal DB?
--         If they do, delete it from their personal DB.
--         If they don't, that's ok, do nothing.
local function Process(self)
    local timeNow = time()
    local playerReminder = Reminders:GetPlayerReminder(self.id)
    local shouldRemind = false

    if self:EvaluateCondition() then
        Reminders:debug("[Process] eval true for "..self.id)
        if playerReminder then
            Reminders:debug("[Process] player has reminder " .. self.id .. " already")
            Reminders:debug("[Process] timeNow = " .. timeNow .. " (aka " .. date("%X", timeNow ) .. ")")
            Reminders:debug("[Process] playerReminder = " .. playerReminder.. " (aka " .. date("%X", playerReminder ) .. ")")
            if timeNow >= playerReminder then
                shouldRemind = true
            end
        else -- This toon has never seen this reminder but they qualify for it
            -- We could make this a config setting.  "Remind first time immediately"
            Reminders:debug("[Process] player does NOT have reminder already")
            shouldRemind = true
        end

        if shouldRemind or not remindersTimers[self.id] then
            self:SetAndScheduleNextReminder()
        end

        if shouldRemind then
            return self.message
        end
    elseif playerReminder then
        -- The toon once qualified for this reminder but doesn't any more so let's delete it
        Reminders:DeletePlayerReminder(self.id)
    end
end

local function Save(self)
    if not self.id then
        RemindersDB.global.remindersCount = RemindersDB.global.remindersCount + 1
        self.id = "r"..RemindersDB.global.remindersCount
    end

    Reminders:debug("Saving id " .. self.id)

    RemindersDB.global.reminders[self.id] = self:Serialize()
end

local function Delete(self)
    local id = nil
    if type(self) == "table" then
        id = self.id
    elseif type(self) == "string" then
        id = self
    end
    Reminders:debug("Deleting id " .. id)

    CancelReminderTimer(id)

    RemindersDB.global.reminders[id] = nil
end

function Reminders:BuildReminder(params)
    local self = {}
    self.message = params.message
    self.condition = params.condition
    self.interval = (params.interval or "daily")
    self.id = params.id

    self.IsEqual = IsEqual
    self.ToString = ToString
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
