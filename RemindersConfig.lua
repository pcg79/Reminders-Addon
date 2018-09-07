local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- Default Day

local function SetDefaultDay(_, val)
    RemindersDB.char.defaultDay = val
end

local function GetDefaultDay(_)
    return RemindersDB.char.defaultDay
end

-- Snooze Amount

local function SetSnoozeAmount(_, val)
    RemindersDB.char.snoozeAmount = val
end

local function GetSnoozeAmount(_)
    return RemindersDB.char.snoozeAmount
end


local function SetDefaultOptions()
    Reminders:ResetCharacterOptions()

    --force config dialog to show new state of options
    LibStub("AceConfigRegistry-3.0"):NotifyChange(Reminders:GetName())
end;

function Reminders:CreateOptions()
    options = {
        type = "group",
        args = {
            AddonInfo = {
                type = "group",
                name = "Addon Info",
                inline = true,
                order = 0,
                args = {
                    version = {
                        name = "Version: " .. Reminders.version,
                        type = "description",
                        width = "double",
                        order = 0.1,
                    },
                },
            },

            LookAndFeel = {
                type = "group",
                name = "Behavior",
                inline = true,
                order = 1,
                args = {
                    defaultDay = {
                        name = "Default Day",
                        desc = "Per character Default day for Weekly reminders",
                        type = "select",
                        order = 1.1,
                        values = Reminders:DayList(),
                        get = GetDefaultDay,
                        set = SetDefaultDay,
                        style = "dropdown",
                    },
                    snoozeAmount = {
                        name = "Snooze Amount",
                        desc = "Amount (in minutes) to sleep a reminder",
                        type = "range",
                        order = 1.2,
                        min = 1,
                        max = 1440,
                        step = 1,
                        bigStep = 10,
                        get = GetSnoozeAmount,
                        set = SetSnoozeAmount,
                    },
                },
            },

            OtherOptions = {
                type = "group",
                name = "Other Options",
                inline = true,
                order = 2,
                args = {
                    debug = {
                        name = "Debug mode (requires UI reload)",
                        desc = "Enables / disables debugging",
                        type = "toggle",
                        order = 2.1,
                        get = function(_) return RemindersDB.char.debug end,
                        set = function(_, val) RemindersDB.char.debug = val end,
                    },
                },
            },
        }
    }

    AceConfig:RegisterOptionsTable(Reminders:GetName(), options)
    local optionsFrame = AceConfigDialog:AddToBlizOptions(Reminders:GetName())

    optionsFrame.default = SetDefaultOptions
end
