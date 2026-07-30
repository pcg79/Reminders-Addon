-- RemindersPopup
-- This is based on the work Marouan Sabbagh did on MSA-Tutorials (which is based on the work
-- João Cardoso did on CustomTutorials)

--- MSA-Tutorials-1.0
--- Tutorials from Marouan Sabbagh based on CustomTutorials from João Cardoso.

--[[
Copyright 2010-2015 João Cardoso
CustomTutorials is distributed under the terms of the GNU General Public License (or the Lesser GPL).

CustomTutorials is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

CustomTutorials is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with CustomTutorials. If not, see <http://www.gnu.org/licenses/>.
--]]

--[[
General Arguments
-----------------
 width .......... Default is 350. Internal frame width (without borders).
 font ........... Default is game font (empty string).
 fontHeight ..... Default is 12.

Frame Arguments
---------------
 title .......... Title relative to frame (replace General value).
 width .......... Width relative to frame (replace General value).
Note: All other arguments can be used as a general!
 text ........... Text string.
 textX .......... Default is 25. Left and Right margin.
 textY .......... Default is 20 (top margin).
 button ......... [optional] Button text string (directing value). Button is out of content flow.
 buttonClick .... Function with button's click action.

 point .......... Default is "CENTER".
 anchor ......... Default is "UIParent".
 relPoint ....... Default is "CENTER".
 x, y ........... Default is 0, 0.
--]]

local ReminderFrames = {}
local NumReminderFrames = 0
local NumReminders = 0
local reminderFrameHeight = 30

