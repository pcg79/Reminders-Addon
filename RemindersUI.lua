local AceGUI = LibStub("AceGUI-3.0")

-- File-local state (previously leaked into _G; see #40)
local REMINDER_ITEMS = {}

local CONDITION_LIST_DEFAULT = "Condition"
local CONDITION_FRAMES = {}
local CONDITION_LIST = {
    Everyone   = "*",
    Name       = "name",
    Level      = "level" ,
    iLevel     = "ilevel",
    Profession = "profession",
    Self       = "name",
}

local OPERATION_LIST = { }
OPERATION_LIST["Equals"] = "="
OPERATION_LIST["Not Equals"] = "~="
OPERATION_LIST["Greater Than"] = ">"
OPERATION_LIST["Greater Than Or Equal To"] = ">="
OPERATION_LIST["Less Than"] = "<"
OPERATION_LIST["Less Than Or Equal To"] = "<="

local INTERVAL_LIST_DEFAULT = "Interval"
local INTERVAL_LIST = {
    Daily = "daily",
    Weekly = "weekly"
}

local PROFESSION_LIST_DEFAULT = "Profession"
local PROFESSION_LIST = {
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

local MESSAGE_EDIT_BOX = nil

-- Assigned later inside functions but referenced across this file, so they need
-- a file-level local declaration up front.
local IntervalDropDown
local DayDropDown
local CreateButton
local CrossCharCheck


-- Utility functions --

-- Sort function from https://stackoverflow.com/a/15706820/367697
local function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

local function SortByNextRemindAt(t, a, b)
    -- I need a big number to make sure the reminders that the current character
    -- doesn't have reminders for filter to the top
    local aNextRemindAt = Reminders:GetPlayerReminder(a) or 99999999999
    local bNextRemindAt = Reminders:GetPlayerReminder(b) or 99999999999

    if aNextRemindAt == bNextRemindAt then
        a = tonumber(strsub(a, 2))
        b = tonumber(strsub(b, 2))
        return a < b
    end

    return aNextRemindAt < bNextRemindAt
end

-- Stable list order by creation (ids are "r1", "r2", ...), so enabling or
-- disabling a reminder (or rescheduling it) never reorders the list.
local function SortByCreation(t, a, b)
    return tonumber(strsub(a, 2)) < tonumber(strsub(b, 2))
end

local function SortAlphabetically(t, a, b)
    return a:lower() < b:lower()
end

local function AlphabeticallySortedList(list)
    local a = {}

    for k,v in spairs(list, SortAlphabetically) do
        table.insert(a, k)
    end

    return a
end

local function NextRemindAtSortedList(list)
    local a = {}

    for k,v in spairs(list, SortByNextRemindAt) do
        a[k] = v
    end

    return a
end

local function DayListDefault()
    return Reminders:DayList()[RemindersDB.char.defaultDay]
end

-- AceGUI keeps a checkmark on the last-selected pullout item even after the
-- dropdown's value/text is changed to something else.  SetValue/SetText update
-- the collapsed text but don't uncheck the old item, so it stays visually
-- checked (e.g. "Greater Than" showing a check while the dropdown reads
-- "Operation").  Explicitly uncheck every item in the pullout.
local function ClearDropDownChecks(dropdown)
    if dropdown and dropdown.pullout then
        for _, item in dropdown.pullout:IterateItems() do
            if item.SetValue then
                item:SetValue(false)
            end
        end
    end
end

-- UI --

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
        if conditionText == CONDITION_LIST_DEFAULT then
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
        elseif conditionText == PROFESSION_LIST_DEFAULT then
            local professionText = professionDropDown.text:GetText()
            if professionText == PROFESSION_LIST_DEFAULT then
                return false
            end
        end

        local intervalText = IntervalDropDown.text:GetText()
        if intervalText == INTERVAL_LIST_DEFAULT then
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

local function AddReminder(newReminder)
    -- Don't save reminders where the message, reminder, and interval already exist
    for key, reminder in pairs(RemindersDB.global.reminders) do
        Reminders:debug("[AddReminder] looping...")
        local reminder = Reminders:BuildReminder(reminder)
        if reminder:IsEqual(newReminder) then
            Reminders:debug("[Error] Reminder with text '"..newReminder.message.."' and condition '"..newReminder.condition .."' and interval '"..newReminder.interval.."' already exists")
            Reminders:ChatMessage("A Reminder for |cff32cd32" .. newReminder.message .. "|r with the same condition and interval already exists!")
            return false
        end
    end

    newReminder:Save()
    -- Don't pre-schedule to the next reset here: leaving it unscheduled makes
    -- the current character "due" (never done), so the next evaluation fires it
    -- and arms its timer -- the same way it's surfaced on other characters. This
    -- keeps creation quiet but consistent across your characters. (#21)

    Reminders:LoadReminders(GUI)
    return true
end

local function ParseReminder(text)
    local array = {}
    for token in string.gmatch(text, "[^,]+") do
        tinsert(array, token:trim())
    end

    return { message = array[1], condition = array[2], interval = array[3], day = array[4] }
end

local function GetIntervalList()
    if RemindersDB.char.debug then
        local interval_list = {}

        for k, v in pairs(INTERVAL_LIST) do
            interval_list[k] = v
        end

        interval_list["Debug"] = "debug"
        return interval_list
    else
        return INTERVAL_LIST
    end
end

local function BuildReminderText()
    if not AreInputsValid() then
        return
    end

    local separator = ","

    local messageText = MESSAGE_EDIT_BOX:GetText():gsub(separator, "")

    local reminderText = messageText .. separator

    -- This is (bad) future-proofing for if I want to implement creating multiple conditions that you can
    -- join via AND or OR.
    for _, conditionFrame in pairs(CONDITION_FRAMES) do
        local conditionDropDown = conditionFrame.conditionDropDown
        local operationDropDown = conditionFrame.operationDropDown
        local valueEditBox      = conditionFrame.valueEditBox
        local professionDropDown = conditionFrame.professionDropDown

        local conditionText = conditionDropDown.text:GetText()

        reminderText = reminderText .. CONDITION_LIST[conditionText]

        if conditionText == "Self" then
            reminderText = reminderText .. " = " .. UnitName("player")
        elseif conditionText ~= "Everyone" then
            local operationText = operationDropDown.text:GetText()
            reminderText = reminderText .. " " .. OPERATION_LIST[operationText]
        end

        if valueEditBox:IsEnabled() then
            reminderText = reminderText .. " " .. valueEditBox:GetText():gsub(separator, "")
        elseif conditionText == PROFESSION_LIST_DEFAULT then
            reminderText = reminderText .. " " .. professionDropDown.text:GetText()
        end

        local intervalText = IntervalDropDown.text:GetText()
        reminderText = reminderText .. separator .. GetIntervalList()[intervalText]

        if intervalText == "Weekly" then
            reminderText = reminderText .. separator .. DayDropDown:GetValue()
        end
    end

    return reminderText
end

local function CreateReminder()
    if AreInputsValid() then
        local reminderText = BuildReminderText()
        local params = ParseReminder(reminderText)
        params.crossChar = (CrossCharCheck and CrossCharCheck:GetChecked()) or false
        local newReminder = Reminders:BuildReminder(params)

        -- Only reset the form and report success if the reminder was actually
        -- saved. A duplicate is rejected in AddReminder (which explains why), so
        -- leaving the form as-is lets you adjust it instead of falsely looking
        -- like it worked. (#56)
        if AddReminder(newReminder) then
            Reminders:ResetInputUI()
            Reminders:ChatMessage("Reminder for |cff32cd32" .. newReminder.message .. "|r has been created!")
        end
    end
end

local function EditBoxOnEscapePressed(self)
    GUI:Hide()
end

-- Small gold field label used across the input form.
local function CreateFieldLabel(parentFrame, text, x, y)
    local label = parentFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", x, y)
    label:SetText(text)
    label:SetTextColor(1, 0.82, 0)
    return label
end

-- Faint placeholder text shown in an edit box while it's empty and unfocused.
local function SetPlaceholder(editbox, text)
    local ph = editbox:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    ph:SetPoint("LEFT", editbox, "LEFT", 4, 0)
    ph:SetText(text)

    local function refresh()
        if editbox:HasFocus() or editbox:GetText() ~= "" then
            ph:Hide()
        else
            ph:Show()
        end
    end

    editbox:HookScript("OnTextChanged", refresh)
    editbox:HookScript("OnEditFocusGained", function() ph:Hide() end)
    editbox:HookScript("OnEditFocusLost", refresh)
    refresh()
end

-- Enable/disable the value edit box AND make it look the part: a plain Disable()
-- on an InputBoxTemplate box doesn't visibly grey out, so dim it too.
local function SetValueBoxEnabled(editbox, enabled)
    if enabled then
        editbox:Enable()
        editbox:SetAlpha(1)
    else
        editbox:Disable()
        editbox:SetAlpha(0.5)
    end
end

local function CreateMessageEditBox(parentFrame)
    CreateFieldLabel(parentFrame, "Reminder", 44, -52)

    local editbox = CreateFrame("EditBox", "MessageEditBox", parentFrame, "InputBoxTemplate")
    editbox:SetPoint("TOPLEFT", parentFrame, 50, -68)
    editbox:SetScript("OnEnterPressed", CreateReminder)
    editbox:SetScript("OnEscapePressed", EditBoxOnEscapePressed)
    editbox:SetScript("OnTextChanged", OnInputValueChanged)
    editbox:SetFontObject(GameFontHighlightSmall)
    editbox:SetWidth(560)
    editbox:SetHeight(20)
    editbox:SetAutoFocus(false)

    SetPlaceholder(editbox, "What do you want to be reminded about?")

    MESSAGE_EDIT_BOX = editbox
end

-- Enable/disable the "remind on other characters" checkbox and dim it to match,
-- clearing the check when disabling so it can't be saved for a condition that
-- doesn't support it. (#21)
local function SetCrossCharEnabled(enabled)
    if not CrossCharCheck then return end
    if enabled then
        CrossCharCheck:Enable()
        CrossCharCheck:SetAlpha(1)
    else
        CrossCharCheck:SetChecked(false)
        CrossCharCheck:Disable()
        CrossCharCheck:SetAlpha(0.5)
    end
end

-- Opt-in to also surfacing this reminder on your other characters. Only makes
-- sense for name/Self-targeted reminders, so it's enabled just for those. (#21)
local function CreateCrossCharCheck(parentFrame)
    local check = CreateFrame("CheckButton", "RemindersCrossCharCheck", parentFrame, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 634, -60)
    check:SetSize(24, 24)

    local label = check:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", check, "RIGHT", 2, 0)
    label:SetText("Remind on my other characters")
    label:SetTextColor(1, 0.82, 0)

    check:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Remind on my other characters")
        GameTooltip:AddLine("Also shows this reminder on your other characters that match its condition (as \"(Name) message\").", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    check:SetScript("OnLeave", function() GameTooltip:Hide() end)

    CrossCharCheck = check
    SetCrossCharEnabled(false)
end

local function CreateDayDropDown(parentFrame)
    DayDropDown = AceGUI:Create("Dropdown")
    DayDropDown.frame:SetParent(parentFrame)
    DayDropDown.frame:SetPoint("TOPLEFT", 670, -116)
    DayDropDown.frame:Hide()
    DayDropDown:SetLabel("")
    DayDropDown:SetWidth(110)
    DayDropDown:SetList(Reminders:DayList())
    DayDropDown:SetText(DayListDefault())
    DayDropDown:SetValue(RemindersDB.char.defaultDay)

    DayDropDown:SetCallback("OnValueChanged", OnInputValueChanged)
end

local function IntervalDropDownOnInputValueChanged(intervalDropDown, event, value)
    local intervalText = intervalDropDown.text:GetText()

    if intervalText == "Weekly" then
        DayDropDown.frame:Show()
    else
        DayDropDown.frame:Hide()
    end

    OnInputValueChanged()
end

local function CreateIntervalDropDown(parentFrame)
    CreateFieldLabel(parentFrame, "Interval", 554, -100)

    IntervalDropDown = AceGUI:Create("Dropdown")
    IntervalDropDown.frame:SetParent(parentFrame)
    IntervalDropDown.frame:SetPoint("TOPLEFT", 550, -116)
    IntervalDropDown.frame:Show()
    IntervalDropDown:SetLabel("")
    IntervalDropDown:SetWidth(110)
    IntervalDropDown:SetText(INTERVAL_LIST_DEFAULT)
    IntervalDropDown:SetList(AlphabeticallySortedList(GetIntervalList()))
    IntervalDropDown:SetCallback("OnValueChanged", IntervalDropDownOnInputValueChanged)
end

local function ConditionDropDownOnValueChanged(conditionDropDown, event, value)
    -- for k,v in pairs(conditionDropDown) do
    --     Reminders:debug("k = " .. k)
    -- end

    local conditionText = conditionDropDown.text:GetText()
    local operationDropDown = conditionDropDown.operationDropDown
    local valueEditBox = conditionDropDown.valueEditBox
    local professionDropDown = conditionDropDown.professionDropDown
    local valueLabel = conditionDropDown.valueLabel

    operationDropDown:SetDisabled(false)

    SetValueBoxEnabled(valueEditBox, true)
    valueEditBox:Show()
    professionDropDown.frame:Hide()

    if conditionText == "Everyone" or conditionText == "Self" then
        -- No operation or value applies to this condition.
        operationDropDown:SetValue(0)
        ClearDropDownChecks(operationDropDown)
        operationDropDown:SetText("")
        operationDropDown:SetDisabled(true)
        SetValueBoxEnabled(valueEditBox, false)
        valueEditBox:SetText("")
        if valueLabel then valueLabel:SetText("Value"); valueLabel:Show() end
    elseif conditionText == "Name" or conditionText == PROFESSION_LIST_DEFAULT then
        -- These conditions only support "Equals".
        operationDropDown:SetValue(0)
        ClearDropDownChecks(operationDropDown)
        operationDropDown:SetText("Equals")
        operationDropDown:SetDisabled(true)

        if conditionText == PROFESSION_LIST_DEFAULT then
            valueEditBox:Hide()
            SetValueBoxEnabled(valueEditBox, false)
            valueEditBox:SetText("")
            professionDropDown.frame:Show()
            if valueLabel then valueLabel:SetText("Profession"); valueLabel:Show() end
        else
            if valueLabel then valueLabel:SetText("Value"); valueLabel:Show() end
        end
    else
        -- Level / iLevel accept every operation, so keep an existing selection
        -- (and its checkmark) intact; only fall back to the placeholder when no
        -- genuine operation is chosen (value 0/nil is the "unset" sentinel).
        local currentValue = operationDropDown:GetValue()
        if not (currentValue and currentValue ~= 0) then
            operationDropDown:SetValue(0)
            ClearDropDownChecks(operationDropDown)
            operationDropDown:SetText("Operation")
        end
        if valueLabel then valueLabel:SetText("Value"); valueLabel:Show() end
    end

    -- Cross-character reminding works for any condition (evaluated against each
    -- character's cached attributes), so enable it once a condition is chosen.
    SetCrossCharEnabled(conditionText ~= CONDITION_LIST_DEFAULT)

    OnInputValueChanged()
end

local function CreateConditionFrame(parentFrame)
    local i = 1

    CreateFieldLabel(parentFrame, "Condition", 44, -100)
    CreateFieldLabel(parentFrame, "Operation", 179, -100)
    local valueLabel = CreateFieldLabel(parentFrame, "Value", 366, -100)

    -- Name should include an id and we should put these into a reusable pool
    local conditionFrame = CreateFrame("Frame", "ConditionFrame", parentFrame)
    conditionFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, -116)
    conditionFrame:SetSize(1000, 40)

    local conditionDropDown = AceGUI:Create("Dropdown")
    conditionDropDown.frame:SetParent(conditionFrame)
    conditionDropDown.frame:SetPoint("TOPLEFT", 40, 0)
    conditionDropDown.frame:Show()
    conditionDropDown:SetLabel("")
    conditionDropDown:SetWidth(120)
    conditionDropDown:SetText(CONDITION_LIST_DEFAULT)
    conditionDropDown:SetList(AlphabeticallySortedList(CONDITION_LIST))
    conditionDropDown:SetCallback("OnValueChanged", ConditionDropDownOnValueChanged)


    local operationDropDown = AceGUI:Create("Dropdown")
    operationDropDown.frame:SetParent(conditionFrame)
    operationDropDown.frame:SetPoint("TOPLEFT", 170, 0)
    operationDropDown.frame:Show()
    operationDropDown:SetLabel("")
    operationDropDown:SetWidth(165)
    operationDropDown:SetText("Operation")
    operationDropDown:SetList(AlphabeticallySortedList(OPERATION_LIST))
    operationDropDown:SetCallback("OnValueChanged", OnInputValueChanged)

    operationDropDown.conditionDropDown = conditionDropDown


    local professionDropDown = AceGUI:Create("Dropdown")
    professionDropDown.frame:SetParent(conditionFrame)
    professionDropDown.frame:SetPoint("TOPLEFT", 350, 0)
    professionDropDown.frame:Show()
    professionDropDown:SetLabel("")
    professionDropDown:SetWidth(140)
    professionDropDown:SetText(PROFESSION_LIST_DEFAULT)
    professionDropDown:SetList(AlphabeticallySortedList(PROFESSION_LIST))
    professionDropDown:SetCallback("OnValueChanged", OnInputValueChanged)

    professionDropDown.conditionDropDown = conditionDropDown
    professionDropDown.frame:Hide()


    local valueEditBox = CreateFrame("EditBox", "ValueEditBox", conditionFrame, "InputBoxTemplate")
    valueEditBox:SetPoint("TOPLEFT", conditionFrame, 366, -3)
    valueEditBox:SetFontObject(GameFontHighlightSmall)
    valueEditBox:SetWidth(150)
    valueEditBox:SetHeight(20)
    valueEditBox:SetAutoFocus(false)
    valueEditBox:SetScript("OnEnterPressed", CreateReminder)
    valueEditBox:SetScript("OnEscapePressed", EditBoxOnEscapePressed)
    valueEditBox:SetScript("OnTextChanged", OnInputValueChanged)
    SetValueBoxEnabled(valueEditBox, false) -- disabled until a condition that uses a value is chosen


    conditionFrame.conditionDropDown = conditionDropDown
    conditionFrame.operationDropDown = operationDropDown
    conditionFrame.valueEditBox      = valueEditBox
    conditionFrame.professionDropDown = professionDropDown
    conditionFrame.valueLabel        = valueLabel

    -- So I can reference these in ConditionDropDownOnClick
    -- Not sure if these's a better way to access them without making them global
    conditionDropDown.operationDropDown = operationDropDown
    conditionDropDown.valueEditBox = valueEditBox
    conditionDropDown.professionDropDown = professionDropDown
    conditionDropDown.valueLabel = valueLabel

    CONDITION_FRAMES[i] = conditionFrame
end

function Reminders:CreateUI()
    local frameName = "RemindersFrame"

    local gui = CreateFrame("Frame", frameName, UIParent, "UIPanelDialogTemplate")
    gui:Hide()

    gui:SetSize(1000, 600)
    gui:SetPoint("CENTER")
    gui:EnableMouse(true)
    -- Let the window be dragged by an empty part of its background; the child
    -- widgets (edit boxes, dropdowns, buttons, list) still take their own clicks.
    -- Position isn't persisted, so it re-centers each session. (#60)
    gui:SetMovable(true)
    gui:SetClampedToScreen(true)
    gui:SetScript("OnMouseDown", function() gui:StartMoving() end)
    gui:SetScript("OnMouseUp", function() gui:StopMovingOrSizing() end)
    gui.Title:SetText("Reminders")

    CreateMessageEditBox(gui)
    CreateCrossCharCheck(gui)

    CreateConditionFrame(gui)

    Reminders:CreateScrollFrame(gui)

    CreateIntervalDropDown(gui)
    CreateDayDropDown(gui)

    CreateButton = CreateFrame("Button", frameName.."Create", gui, "UIPanelButtonTemplate")
    CreateButton:SetScript("OnClick", CreateReminder)
    CreateButton:SetPoint("TOPLEFT", 880, -116)
    CreateButton:SetHeight(22)
    CreateButton:SetWidth(100)
    CreateButton:SetText("Create")
    CreateButton:Disable()

    -- Divider separating the create-a-reminder form from the list below
    local divider = gui:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(1, 1, 1, 0.15)
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT", gui, "TOPLEFT", 40, -152)
    divider:SetPoint("TOPRIGHT", gui, "TOPRIGHT", -40, -152)

    local closeButton = CreateFrame("Button", frameName.."Close", gui, "UIPanelButtonTemplate")
    closeButton:SetScript("OnClick", function(self) gui:Hide() end)
    closeButton:SetPoint("BOTTOMRIGHT", -27, 17)
    closeButton:SetHeight(20)
    closeButton:SetWidth(100)
    closeButton:SetText("Close")

    local whatsNewButton = CreateFrame("Button", frameName.."WhatsNew", gui, "UIPanelButtonTemplate")
    whatsNewButton:SetScript("OnClick", function() Reminders:ShowWhatsNew() end)
    whatsNewButton:SetPoint("BOTTOMLEFT", 27, 17)
    whatsNewButton:SetHeight(20)
    whatsNewButton:SetWidth(120)
    whatsNewButton:SetText("What's New")

    return gui
end

local REMINDER_ROW_HEIGHT = 44

local function CreateReminderItem(reminder, i, parentFrame)
    local reminderItem = REMINDER_ITEMS[i]
    if not reminderItem then
        reminderItem = CreateFrame("Button", "reminderItemFrame"..i, parentFrame.scrollList)

        -- Zebra background (shade set per-row below)
        reminderItem.bg = reminderItem:CreateTexture(nil, "BACKGROUND")
        reminderItem.bg:SetAllPoints()

        -- Soft gold hover highlight (same texture the quest log uses)
        reminderItem:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        local highlight = reminderItem:GetHighlightTexture()
        if highlight then
            highlight:SetBlendMode("ADD")
            highlight:SetAlpha(0.35)
        end

        -- Message (primary line)
        reminderItem.title = reminderItem:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        reminderItem.title:SetJustifyH("LEFT")
        reminderItem.title:SetWordWrap(false)
        reminderItem.title:SetPoint("TOPLEFT", 34, -6)
        reminderItem.title:SetPoint("RIGHT", reminderItem, "RIGHT", -170, 0)

        -- Condition (secondary line, dimmed)
        reminderItem.subtitle = reminderItem:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        reminderItem.subtitle:SetJustifyH("LEFT")
        reminderItem.subtitle:SetWordWrap(false)
        reminderItem.subtitle:SetTextColor(0.6, 0.6, 0.6)
        reminderItem.subtitle:SetPoint("TOPLEFT", reminderItem.title, "BOTTOMLEFT", 0, -3)
        reminderItem.subtitle:SetPoint("RIGHT", reminderItem, "RIGHT", -170, 0)

        -- Interval (right-aligned)
        reminderItem.intervalText = reminderItem:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        reminderItem.intervalText:SetJustifyH("RIGHT")
        reminderItem.intervalText:SetTextColor(0.85, 0.72, 0.42)
        reminderItem.intervalText:SetPoint("RIGHT", reminderItem, "RIGHT", -40, 0)

        -- Delete (X) button
        local deleteButton = CreateFrame("Button", nil, reminderItem)
        deleteButton:SetSize(18, 18)
        deleteButton:SetPoint("RIGHT", reminderItem, "RIGHT", -12, 0)
        deleteButton:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
        deleteButton:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight")
        deleteButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Delete this reminder", 1, 0.2, 0.2)
            GameTooltip:Show()
        end)
        deleteButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
        reminderItem.deleteButton = deleteButton

        -- Enable/disable checkbox on the left (checked = enabled)
        local enabledCheck = CreateFrame("CheckButton", nil, reminderItem, "UICheckButtonTemplate")
        enabledCheck:SetSize(24, 24)
        enabledCheck:SetPoint("LEFT", reminderItem, "LEFT", 6, 0)
        enabledCheck:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self:GetChecked() then
                GameTooltip:AddLine("Enabled - click to disable", 1, 1, 1)
            else
                GameTooltip:AddLine("Disabled - click to enable", 1, 1, 1)
            end
            GameTooltip:Show()
        end)
        enabledCheck:SetScript("OnLeave", function() GameTooltip:Hide() end)
        reminderItem.enabledCheck = enabledCheck
    end

    reminderItem:SetSize(SCROLLWIDTH - 80, REMINDER_ROW_HEIGHT)
    reminderItem:ClearAllPoints()
    reminderItem:SetPoint("TOP", 0, -(REMINDER_ROW_HEIGHT * (i - 1)))

    -- Zebra shading (alternate rows)
    local shade = (i % 2 == 0) and 0.05 or 0.09
    reminderItem.bg:SetColorTexture(1, 1, 1, shade)

    if RemindersDB.char.debug then
        -- Keep the raw debug string (id | message | condition | interval | nextRemindAt)
        reminderItem.title:SetText(reminder:ToString())
        reminderItem.subtitle:SetText("")
        reminderItem.intervalText:SetText("")
    else
        reminderItem.title:SetText(reminder.message)

        local conditionText = (reminder.condition == "*") and "All characters" or reminder.condition
        if reminder.crossChar then
            conditionText = conditionText .. "  \194\183  on all my characters"
        end
        reminderItem.subtitle:SetText(conditionText)

        local intervalText = tostring(reminder.interval):gsub("^%l", string.upper)
        if reminder.interval == "weekly" and reminder.day then
            intervalText = intervalText .. " \194\183 " .. (Reminders:DayList()[tonumber(reminder.day)] or "")
        end
        reminderItem.intervalText:SetText(intervalText)
    end

    -- Reflect the enabled/disabled state: checkbox + dimmed text when disabled.
    reminderItem.enabledCheck:SetChecked(not reminder.disabled)
    reminderItem.enabledCheck:SetScript("OnClick", function(self)
        reminder:SetDisabled(not self:GetChecked())
        Reminders:LoadReminders(parentFrame)
    end)

    if reminder.disabled then
        reminderItem.title:SetTextColor(0.45, 0.45, 0.45)
        reminderItem.subtitle:SetTextColor(0.4, 0.4, 0.4)
        reminderItem.intervalText:SetTextColor(0.45, 0.4, 0.3)
    else
        reminderItem.title:SetTextColor(1, 1, 1)
        reminderItem.subtitle:SetTextColor(0.6, 0.6, 0.6)
        reminderItem.intervalText:SetTextColor(0.85, 0.72, 0.42)
    end

    reminderItem:SetScript("OnClick", function(self, button)
        if IsAltKeyDown() then
            reminder:Delete()
            Reminders:LoadReminders(parentFrame)
            Reminders:ChatMessage("Reminder for |cff32cd32" .. reminder.message .. "|r has been deleted!")
        elseif IsControlKeyDown() and RemindersDB.char.debug then
            reminder:SetAndScheduleNextReminder(1)
        else
            Reminders:BuildAndDisplayReminders( { reminder:Evaluate() } )
        end
    end)

    reminderItem.deleteButton:SetScript("OnClick", function()
        reminder:Delete()
        Reminders:LoadReminders(parentFrame)
        Reminders:ChatMessage("Reminder for |cff32cd32" .. reminder.message .. "|r has been deleted!")
    end)

    reminderItem:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Left-click to test", 1, 1, 1)
        GameTooltip:AddLine("Alt+click or the X to delete", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    reminderItem:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    reminderItem:Show()

    return reminderItem
end

function Reminders:LoadReminders(parentFrame)
    local i = 0
    for key, reminder in spairs(RemindersDB.global.reminders, SortByCreation) do
        i = i + 1

        local reminder = Reminders:BuildReminder(reminder)
        REMINDER_ITEMS[i] = CreateReminderItem(reminder, i, parentFrame)
    end

    local remindersCount = i
    local reminderButtonsCount = #REMINDER_ITEMS

    -- Hide any created buttons that are unused
    if  remindersCount < reminderButtonsCount then
        for i=remindersCount+1, reminderButtonsCount do
            REMINDER_ITEMS[i]:Hide()
        end
    end

    -- Grow the scroll child to fit all rows so the list can actually scroll
    parentFrame.scrollList:SetHeight(math.max(remindersCount * REMINDER_ROW_HEIGHT, SCROLLHEIGHT))

    -- Empty state shown when there are no reminders yet
    if not parentFrame.emptyState then
        parentFrame.emptyState = parentFrame.scrollList:CreateFontString(nil, "ARTWORK", "GameFontDisable")
        parentFrame.emptyState:SetPoint("TOP", 0, -24)
        parentFrame.emptyState:SetText("No reminders yet.  Create one above to get started.")
    end
    if remindersCount == 0 then
        parentFrame.emptyState:Show()
    else
        parentFrame.emptyState:Hide()
    end
end

function Reminders:ResetInputUI()
    MESSAGE_EDIT_BOX:SetText("")
    SetCrossCharEnabled(false)
    IntervalDropDown:SetValue(0)
    IntervalDropDown:SetText(INTERVAL_LIST_DEFAULT)
    ClearDropDownChecks(IntervalDropDown)
    DayDropDown:SetText(DayListDefault())
    DayDropDown:SetValue(RemindersDB.char.defaultDay)
    DayDropDown.frame:Hide()

    -- SetValue has to be before SetText or the text is blanked out
    for i, conditionFrame in pairs(CONDITION_FRAMES) do
        conditionFrame.conditionDropDown:SetValue(0)
        conditionFrame.conditionDropDown:SetText(CONDITION_LIST_DEFAULT)
        ClearDropDownChecks(conditionFrame.conditionDropDown)

        conditionFrame.operationDropDown:SetDisabled(false)
        conditionFrame.operationDropDown:SetValue(0)
        conditionFrame.operationDropDown:SetText("Operation")
        ClearDropDownChecks(conditionFrame.operationDropDown)

        SetValueBoxEnabled(conditionFrame.valueEditBox, false)
        conditionFrame.valueEditBox:SetText("")
        conditionFrame.valueEditBox:Show()

        conditionFrame.professionDropDown:SetValue(0)
        conditionFrame.professionDropDown:SetText(PROFESSION_LIST_DEFAULT)
        ClearDropDownChecks(conditionFrame.professionDropDown)
        conditionFrame.professionDropDown.frame:Hide()

        if conditionFrame.valueLabel then
            conditionFrame.valueLabel:SetText("Value")
            conditionFrame.valueLabel:Show()
        end

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

