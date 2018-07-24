local AceGUI = LibStub("AceGUI-3.0")

-- Globals
REMINDER_ITEMS = {}
CONDITION_FRAMES = {}
CONDITION_LIST = {
    Everyone   = "*",
    Name       = "name",
    Level      = "level" ,
    iLevel     = "ilevel",
    Profession = "profession",
    Self       = "name",
}

OPERATION_LIST = { }
OPERATION_LIST["Equals"] = "="
-- OPERATION_LIST["Not Equals"] = "~="
OPERATION_LIST["Greater Than"] = ">"
OPERATION_LIST["Greater Than Or Equal To"] = ">="
OPERATION_LIST["Less Than"] = "<"
OPERATION_LIST["Less Than Or Equal To"] = "<="

INTERVAL_LIST = {
    Debug = "debug",
    Daily = "daily",
    Weekly = "weekly"
}

PROFESSION_LIST = {
    Alchemy        = "Alchemy",
    Blacksmithing  = "Blacksmithing",
    Cooking        = "Cooking",
    Enchanting     = "Enchanting",
    Engineering    = "Engineering",
    Fishing        = "Fishing",
    Herbalism      = "Herbalism",
    Inscription    = "Inscription",
    Jewelcrafting  = "Jewelcrafting",
    Leatherworking = "Leatherworking",
    Mining         = "Mining",
    Skinning       = "Skinning",
    Tailoring      = "Tailoring",
}

EDIT_BOX_BACKDROP = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    tile = true, edgeSize = 1, tileSize = 5,
}
MESSAGE_EDIT_BOX = nil

local function SortAlphabetically(a, b)
    return a:lower() < b:lower()
end

local function AlphabeticallySortedList(list)
    local a = {}
    for n in pairs(list) do table.insert(a, n) end
    table.sort(a, SortAlphabetically)

    return a
end

local function AreInputsValid()
    local messageText = MESSAGE_EDIT_BOX:GetText()
    if not messageText or messageText == "" then
        return false
    end

    -- This is (bad) future-proofing for if I want to implement creating multiple conditions that you can
    -- join via AND or OR.
    for _, conditionFrame in pairs(CONDITION_FRAMES) do

        local conditionDropDown = conditionFrame.conditionDropDown
        local operationDropDown = conditionFrame.operationDropDown
        local valueEditBox      = conditionFrame.valueEditBox
        local professionDropDown = conditionFrame.professionDropDown

        local conditionText = conditionDropDown.text:GetText()
        if conditionText == "Condition" then
            return false
        elseif conditionText ~= "Everyone" and conditionText ~= "Self" then
            local operationText = operationDropDown.text:GetText()
            if operationText == "Operation" then
                return false
            end
        end

        if valueEditBox:IsEnabled() then
            local value = valueEditBox:GetText()

            if conditionText == "iLevel" or conditionText == "Level" then
                value = tonumber(value)
            end

            if not value or value == "" then
                return false
            end
        elseif conditionText == "Profession" then
            local professionText = professionDropDown.text:GetText()
            if professionText == "Profession" then
                return false
            end
        end

        local intervalText = IntervalDropDown.text:GetText()
        if intervalText == "Interval" then
            return false
        end
    end

    return true
end

local function OnInputValueChanged(widget)
    if AreInputsValid() then
        CreateButton:Enable()
    else
        CreateButton:Disable()
    end
end

local function CreateReminder()
    if AreInputsValid() then
        local reminderText = BuildReminderText()

        Reminders:AddReminder(reminderText)
        Reminders:ResetInputUI()
    end
end


