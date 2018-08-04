local AceGUI = LibStub("AceGUI-3.0")

-- Globals
REMINDER_ITEMS = {}

CONDITION_LIST_DEFAULT = "Condition"
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

INTERVAL_LIST_DEFAULT = "Interval"
INTERVAL_LIST = {
    Daily = "daily",
    Weekly = "weekly"
}

PROFESSION_LIST_DEFAULT = "Profession"
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
            return
        end
    end

    newReminder:Save()
    newReminder:SetAndScheduleNextReminder()

    Reminders:LoadReminders(GUI)
end

local function ParseReminder(text)
    local array = {}
    for token in string.gmatch(text, "[^,]+") do
        tinsert(array, token:trim())
    end

    return { message = array[1], condition = array[2], interval = array[3] }
end

local function CreateReminder()
    if AreInputsValid() then
        local reminderText = BuildReminderText()
        local newReminder = Reminders:BuildReminder(ParseReminder(reminderText))

        AddReminder(newReminder)
        Reminders:ResetInputUI()

        Reminders:ChatMessage("Reminder for |cff32cd32" .. newReminder.message .. "|r has been created!")
    end
end

local function EditBoxOnEscapePressed(self)
    GUI:Hide()
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
    editbox:SetScript("OnEscapePressed", EditBoxOnEscapePressed)
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
    IntervalDropDown:SetText(INTERVAL_LIST_DEFAULT)
    IntervalDropDown:SetList(AlphabeticallySortedList(GetIntervalList()))
    IntervalDropDown:SetCallback("OnValueChanged", OnInputValueChanged);
end

function BuildReminderText()
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
        Reminders:debug("GetIntervalList()[intervalText] = " .. GetIntervalList()[intervalText])
        reminderText = reminderText .. separator .. GetIntervalList()[intervalText]
    end

    return reminderText
end

local function ConditionDropDownOnValueChanged(conditionDropDown, event, value)
    -- for k,v in pairs(conditionDropDown) do
    --     Reminders:debug("k = " .. k)
    -- end

    local conditionText = conditionDropDown.text:GetText()
    local operationDropDown = conditionDropDown.operationDropDown
    local valueEditBox = conditionDropDown.valueEditBox
    local professionDropDown = conditionDropDown.professionDropDown

    operationDropDown:SetDisabled(false)

    valueEditBox:Enable()
    valueEditBox:Show()
    professionDropDown.frame:Hide()

    if conditionText == "Everyone" or conditionText == "Self" then
        operationDropDown:SetText("")
        operationDropDown:SetDisabled(true)
        valueEditBox:Disable()
    elseif conditionText == "Name" or conditionText == PROFESSION_LIST_DEFAULT then
        operationDropDown:SetText("Equals")
        operationDropDown:SetDisabled(true)

        if conditionText == PROFESSION_LIST_DEFAULT then
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
    conditionDropDown:SetText(CONDITION_LIST_DEFAULT)
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
    professionDropDown:SetText(PROFESSION_LIST_DEFAULT)
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
    valueEditBox:SetScript("OnEscapePressed", EditBoxOnEscapePressed)
    valueEditBox:SetScript("OnTextChanged", OnInputValueChanged)
    valueEditBox:SetAutoFocus(false)


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
    for key, reminder in spairs(RemindersDB.global.reminders, SortByNextRemindAt) do
        i = i + 1

        local reminder = Reminders:BuildReminder(reminder)
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
                Reminders:ChatMessage("Reminder for |cff32cd32" .. reminder.message .. "|r has been deleted!")
            elseif IsControlKeyDown() and RemindersDB.char.debug then
                reminder:SetAndScheduleNextReminder(1)
            else
                Reminders:BuildAndDisplayReminders( { reminder:Evaluate() } )
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
    IntervalDropDown:SetValue(0)
    IntervalDropDown:SetText(INTERVAL_LIST_DEFAULT)

    -- SetValue has to be before SetText or the text is blanked out
    for i, conditionFrame in pairs(CONDITION_FRAMES) do
        conditionFrame.conditionDropDown:SetValue(0)
        conditionFrame.conditionDropDown:SetText(CONDITION_LIST_DEFAULT)

        conditionFrame.operationDropDown:SetDisabled(false)
        conditionFrame.operationDropDown:SetValue(0)
        conditionFrame.operationDropDown:SetText("Operation")

        conditionFrame.valueEditBox:Enable()
        conditionFrame.valueEditBox:SetText("")
        conditionFrame.valueEditBox:Show()

        conditionFrame.professionDropDown:SetValue(0)
        conditionFrame.professionDropDown:SetText(PROFESSION_LIST_DEFAULT)
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

