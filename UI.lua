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

        Reminders:SaveReminder(reminderText)
        self:SetText("")
        self:ClearFocus()
        -- MainPanel.list_frame:Update(nil, false)
    end)
    editbox:SetFontObject(GameFontHighlightSmall)
    editbox:SetWidth(500)
    editbox:SetHeight(25)
    editbox:EnableMouse(true)
    editbox:SetBackdrop(EditBoxBackdrop)
    editbox:SetBackdropColor (0, 0, 0, 0.5)
    editbox:SetBackdropBorderColor (0.3, 0.3, 0.30, 0.80)


    Reminders:CreateScrollFrame(gui)
end

function Reminders:CloseOnClick(frame)
    debug("In on click")
    gui:Hide()
end

function Reminders:LoadReminders()
    offset = 0
    for i, reminder in pairs(self.db.global.reminders) do
        local reminderItem = _G.CreateFrame("Button", "elementFrame"..i, gui.scrollList, "UIPanelButtonTemplate")
        reminderItem:SetSize(SCROLLWIDTH - 60, 50)
        reminderItem:SetPoint("TOP", 0, -(50 * (i - 1)))
        reminderItem.text = reminderItem:CreateFontString("Text", "ARTWORK", "NumberFontNormalSmall")
        reminderItem.text:SetSize(SCROLLWIDTH - 60, 50)
        reminderItem.text:SetJustifyH("LEFT")
        reminderItem.text:SetPoint("TOPLEFT", 10, 0)
        reminderItem.text:SetText(reminder.message .. " -> " .. reminder.condition)
    end
end

function Reminders:RefreshReminderList()
  -- Not sure what to do here.  If I recreate all the buttons will they just appear over the existing ones?
  -- Do I have to somehow "erase" the existing ones?
end


function Reminders:OnEvent()
    debug('Reminder Loaded')
end

function Reminders:CloseFrame(widget, event)
    debug("closing")
    AceGUI:Release(widget)
    self.frameShown = false
end
