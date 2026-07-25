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

local movedPosition = {
  x = nil,
  y = nil,
  point = nil,
  relPoint = nil,
}

--[[ Internal API ]]--

-- Since GetLeft and GetTop are measured from the BOTTOMLEFT of the screen we'll set the relPoint
-- to BOTTOMLEFT in order to make the positioning easier
local function StopMovingAndRecordPosition(frame)
  frame:StopMovingOrSizing()
  movedPosition = {
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
  for _, reminderFrame in ipairs(masterFrame.reminderFrames) do
    if reminderFrame:IsShown() then
      reminderFrame:ClearAllPoints()
      reminderFrame:SetPoint("TOPLEFT", masterFrame, 20, -y)
      y = y + (reminderFrame.rowHeight or reminderFrameHeight)
    end
  end

  if y == 40 then
    masterFrame:Hide()
  else
    local baseMasterFrameHeight = (masterFrame.data and masterFrame.data.baseMasterFrameHeight) or default.baseMasterFrameHeight
    masterFrame:SetHeight(baseMasterFrameHeight + (y - 40))
  end
end

local function NewFrame(parentFrame, reminder, i)
  if not reminder.textY then
    reminder.textY = 0
  end

  for k, v in pairs(default) do
    if not reminder[k] then
      reminder[k] = v
    end
  end

  local frame = nil
  if parentFrame.reminderFrames[i] then
    frame = parentFrame.reminderFrames[i]
  else
    frame = CreateFrame("Frame", "$parentChildFrame" .. i, parentFrame)
    frame.text = frame:CreateFontString(nil, nil, "GameFontHighlight")
    frame.snoozeButton = CreateFrame("Button", "$parentSnoozeButton" .. i, frame, "UIPanelButtonTemplate")
    frame.dismissButton = CreateFrame("Button", "$parentDismissButton" .. i, frame, "UIPanelButtonTemplate")

    tinsert(parentFrame.reminderFrames, frame)
  end

  -- Frame width is set now; its height is sized to the text below and its
  -- position is assigned by LayoutReminderFrames.
  frame:SetWidth(parentFrame:GetWidth() - 30)

  local snoozeButton = reminder.snoozeButton
  frame.snoozeButton:ClearAllPoints()
  frame.snoozeButton:SetSize(80, 22)
  frame.snoozeButton:SetPoint("TOPRIGHT", frame, -90, 0)
  frame.snoozeButton:SetText(snoozeButton.text)
  frame.snoozeButton:SetScript("OnClick", snoozeButton.onClick)
  frame.snoozeButton:Enable()

  local dismissButton = reminder.dismissButton
  frame.dismissButton:ClearAllPoints()
  frame.dismissButton:SetSize(80, 22)
  frame.dismissButton:SetPoint("TOPRIGHT", frame, 0, 0)
  frame.dismissButton:SetText(dismissButton.text)
  -- Run the original dismiss behavior (chat message + hide this row), then
  -- reflow so the remaining rows close the gap and the popup shrinks/closes.
  local originalOnDismiss = dismissButton.onClick
  frame.dismissButton:SetScript("OnClick", function(self, mouseButton, down)
    if originalOnDismiss then
      originalOnDismiss(self, mouseButton, down)
    end
    LayoutReminderFrames(parentFrame)
  end)
  frame.dismissButton:Enable()

  frame.text:ClearAllPoints()
  frame.text:SetJustifyH("LEFT")
  frame.text:SetPoint("TOPLEFT", frame, 0, 0)
  frame.text:SetWidth(frame:GetWidth() - frame.snoozeButton:GetWidth() - frame.dismissButton:GetWidth())
  frame.text:SetWordWrap(true)
  frame.text:SetText(reminder.text)

  -- Size the row to fit its (possibly wrapped) text so long reminders don't
  -- overflow into the next one. GetStringHeight measures the rendered height,
  -- which also accounts for the player's font size. (#20)
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

  for i, reminder in pairs(reminders) do
    NewFrame(frame, reminder, i)
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

  frame:ClearAllPoints()
  frame:SetPoint((movedPosition.point or data.point), data.anchor, (movedPosition.relPoint or data.relPoint), (movedPosition.x or data.x), (movedPosition.y or data.y))
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
