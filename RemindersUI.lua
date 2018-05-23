function Reminders:CreateUI()
    local frameName = "RemindersFrame"
    local EditBoxBackdrop = {
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        tile = true, edgeSize = 1, tileSize = 5,
    }

    gui = CreateFrame("Frame", frameName, UIParent, "UIPanelDialogTemplate")
    gui:Hide()

    gui:SetSize(1000, 600)
    gui:SetPoint("CENTER")
    gui:EnableMouse(true)
    gui.Title:SetText("Reminders")

    local editbox = CreateFrame("EditBox", frameName.."EditBox", gui)
    -- editbox:SetLabel("Insert text:")
    editbox:SetPoint("TOPLEFT", gui, 50, -50)
    editbox:SetScript("OnEnterPressed", function(self)
        local reminderText = self:GetText()
        reminderText = reminderText:trim()

        if not reminderText or reminderText == "" then
            return
        end

        Reminders:SaveNewReminder(reminderText)
        self:SetText("")
        self:ClearFocus()
    end)
    editbox:SetFontObject(GameFontHighlightSmall)
    editbox:SetWidth(500)
    editbox:SetHeight(25)
    editbox:EnableMouse(true)
    editbox:SetBackdrop(EditBoxBackdrop)
    editbox:SetBackdropColor (0, 0, 0, 0.5)
    editbox:SetBackdropBorderColor (0.3, 0.3, 0.30, 0.80)

    Reminders:CreateScrollFrame(gui)

    local closeButton = CreateFrame("Button", frameName.."Close", gui, "UIPanelButtonTemplate")
    closeButton:SetScript("OnClick", function(self) gui:Hide() end)
    closeButton:SetPoint("BOTTOMRIGHT", -27, 17)
    closeButton:SetHeight(20)
    closeButton:SetWidth(100)
    closeButton:SetText("Close")
end

reminderItems = {}

function Reminders:LoadReminders()
    offset = 0

    for i, reminder in pairs(RemindersDB.global.reminders) do
        local reminder = Reminders:CreateReminder(reminder)
        local reminderItem = reminderItems[i] or _G.CreateFrame("Button", "reminderItemFrame"..i, gui.scrollList, "UIPanelButtonTemplate")
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
                Reminders:LoadReminders()
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
        reminderItems[i] = reminderItem
    end

    local remindersCount = #RemindersDB.global.reminders
    local reminderButtonsCount = #reminderItems
    if  remindersCount < reminderButtonsCount then
        for i=remindersCount+1, reminderButtonsCount do
            reminderItems[i]:Hide()
        end
    end
end

function Reminders:OnEvent()
    debug('Reminder Loaded')
end

function Reminders:CloseFrame(widget, event)
    debug("closing")
    AceGUI:Release(widget)
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

