-- GLOBALS

SCROLLWIDTH = 1000
SCROLLHEIGHT = 300


function Reminders:CreateScrollFrame(parentFrame)
    local scrollFrame = CreateFrame("ScrollFrame", "scrollFrame", parentFrame, "UIPanelScrollFrameTemplate")
    -- Stretch the list from just under the condition row down to above the
    -- Close button so it fills the window instead of floating near the bottom.
    scrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", -10, -162)
    scrollFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMLEFT", SCROLLWIDTH - 30, 45)

    -- Not sure what this is even setting.  Changing it doesn't seem to do anything
    -- but the scrollbar won't show up w/o it.
    scrollFrame:SetSize(SCROLLWIDTH, SCROLLHEIGHT)

    scrollFrame:SetToplevel(true)

    local scrollChild = CreateFrame("Frame", "scrollChild", scrollFrame)
    scrollChild:SetSize(SCROLLWIDTH, SCROLLHEIGHT)
    scrollChild:SetPoint("TOPLEFT", 0, 0)

    scrollFrame:SetScrollChild(scrollChild)

    -- Clip content to the viewport so overflow rows don't cover the Close button.
    -- SetClipsChildren would also hide the template's scrollbar (it's anchored at
    -- the frame's right edge), so pull the scrollbar just inside the frame's rect
    -- first, keeping it visible under the clip.
    local scrollBar = scrollFrame.ScrollBar or _G[(scrollFrame:GetName() or "") .. "ScrollBar"]
    if scrollBar then
        scrollBar:ClearAllPoints()
        scrollBar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -1, -18)
        scrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -1, 18)
        scrollFrame:SetClipsChildren(true)
    end

    parentFrame.scrollFrame = scrollFrame
    parentFrame.scrollList = scrollChild
end
