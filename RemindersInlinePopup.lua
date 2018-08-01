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
 textHeight ..... Default is 0 (auto height).
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

  textHeight = 0,
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
    local masterFrameName = parentFrame:GetName()
    frame = CreateFrame("Frame", masterFrameName .. "ChildFrame" .. i, parentFrame)
    frame.text = frame:CreateFontString(nil, nil, "GameFontHighlight")
    frame.button = CreateFrame("Button", masterFrameName .. "Button" .. i, frame, "UIPanelButtonTemplate")

    tinsert(parentFrame.reminderFrames, frame)
  end

  -- Frame
  frame:ClearAllPoints()
  frame:SetPoint("TOPLEFT", parentFrame, 0, -(60 + ((i-1) * reminderFrameHeight)))
  frame:SetWidth(parentFrame:GetWidth() - 10)
  frame:SetHeight(reminderFrameHeight)
  frame:SetFrameStrata('DIALOG')

  frame.text:ClearAllPoints()
  frame.text:SetJustifyH('LEFT')
  frame.text:SetPoint('TOPLEFT', frame, 40, 0)
  frame.text:SetWidth(reminder.width)
  frame.text:SetText(reminder.text)

  frame.button:ClearAllPoints()
  frame.button:SetSize(100, 22)
  frame.button:SetPoint("TOPRIGHT", frame, 0, 0)
  frame.button:SetText(reminder.button)
  frame.button:SetScript('OnClick', reminder.buttonClick)
  frame.button:Enable()

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

  local frame = CreateFrame("Frame", "RemindersPopup"..(NumReminderFrames + 1), UIParent, "UIPanelDialogTemplate")
  frame:SetBackdrop({
    bgFile = "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-AchievementBackground",
    insets = {left = 4, right = 4, top = 4, bottom = 4},
  })
  frame:ClearAllPoints()
  frame:SetPoint((movedPosition.point or data.point), data.anchor, (movedPosition.relPoint or data.relPoint), (movedPosition.x or data.x), (movedPosition.y or data.y))
  frame:SetWidth(data.width + 16)
  frame:SetHeight(80 + (NumReminders * reminderFrameHeight))
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
  local frame = nil
  local count = 0
  for _ in pairs(data.reminders) do count = count + 1 end

  NumReminders = count

  -- Attempt to reuse any created but unused frames
  for _, reminderFrame in pairs(ReminderPopupFrames) do
    if not reminderFrame:IsVisible() and not frame then
      frame = reminderFrame
      frame:SetHeight(80 + (NumReminders * reminderFrameHeight))
    end
  end

  -- No unused frames available so make a new one
  if not frame then
    frame = NewMasterFrame(data)
    NumReminderFrames = NumReminderFrames + 1
    tinsert(ReminderPopupFrames, frame)
  end

  -- Whether it's new or reusing, set the current data
  frame.data = data

  CreateIndividualReminderFrames(frame)
  frame:Show()
end