function Reminders:CreateUI()
    local frameName = "RemindersFrame"

    local gui = CreateFrame("Frame", frameName, UIParent, "UIPanelDialogTemplate")
    gui:Hide()

    gui:SetSize(1000, 600)
    gui:SetPoint("CENTER")
    gui:EnableMouse(true)
    gui.Title:SetText("Reminders")

    CreateMessageEditBox(gui)

    Reminders:CreateConditionFrame(gui)

    Reminders:CreateScrollFrame(gui)

    CreateIntervalDropDown(gui)

    CreateButton = CreateFrame("Button", frameName.."Create", gui, "UIPanelButtonTemplate")
    CreateButton:SetScript("OnClick", CreateReminder)
    CreateButton:SetPoint("TOPLEFT", 860, -48)
    CreateButton:SetHeight(20)
    CreateButton:SetWidth(100)
    CreateButton:SetText("Create")
    CreateButton:Disable()

    local closeButton = CreateFrame("Button", frameName.."Close", gui, "UIPanelButtonTemplate")
    closeButton:SetScript("OnClick", function(self) gui:Hide() end)
    closeButton:SetPoint("BOTTOMRIGHT", -27, 17)
    closeButton:SetHeight(20)
    closeButton:SetWidth(100)
    closeButton:SetText("Close")

    return gui
end

function CreateMessageEditBox(parentFrame)
    local editbox = CreateFrame("EditBox", "MessageEditBox", parentFrame)
    editbox:SetPoint("TOPLEFT", parentFrame, 50, -50)
    editbox:SetScript("OnEnterPressed", CreateReminder)
    editbox:SetScript("OnTextChanged", OnInputValueChanged)
    editbox:SetFontObject(GameFontHighlightSmall)
    editbox:SetWidth(500)
    editbox:SetHeight(25)
    editbox:EnableMouse(true)
    editbox:SetBackdrop(EDIT_BOX_BACKDROP)
    editbox:SetBackdropColor (0, 0, 0, 0.5)
    editbox:SetBackdropBorderColor (0.3, 0.3, 0.30, 0.80)

    MESSAGE_EDIT_BOX = editbox
end

function CreateIntervalDropDown(parentFrame)
    IntervalDropDown = AceGUI:Create("Dropdown")
    IntervalDropDown.frame:SetParent(parentFrame)
    IntervalDropDown.frame:SetPoint("TOPLEFT", 560, -48)
    IntervalDropDown.frame:Show()
    IntervalDropDown:SetLabel("")
    IntervalDropDown:SetWidth(100)
    IntervalDropDown:SetText("Interval")
    IntervalDropDown:SetList(AlphabeticallySortedList(INTERVAL_LIST))
    IntervalDropDown:SetCallback("OnValueChanged", OnInputValueChanged);

end

function BuildReminderText()
    local messageText = MESSAGE_EDIT_BOX:GetText()
    if not messageText or messageText == "" then
        -- TODO: Print a friendly error message that the uesr didn't type a message here.
        return
    end

    local reminderText = messageText .. ","

    -- This is (bad) future-proofing for if I want to implement creating multiple conditions that you can
    -- join via AND or OR.
    for _, conditionFrame in pairs(CONDITION_FRAMES) do

        local conditionText = conditionFrame.conditionDropDown.text:GetText()
        if conditionText == "Condition" then
            -- TODO: Print a friendly error message that the user didn't choose a condition here.
            return
        end

        debug("conditionText = " .. conditionText)
        reminderText = reminderText .. CONDITION_LIST[conditionText]

        -- Apparently there's no "IsEnabled()" on UIDropDownMenus so we'll just check
        -- for the condition(s) that doesn't use an operation
        if conditionText == "Self" then
            reminderText = reminderText .. " = " .. UnitName("player")
        elseif conditionText ~= "Everyone" then
            local operationText = conditionFrame.operationDropDown.text:GetText()
            debug("operationText = " .. operationText)
            if operationText == "Operation" then
                -- TODO: Print a friendly error message that the user didn't choose an operation here.
                return
            end
            reminderText = reminderText .. " " .. OPERATION_LIST[operationText]
        end

        if conditionFrame.valueEditBox:IsEnabled() then
            debug("is enabled")
            local value = conditionFrame.valueEditBox:GetText()
            if not value or value == "" then
                -- TODO: Print a friendly error message that the user didn't type a value here.
                return
            end
            reminderText = reminderText .. " " .. conditionFrame.valueEditBox:GetText()
        elseif conditionText == "Profession" then
            local professionText = conditionFrame.professionDropDown.text:GetText()
            debug("professionText = " .. professionText)
            if professionText == "Profession" then
                -- TODO: Print a friendly error message that the user didn't choose a profession here.
                return
            end
            reminderText = reminderText .. " " .. professionText
        end

        local intervalText = IntervalDropDown.text:GetText()
        reminderText = reminderText .. "," .. INTERVAL_LIST[intervalText]
    end

    return reminderText