-- Reminder popup layout (#62): the popup sizes its width to the widest message
-- (instead of a fixed-width banner), and each row shows a Snooze button plus a
-- small X for dismiss.
local ROW_INSET = 20          -- row x offset inside the popup (matches LayoutReminderFrames)
local ROW_RIGHT_PAD = 14
local TEXT_ACTIONS_GAP = 20   -- space between the message and the actions
local TEXT_SLACK = 18         -- breathing room past the measured text so the widest line never wraps
local SNOOZE_WIDTH = 74
local DISMISS_WIDTH = 74
local BUTTON_HEIGHT = 22
local ACTIONS_GAP = 8         -- space between the Snooze and Dismiss buttons
local MIN_POPUP_WIDTH = 300
local MAX_POPUP_WIDTH = 560

local default = {
  title = "Reminder!",
  width = 350,
  font = "",
  fontHeight = 12,
  baseMasterFrameHeight = 60,

  textX = 25,
  textY = 20,
  point = "CENTER",
  anchor = UIParent,
  relPoint = "CENTER",
  x = 0,
  y = 0,
}

--[[ Internal API ]]--

-- Since GetLeft and GetTop are measured from the BOTTOMLEFT of the screen we'll set the relPoint
-- to BOTTOMLEFT in order to make the positioning easier
local function StopMovingAndRecordPosition(frame)
  frame:StopMovingOrSizing()
  -- Persist per-character so the popup reopens where you last left it. (#23)
  RemindersDB.char.popupPosition = {
    x = frame:GetLeft(),
    y = frame:GetTop(),
    point = "TOPLEFT",
    relPoint = "BOTTOMLEFT",
  }
end

-- Position the visible rows top-to-bottom using each row's own height (rows are
-- sized to fit their text, so long reminders don't overflow), shrink the popup
-- to fit, and close it if none remain. Handles both the dismiss-reflow (#44)
-- and variable-height rows (#20).
local function LayoutReminderFrames(masterFrame)
  local y = 40
  local shownCount = 0
  for _, reminderFrame in ipairs(masterFrame.reminderFrames) do
    if reminderFrame:IsShown() then
      shownCount = shownCount + 1
      reminderFrame:ClearAllPoints()
      reminderFrame:SetPoint("TOPLEFT", masterFrame, 20, -y)
      y = y + (reminderFrame.rowHeight or reminderFrameHeight)
    end
  end

  -- Header shows the current count, updating as reminders are dismissed. (#62)
  if masterFrame.Title then
    masterFrame.Title:SetText(shownCount == 1 and "1 Reminder" or (shownCount .. " Reminders"))
  end

  if y == 40 then
    masterFrame:Hide()
  else
    local baseMasterFrameHeight = (masterFrame.data and masterFrame.data.baseMasterFrameHeight) or default.baseMasterFrameHeight
    masterFrame:SetHeight(baseMasterFrameHeight + (y - 40))
  end
end

-- Ensure a row's widgets exist and carry the current message + handlers. Sizing
-- and positioning happen in LayoutReminderRow once the popup width is known. (#62)
local function BuildReminderRow(parentFrame, reminder, i)
  local frame = parentFrame.reminderFrames[i]
  if not frame then
    frame = CreateFrame("Frame", "$parentChildFrame" .. i, parentFrame)
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.snoozeButton = CreateFrame("Button", "$parentSnoozeButton" .. i, frame, "UIPanelButtonTemplate")
    -- Dismiss stays a labeled button: there's no unambiguous icon for it (the
    -- circle-slash reads as "no", a close-X collides with the frame's corner X). (#62)
    frame.dismissButton = CreateFrame("Button", "$parentDismissButton" .. i, frame, "UIPanelButtonTemplate")

    tinsert(parentFrame.reminderFrames, frame)
  end

  local snoozeButton = reminder.snoozeButton
  frame.snoozeButton:SetText(snoozeButton.text)
  frame.snoozeButton:SetScript("OnClick", snoozeButton.onClick)
  frame.snoozeButton:Enable()

  -- Run the original dismiss behavior (chat message + hide this row), then reflow
  -- so remaining rows close the gap and the popup shrinks/closes.
  local dismissButton = reminder.dismissButton
  frame.dismissButton:SetText(dismissButton.text)
  local originalOnDismiss = dismissButton.onClick
  frame.dismissButton:SetScript("OnClick", function(self, mouseButton, down)
    if originalOnDismiss then
      originalOnDismiss(self, mouseButton, down)
    end
    LayoutReminderFrames(parentFrame)
  end)
  frame.dismissButton:Enable()

  frame.text:SetJustifyH("LEFT")
  frame.text:SetWordWrap(true)
  -- Accent a leading "(Name)" cross-character prefix so the target stands out.
  frame.text:SetText((reminder.text:gsub("^(%b())", "|cffffd100%1|r")))

  return frame
end

-- Position a row's widgets and size its height for the popup's current width. (#62)
local function LayoutReminderRow(parentFrame, i)
  local frame = parentFrame.reminderFrames[i]
  frame:SetWidth(parentFrame:GetWidth() - (ROW_INSET + ROW_RIGHT_PAD))

  frame.dismissButton:ClearAllPoints()
  frame.dismissButton:SetSize(DISMISS_WIDTH, BUTTON_HEIGHT)
  frame.dismissButton:SetPoint("RIGHT", frame, "RIGHT", 0, 0)

  frame.snoozeButton:ClearAllPoints()
  frame.snoozeButton:SetSize(SNOOZE_WIDTH, BUTTON_HEIGHT)
  frame.snoozeButton:SetPoint("RIGHT", frame.dismissButton, "LEFT", -ACTIONS_GAP, 0)

  frame.text:ClearAllPoints()
  frame.text:SetPoint("LEFT", frame, "LEFT", 0, 0)
  frame.text:SetPoint("RIGHT", frame.snoozeButton, "LEFT", -TEXT_ACTIONS_GAP, 0)

  -- Size the row to fit its (possibly wrapped) text. (#20)
  local textHeight = frame.text:GetStringHeight() or 0
  frame.rowHeight = math.max(reminderFrameHeight, math.ceil(textHeight) + 6)
  frame:SetHeight(frame.rowHeight)

  frame:Show()
end

local function CreateIndividualReminderFrames(frame)
  local reminders = frame.data.reminders

  for i, reminderFrame in pairs(frame.reminderFrames) do
    reminderFrame:Hide()
  end

  -- First pass: build each row and measure the widest (unwrapped) message.
  local maxTextWidth = 0
  for i, reminder in pairs(reminders) do
    local row = BuildReminderRow(frame, reminder, i)
    row.text:ClearAllPoints()
    row.text:SetWidth(0) -- unbounded, so GetStringWidth is the natural width
    maxTextWidth = math.max(maxTextWidth, math.ceil(row.text:GetStringWidth() or 0))
  end

  -- Size the popup to its content (clamped) instead of a fixed-width banner.
  -- TEXT_SLACK gives the widest message a little room so it never wraps.
  local actionsWidth = SNOOZE_WIDTH + ACTIONS_GAP + DISMISS_WIDTH
  local desiredWidth = ROW_INSET + maxTextWidth + TEXT_SLACK + TEXT_ACTIONS_GAP + actionsWidth + ROW_RIGHT_PAD
  frame:SetWidth(math.max(MIN_POPUP_WIDTH, math.min(MAX_POPUP_WIDTH, desiredWidth)))

  -- Second pass: lay out each row at the final width, then reflow + size height.
  for i in pairs(reminders) do
    LayoutReminderRow(frame, i)
  end

  LayoutReminderFrames(frame)
end

local function NewMasterFrame(data)
  if not data.textY then
    data.textY = 0
  end

  for k, v in pairs(default) do
    if not data[k] then
      data[k] = v
    end
  end

  local frameName = "RemindersPopup"..(NumReminderFrames + 1)
  local frame = CreateFrame("Frame", frameName, UIParent, "UIPanelDialogTemplate")
  -- Learned how to do this from http://www.wowinterface.com/forums/showthread.php?p=329257#post329257
  _G[frameName.."TitleBG"]:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-AchievementBackground")
  _G[frameName.."DialogBG"]:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-AchievementBackground")

  local pos = RemindersDB.char.popupPosition
  frame:ClearAllPoints()
  frame:SetPoint((pos and pos.point) or data.point, data.anchor, (pos and pos.relPoint) or data.relPoint, (pos and pos.x) or data.x, (pos and pos.y) or data.y)
  frame:SetWidth(data.width + 16)
  frame:SetHeight(data.baseMasterFrameHeight + (NumReminders * reminderFrameHeight))
  frame.Title:SetText(data.title)

  frame:SetFrameStrata('DIALOG')
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)
  frame:SetToplevel(true)
  frame:SetMovable(true)
  frame:SetScript("OnMouseDown", function() frame:StartMoving() end)
  frame:SetScript("OnMouseUp", function() StopMovingAndRecordPosition(frame) end)
  frame:Hide()

  frame.reminderFrames = {}
  return frame
end


--[[ User API ]]--

local ReminderPopupFrames = {}

function Reminders:DisplayInlinePopup(data)
  local count = 0
  for _ in pairs(data.reminders) do count = count + 1 end

  NumReminders = count

  -- Only ever show a single popup: reuse the one frame (even if it's currently
  -- visible) and hide any extras, so a new set of reminders replaces the current
  -- popup instead of stacking a new one on top of it. (#4)
  local frame = ReminderPopupFrames[1]
  for i = 2, #ReminderPopupFrames do
    ReminderPopupFrames[i]:Hide()
  end

  if not frame then
    frame = NewMasterFrame(data)
    NumReminderFrames = NumReminderFrames + 1
    tinsert(ReminderPopupFrames, frame)
  end

  -- Set the current data (replacing whatever the popup was showing)
  frame.data = data

  -- CreateIndividualReminderFrames lays out the rows and sizes the popup to fit.
  CreateIndividualReminderFrames(frame)
  frame:Show()
end
