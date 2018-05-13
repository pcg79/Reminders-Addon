Reminders = LibStub("AceAddon-3.0"):NewAddon("Reminders", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
RemindersConsole = LibStub("AceConsole-3.0")
Reminders:RegisterChatCommand("reminders", "CommandProcessor")

local function chatMessage(message)
    RemindersConsole:Print(message)
end

local function debug(message)
  --if addon.db.profile.debug then
  if true then
     chatMessage("Reminder debug: "..message)
  end
end

debug("We're in")

function Reminders:CommandProcessor(input)
    debug(input)
    if input == "" or input == "open" or input == "show" then
        gui:Show()
    elseif input == "reset" then
        debug("resetting")
        Reminders:ResetAll()
    else
        OutputLog("Usage:")
    end
end

function Reminders:ResetAll()
    self.db:ResetDB()
end


function Reminders:OnInitialize()
    debug("OnInit")

    self.db = LibStub("AceDB-3.0"):New("RemindersDB", dbDefaults(), true)
    self.db:RegisterDefaults(dbDefaults())

    AceGUI = LibStub("AceGUI-3.0")

    self.frameShown = false

    Reminders:PrintReminders()

    -- evaluateReminders(self.db.global.reminders)

    if not gui then Reminders:CreateUI() end
    gui:Show()
end


function Reminders:OnEvent()
    debug('Reminder Loaded')
end

function Reminders:CloseFrame(widget, event)
    debug("closing")
    AceGUI:Release(widget)
    self.frameShown = false
end

function Reminders:SaveReminder(widget, event, text)
    debug("saving - "..text)
    table.insert(self.db.global.reminders, text)
end

function Reminders:PrintReminders()
    reminders = self.db.global.reminders
    for _, reminder in pairs(reminders) do
        chatMessage(reminder)
    end
end

function Reminders:CreateUI()
    debug("creating UI")

    local frameName = "RemindersFrame"
    local FrameBackdrop = {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 24, bottom = 8 }
    }

    gui = CreateFrame("Frame", frameName, UIParent)
    gui:Hide()

    gui:SetPoint("CENTER")
    gui:EnableMouse(true)
    -- gui:SetMovable(true)
    -- gui:SetClampedToScreen(true)
    gui:SetSize(800, 600)
    -- gui:SetBackdrop(FrameBackdrop)

    gui:SetScript("OnShow", function(self) debug("it should be showing 2") end)
    -- tinsert(UISpecialFrames, frameName)

    local titlebg = gui:CreateTexture(nil, "BORDER")
    titlebg:SetTexture(251966) --"Interface\\PaperDollInfoFrame\\UI-GearManager-Title-Background"
    titlebg:SetPoint("TOPLEFT", 9, -6)
    titlebg:SetPoint("BOTTOMRIGHT", gui, "TOPRIGHT", 0, -24)


    local reminderList = CreateFrame("Frame", frameName.."List", gui)
    reminderList:SetPoint("LEFT", gui)
    reminderList:SetSize(210, 600)
    reminderList:SetBackdrop(FrameBackdrop)


    local reminderAction = CreateFrame("Frame", frameName.."Action", gui)
    reminderAction:SetPoint("RIGHT", gui)
    reminderAction:SetSize(600, 600)
    reminderAction:SetBackdrop(FrameBackdrop)


    local closeButton = CreateFrame("Button", frameName.."Close", gui, "UIPanelButtonTemplate")
    closeButton:SetScript("OnClick", function(self)
        gui:Hide()
    end)
    closeButton:SetPoint("BOTTOMRIGHT", -27, 17)
    closeButton:SetHeight(20)
    closeButton:SetWidth(100)
    closeButton:SetText("Close")


    -- gui:SetPoint("CENTER",0,0)

    -- gui = CreateFrame("Frame", frameName, UIParent)
    -- gui:SetFrameStrata("LOW")
    -- gui:SetSize(200, 200)
    -- gui:SetWidth(208)
    -- gui:SetHeight(60)
    -- gui:SetAllPoints(UIParent)


    -- local t = gui:CreateTexture(nil, "BACKGROUND")
    -- t:SetTexture("Interface/Worldmap/Gear_64Grey")
    -- t:SetAllPoints(gui)
    -- gui.texture = t

    -- gui:SetPoint("CENTER",0,0)

    -- lbRealm = setupWidget(gui:CreateFontString(nil,"BACKGROUND", "GameFontNormal"), {SetWidth=200,SetHeight=18}, 0, 6)
    -- lbStatus = setupWidget(gui:CreateFontString(nil,"BACKGROUND", "GameFontHighlightSmallLeft"), {SetWidth=200,SetHeight=10}, 6, 23)

    -- btQuick = setupWidget(CreateFrame("Button",nil,gui,"UIMenuButtonStretchTemplate"),{SetWidth=90,SetHeight=20,SetText="Quick join"},4,36)
    -- btQuick:RegisterForClicks("RightButtonUp","LeftButtonUp")
    -- btQuick:SetScript("OnClick",addon.DoAutoAction)
    -- setupTooltip(btQuick, "ANCHOR_BOTTOM", addon.actionTooltip)
    -- btManual = setupWidget(CreateFrame("Button",nil,gui,"UIMenuButtonStretchTemplate"),{SetWidth=90,SetHeight=20,SetText="Manual join"},94,36)
    -- btManual:SetScript("OnClick",addon.ShowManualLfg)
    -- setupWidget(CreateFrame("Button",nil,gui,"UIPanelCloseButton"),{EnableMouse=true,SetWidth=20,SetHeight=20},188,0)

    -- btRefresh = setupWidget(CreateFrame("Button",nil,gui,"UIPanelSquareButton"),{SetWidth=20,SetHeight=20},184,16)
    -- btRefresh.icon:SetTexture("Interface/BUTTONS/UI-RefreshButton")
    -- btRefresh.icon:SetTexCoord(0,1,0,1);
    -- btRefresh:SetScript("OnClick",addon.RefreshZone)

    -- btSettings = setupWidget(CreateFrame("Button",nil,gui,"UIPanelSquareButton"),{SetWidth=20,SetHeight=20},184,36)
    -- btSettings.icon:SetTexture("Interface/Worldmap/Gear_64Grey")
    -- btSettings.icon:SetTexCoord(0.1,0.9,0.1,0.9);
    -- btSettings:SetScript("OnClick",addon.ShowSettings)

    -- local savedPos = db.global.widgetPos
    -- gui:SetPoint(savedPos.to,savedPos.x,savedPos.y)
    -- addon:UpdateAutoButtonStatus()

    -- local languages = C_LFGList.GetAvailableLanguageSearchFilter()
    -- for i=1,#languages do
    --     allLanguageTable[languages[i]] = true;
    -- end

end

function Reminders:CloseOnClick(frame)
    debug("In on click")
    gui:Hide()
end

function Reminders:CreateAceUI()
    debug("frameShown = "..tostring(self.frameShown))
    if self.frameShown == true then
        return
    end

    -- Create a container frame
    local f = AceGUI:Create("Frame")
    f:SetCallback("OnClose", function(widget, event) Reminders:CloseFrame(widget, event) end)
    f:SetTitle("Reminders")
    f:SetStatusText("Status Bar")
    f:SetLayout("Flow")

    local editbox = AceGUI:Create("EditBox")
    editbox:SetLabel("Insert text:")
    editbox:SetWidth(1000)
    editbox:SetCallback("OnEnterPressed", function(widget, event, text) Reminders:SaveReminder(widget, event, text) end)

    f:AddChild(editbox)

    local button = AceGUI:Create("Button")
    button:SetText("Click Me!")
    button:SetWidth(200)
    button:SetCallback("OnClick", function() Reminders:PrintReminders() end)
    f:AddChild(button)

    self.frameShown = true
end

function dbDefaults()
    return  {
      global = {
        reminders = {},
      }
    }
end
