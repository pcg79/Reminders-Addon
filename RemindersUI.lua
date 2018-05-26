-- Globals
REMINDER_ITEMS = {}
CONDITION_FRAMES = {}
CONDITION_LIST = {
    Everyone   = "*",
    Name       = "name",
    Level      = "level" ,
    iLevel     = "ilevel",
    Profession = "profession",
}
OPERATION_LIST = { }
OPERATION_LIST["Equals"] = "="
-- OPERATION_LIST["Not Equals"] = "~="
OPERATION_LIST["Greater Than"] = ">"
OPERATION_LIST["Greater Than Or Equal To"] = ">="
OPERATION_LIST["Less Than"] = "<"
OPERATION_LIST["Less Than Or Equal To"] = "<="

PROFESSION_LIST = {

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

local function pairsByKeys(t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
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
    editbox:SetScript("OnEnterPressed", function(self)
        local reminderText = BuildReminderText()

        debug("[editbox OnEnterPressed] reminderText = "..reminderText)

        if not reminderText or reminderText == "" then
            return
        end

        Reminders:AddReminder(reminderText)
        self:SetText("")
        self:ClearFocus()
    end)
    editbox:SetFontObject(GameFontHighlightSmall)
    editbox:SetWidth(500)
    editbox:SetHeight(25)
    editbox:EnableMouse(true)
    editbox:SetBackdrop(EDIT_BOX_BACKDROP)
    editbox:SetBackdropColor (0, 0, 0, 0.5)
    editbox:SetBackdropBorderColor (0.3, 0.3, 0.30, 0.80)

    MESSAGE_EDIT_BOX = editbox
end

function BuildReminderText()
    local reminderText = MESSAGE_EDIT_BOX:GetText() .. ","

    for _, conditionFrame in pairs(CONDITION_FRAMES) do

        local conditionText = UIDropDownMenu_GetText(conditionFrame.conditionDropDown)
        reminderText = reminderText .. CONDITION_LIST[conditionText]

        -- Apparently there's no "IsEnabled()" on UIDropDownMenus so we'll just check
        -- for the condition(s) that doesn't use an operation
        if conditionText ~= "Everyone" then
            local operationText = UIDropDownMenu_GetText(conditionFrame.operationDropDown)
            reminderText = reminderText .. " " .. OPERATION_LIST[operationText]
        end

        if conditionFrame.valueEditBox:IsEnabled() then
            reminderText = reminderText .. " " .. conditionFrame.valueEditBox:GetText()
        end
    end

    return reminderText
end

local function ConditionDropDownOnClick(self, arg1, arg2, checked)
    local conditionDropDown = self.owner

    UIDropDownMenu_EnableDropDown(conditionDropDown.operationDropDown)
    conditionDropDown.valueEditBox:Enable()

    if self:GetText() == "Everyone" then
        UIDropDownMenu_DisableDropDown(conditionDropDown.operationDropDown)
        conditionDropDown.valueEditBox:Disable()
    end
    UIDropDownMenu_SetText(conditionDropDown, self:GetText())
end

local function OperationDropDownOnClick(self, arg1, arg2, checked)
    UIDropDownMenu_SetText(self.owner, self:GetText())
end

local function PopulateConditionList(self, level)
    for k, v in pairsByKeys(CONDITION_LIST, SortAlphabetically) do
        local info = UIDropDownMenu_CreateInfo()
        info.owner = self
        info.arg1 = v
        info.text = k
        info.func = ConditionDropDownOnClick

        UIDropDownMenu_AddButton(info)
    end
end

local function PopulateOperationList(self, level, menuList)
    for k, v in pairsByKeys(OPERATION_LIST, SortAlphabetically) do
        local info = UIDropDownMenu_CreateInfo()
        info.owner = self
        info.arg1 = v
        info.text = k
        info.func = OperationDropDownOnClick

        UIDropDownMenu_AddButton(info)
    end
end

function Reminders:CreateConditionFrame(parentFrame)
    debug("[CreateConditionFrame] here")

    local i = 1
    -- Name should include an id and we should put these into a reusable pool
    local conditionFrame = CreateFrame("Frame", "ConditionFrame", parentFrame)
    conditionFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, -100)
    conditionFrame:SetSize(1000, 100)

    local conditionDropDown = CreateFrame("Frame", "ConditionDropDown", conditionFrame, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(conditionDropDown, 90)
    UIDropDownMenu_SetText(conditionDropDown, "Condition")
    UIDropDownMenu_Initialize(conditionDropDown, PopulateConditionList)
    conditionDropDown:SetPoint("TOPLEFT", conditionFrame, "TOPLEFT", 0, 0)

    local operationDropDown = CreateFrame("Frame", "OperationDropDown", conditionFrame, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(operationDropDown, 160)
    UIDropDownMenu_SetText(operationDropDown, "Operation")
    UIDropDownMenu_Initialize(operationDropDown, PopulateOperationList)
    operationDropDown:SetPoint("TOPLEFT", conditionFrame, "TOPLEFT", 175, 0)

    local valueEditBox = CreateFrame("EditBox", "valueEditBox", conditionFrame)
    valueEditBox:SetPoint("TOPLEFT", conditionFrame, 450, 0)
    valueEditBox:SetFontObject(GameFontHighlightSmall)
    valueEditBox:SetWidth(100)
    valueEditBox:SetHeight(25)
    valueEditBox:EnableMouse(true)
    valueEditBox:SetBackdrop(EDIT_BOX_BACKDROP)
    valueEditBox:SetBackdropColor (0, 0, 0, 0.5)
    valueEditBox:SetBackdropBorderColor (0.3, 0.3, 0.30, 0.80)
    valueEditBox:SetScript("OnEnterPressed", function(self)
        local reminderText = BuildReminderText()

        debug("[valueEditBox OnEnterPressed] reminderText = "..reminderText)
        if not reminderText or reminderText == "" then
            return
        end

        Reminders:AddReminder(reminderText)
        self:SetText("")
        self:ClearFocus()
    end)

    conditionFrame.conditionDropDown = conditionDropDown
    conditionFrame.operationDropDown = operationDropDown
    conditionFrame.valueEditBox      = valueEditBox

    -- So I can reference these in ConditionDropDownOnClick
    -- Not sure if these's a better way to access them without making them global
    conditionDropDown.operationDropDown = operationDropDown
    conditionDropDown.valueEditBox = valueEditBox

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

