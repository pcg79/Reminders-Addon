-- Globals
REMINDER_ITEMS = {}

CONDITION_LIST = {
    { text = "Everyone",   condition = "*" },
    { text = "Name",       condition = "name" },
    { text = "Level",      condition = "level" },
    { text = "iLevel",     condition = "ilevel" },
    { text = "Profession", condition = "profession" },
}
OPERATION_LIST = {
    { text = "Equals",                   operation = "=" },
    -- { text = "Not Equals",               operation = "~=" },
    { text = "Greater Than",             operation = ">" },
    { text = "Greater Than Or Equal To", operation = ">=" },
    { text = "Less Than",                operation = "<" },
    { text = "Less Than Or Equal To",    operation = "<=" },
}
PROFESSION_LIST = {

}
EDIT_BOX_BACKDROP = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    tile = true, edgeSize = 1, tileSize = 5,
}

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
        -- local reminderText = self:GetText()
        -- reminderText = reminderText:trim()

        -- if not reminderText or reminderText == "" then
        --     return
        -- end

        -- Reminders:AddReminder(reminderText)
        -- self:SetText("")
        -- self:ClearFocus()
    end)
    editbox:SetFontObject(GameFontHighlightSmall)
    editbox:SetWidth(500)
    editbox:SetHeight(25)
    editbox:EnableMouse(true)
    editbox:SetBackdrop(EDIT_BOX_BACKDROP)
    editbox:SetBackdropColor (0, 0, 0, 0.5)
    editbox:SetBackdropBorderColor (0.3, 0.3, 0.30, 0.80)
end

local function ConditionDropDownOnClick(self, arg1, arg2, checked)
    local conditionDropDown = self.owner
    UIDropDownMenu_EnableDropDown(conditionDropDown.operationDropDown)

    if self:GetText() == "Everyone" then
        UIDropDownMenu_DisableDropDown(conditionDropDown.operationDropDown)
    end
    UIDropDownMenu_SetText(conditionDropDown, self:GetText())
end

local function OperationDropDownOnClick(self, arg1, arg2, checked)
    UIDropDownMenu_SetText(self.owner, self:GetText())
end

local function PopulateConditionList(self, level)
    for i=1, #CONDITION_LIST do
        local info = UIDropDownMenu_CreateInfo()
        info.owner = self
        info.arg1 = i
        info.text = CONDITION_LIST[i].text
        info.func = ConditionDropDownOnClick

        UIDropDownMenu_AddButton(info)
    end
end

local function PopulateOperationList(self, level, menuList)
    for i=1, #OPERATION_LIST do
        local info = UIDropDownMenu_CreateInfo()
        info.owner = self
        info.arg1 = i
        info.text = OPERATION_LIST[i].text
        info.func = OperationDropDownOnClick

        UIDropDownMenu_AddButton(info)
    end
end

function Reminders:CreateConditionFrame(parentFrame)
    debug("[CreateConditionFrame] here")
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

    conditionDropDown.operationDropDown = operationDropDown

    local valueEditBox = CreateFrame("EditBox", "valueEditBox", conditionFrame)
    valueEditBox:SetPoint("TOPLEFT", conditionFrame, 450, 0)
    valueEditBox:SetFontObject(GameFontHighlightSmall)
    valueEditBox:SetWidth(100)
    valueEditBox:SetHeight(25)
    valueEditBox:EnableMouse(true)
    valueEditBox:SetBackdrop(EDIT_BOX_BACKDROP)
    valueEditBox:SetBackdropColor (0, 0, 0, 0.5)
    valueEditBox:SetBackdropBorderColor (0.3, 0.3, 0.30, 0.80)
    -- valueEditBox:SetScript("OnEnterPressed", function(self)
    --     local reminderText = self:GetText()
    --     reminderText = reminderText:trim()

    --     if not reminderText or reminderText == "" then
    --         return
    --     end

    --     Reminders:AddReminder(reminderText)
    --     self:SetText("")
    --     self:ClearFocus()
    -- end)


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