end

local function ConditionDropDownOnValueChanged(conditionDropDown, event, value)
    -- for k,v in pairs(conditionDropDown) do
    --     debug("k = " .. k)
    -- end

    local conditionText = conditionDropDown.text:GetText()
    local operationDropDown = conditionDropDown.operationDropDown
    local valueEditBox = conditionDropDown.valueEditBox
    local professionDropDown = conditionDropDown.professionDropDown

    operationDropDown:SetDisabled(false)

    debug("conditionText = " .. conditionText)
    debug("event = " .. event)
    debug("value = " .. value)
    debug("operationDropDown.text:GetText() = " .. (operationDropDown.text:GetText() or ""))

    valueEditBox:Enable()
    valueEditBox:Show()
    professionDropDown.frame:Hide()

    if conditionText == "Everyone" or conditionText == "Self" then
        operationDropDown:SetText("")
        operationDropDown:SetDisabled(true)
        valueEditBox:Disable()
    elseif conditionText == "Name" or conditionText == "Profession" then
        operationDropDown:SetText("Equals")
        operationDropDown:SetDisabled(true)

        if conditionText == "Profession" then
            valueEditBox:Hide()
            valueEditBox:Disable()
            professionDropDown.frame:Show()
        end
    else
        operationDropDown:SetText("Operation")
    end

    OnInputValueChanged()
end

function Reminders:CreateConditionFrame(parentFrame)
    debug("[CreateConditionFrame] here")

    local i = 1
    -- Name should include an id and we should put these into a reusable pool
    local conditionFrame = CreateFrame("Frame", "ConditionFrame", parentFrame)
    conditionFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, -100)
    conditionFrame:SetSize(1000, 100)

    local conditionDropDown = AceGUI:Create("Dropdown")
    conditionDropDown.frame:SetParent(conditionFrame)
    conditionDropDown.frame:SetPoint("TOPLEFT", 46, 0)
    conditionDropDown.frame:Show()
    conditionDropDown:SetLabel("")
    conditionDropDown:SetWidth(100)
    conditionDropDown:SetText("Condition")
    conditionDropDown:SetList(AlphabeticallySortedList(CONDITION_LIST))
    conditionDropDown:SetCallback("OnValueChanged", ConditionDropDownOnValueChanged)


    local operationDropDown = AceGUI:Create("Dropdown")
    operationDropDown.frame:SetParent(conditionFrame)
    operationDropDown.frame:SetPoint("TOPLEFT", 200, 0)
    operationDropDown.frame:Show()
    operationDropDown:SetLabel("")
    operationDropDown:SetWidth(180)
    operationDropDown:SetText("Operation")
    operationDropDown:SetList(AlphabeticallySortedList(OPERATION_LIST))
    operationDropDown:SetCallback("OnValueChanged", OnInputValueChanged)

    operationDropDown.conditionDropDown = conditionDropDown


    local professionDropDown = AceGUI:Create("Dropdown")
    professionDropDown.frame:SetParent(conditionFrame)
    professionDropDown.frame:SetPoint("TOPLEFT", 450, 0)
    professionDropDown.frame:Show()
    professionDropDown:SetLabel("")
    professionDropDown:SetWidth(180)
    professionDropDown:SetText("Profession")
    professionDropDown:SetList(AlphabeticallySortedList(PROFESSION_LIST))
    professionDropDown:SetCallback("OnValueChanged", OnInputValueChanged)

    professionDropDown.conditionDropDown = conditionDropDown
    professionDropDown.frame:Hide()


    local valueEditBox = CreateFrame("EditBox", "ValueEditBox", conditionFrame)
    valueEditBox:SetPoint("TOPLEFT", conditionFrame, 450, 0)
    valueEditBox:SetFontObject(GameFontHighlightSmall)
    valueEditBox:SetWidth(100)
    valueEditBox:SetHeight(25)
    valueEditBox:EnableMouse(true)
    valueEditBox:SetBackdrop(EDIT_BOX_BACKDROP)
    valueEditBox:SetBackdropColor (0, 0, 0, 0.5)
    valueEditBox:SetBackdropBorderColor (0.3, 0.3, 0.30, 0.80)
    valueEditBox:SetScript("OnEnterPressed", CreateReminder)
    valueEditBox:SetScript("OnTextChanged", OnInputValueChanged)


    conditionFrame.conditionDropDown = conditionDropDown
    conditionFrame.operationDropDown = operationDropDown
    conditionFrame.valueEditBox      = valueEditBox
    conditionFrame.professionDropDown = professionDropDown

    -- So I can reference these in ConditionDropDownOnClick
    -- Not sure if these's a better way to access them without making them global
    conditionDropDown.operationDropDown = operationDropDown
    conditionDropDown.valueEditBox = valueEditBox
    conditionDropDown.professionDropDown = professionDropDown

    CONDITION_FRAMES[i] = conditionFrame
