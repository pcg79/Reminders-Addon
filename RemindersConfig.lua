local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local function SetDefaultDay(_, val)
    RemindersDB.char.defaultDay = val
end

local function GetDefaultDay(_)
    if not RemindersDB.char.defaultDay then
        RemindersDB.char.defaultDay = 3 -- Tuesday
    end

    return RemindersDB.char.defaultDay
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
                name = "Look and Feel",
                inline = true,
                order = 1,
                args = {
                    defaultDay = {
                        name = "Default Day",
                        desc = "Per character Default day for Weekly reminders",
                        type = "select",
                        values = Reminders:DayList(),
                        get = GetDefaultDay,
                        set = SetDefaultDay,
                        style = "dropdown",
                        order = 1.1,
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
                        name = "Debug",
                        desc = "Enables / disables debugging (requires UI reload)",
                        type = "toggle",
                        get = function(_) return RemindersDB.char.debug end,
                        set = function(_, val) RemindersDB.char.debug = val end,
                        order = 2.1,
                    },
                },
            },
        }
    }

    AceConfig:RegisterOptionsTable(Reminders:GetName(), options)
    local optionsFrame = AceConfigDialog:AddToBlizOptions(Reminders:GetName())

    optionsFrame.default = SetDefaultOptions

end
