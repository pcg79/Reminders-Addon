-- GLOBALS

SCROLLWIDTH = 1000
SCROLLHEIGHT = 300


function Reminders:CreateScrollFrame(mainFrame)
    local scrollFrame = CreateFrame("ScrollFrame", "scrollFrame", mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("BOTTOMLEFT", -10, 50)
    scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMLEFT", SCROLLWIDTH - 30, 10)

    -- Not sure what this is even setting.  Changing it doesn't seem to do anything
    -- but the scrollbar won't show up w/o it.
    scrollFrame:SetSize(SCROLLWIDTH, SCROLLHEIGHT)

    local scrollChild = CreateFrame("Frame", "scrollChild", scrollFrame)
    scrollChild:SetSize(SCROLLWIDTH, SCROLLHEIGHT)
    scrollChild:SetPoint("TOPLEFT", 0, 0)

    scrollFrame:SetScrollChild(scrollChild)

    mainFrame.scrollList = scrollChild
end