end

function Reminders:LoadReminders(parentFrame)
    local i = 0
    for key, reminder in pairs(RemindersDB.global.reminders) do
        i = i + 1
        debug("[LoadReminders] i = " .. i)
        debug("[LoadReminders] key = " .. key)
        local reminder = Reminders:BuildReminder(reminder)
        debug("[LoadReminders] reminder.id = " .. reminder.id)
        local reminderItem = REMINDER_ITEMS[i] or CreateFrame("Button", "reminderItemFrame"..i, parentFrame.scrollList, "UIPanelButtonTemplate")
        reminderItem:SetSize(SCROLLWIDTH - 60, 50)
        reminderItem:SetPoint("TOP", 0, -(50 * (i - 1)))
        reminderItem.text = reminderItem.text or reminderItem:CreateFontString("Text", "ARTWORK", "NumberFontNormalSmall")
        reminderItem.text:SetSize(SCROLLWIDTH - 60, 50)
        reminderItem.text:SetJustifyH("LEFT")
        reminderItem.text:SetPoint("TOPLEFT", 10, 0)
        reminderItem.text:SetText(reminder:ToString())
        reminderItem:SetScript("OnClick", function(self, button)
            if IsAltKeyDown() then
                reminder:Delete()
                Reminders:LoadReminders(parentFrame)
            else
                debug("i = "..i.." for reminder '" .. reminder.message .."'")

                local reminderMessage = reminder:Process()

                if reminderMessage ~= nil and reminderMessage ~= "" then
                    message(reminderMessage)
                    reminder:Save()
                    self.text:SetText(reminder:ToString())
                end
            end
        end)
        reminderItem:Show()
        REMINDER_ITEMS[i] = reminderItem
    end

    local remindersCount = i
    local reminderButtonsCount = #REMINDER_ITEMS

    -- Hide any created buttons that are unused
    if  remindersCount < reminderButtonsCount then
        for i=remindersCount+1, reminderButtonsCount do
            REMINDER_ITEMS[i]:Hide()
        end
    end
end

function Reminders:ResetInputUI()
    MessageEditBox:SetText("")
    IntervalDropDown:SetText("Interval")

    for i, conditionFrame in pairs(CONDITION_FRAMES) do
        conditionFrame.conditionDropDown:SetValue(0)
        conditionFrame.conditionDropDown:SetText("Condition")
        conditionFrame.operationDropDown:SetDisabled(false)
        conditionFrame.operationDropDown:SetValue(0)
        conditionFrame.operationDropDown:SetText("Operation")
        conditionFrame.valueEditBox:Enable()
        conditionFrame.valueEditBox:SetText("")
        conditionFrame.valueEditBox:Show()
        conditionFrame.professionDropDown:SetText("Profession")
        conditionFrame.professionDropDown.frame:Hide()
        if i > 1 then
            conditionFrame:Hide()
        end
    end
end

StaticPopupDialogs["REMINDERS_REMOVE_ALL_CONFIRM"] = {
    preferredIndex = STATICPOPUPS_NUMDIALOGS,
    text = "Are you sure you would like to remove ALL Reminders?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        Reminders:ResetAll()
    end,
    timeout = 30,
    whileDead = 1,
    hideOnEscape = 1,
}

