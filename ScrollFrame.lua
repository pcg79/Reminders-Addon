-- function Reminders:CreateScrollFrame()

--     -- create the frame that will hold all other frames/objects:
--     local frameHolder = CreateFrame("Frame", nil, UIParent); -- re-size this to whatever size you wish your ScrollFrame to be, at this point

--     -- now create the template Scroll Frame (this frame must be given a name so that it can be looked up via the _G function (you'll see why later on in the code)
--     frameHolder.scrollframe = frameHolder.scrollframe or CreateFrame("ScrollFrame", "ANewScrollFrame", frameHolder, "UIPanelScrollFrameTemplate");

--     -- create the standard frame which will eventually become the Scroll Frame's scrollchild
--     -- importantly, each Scroll Frame can have only ONE scrollchild
--     frameHolder.scrollchild = frameHolder.scrollchild or CreateFrame("Frame"); -- not sure what happens if you do, but to be safe, don't parent this yet (or do anything with it)

--     -- define the scrollframe's objects/elements:
--     local scrollbarName = frameHolder.scrollframe:GetName()
--     frameHolder.scrollbar = _G[scrollbarName.."ScrollBar"];
--     frameHolder.scrollupbutton = _G[scrollbarName.."ScrollBarScrollUpButton"];
--     frameHolder.scrolldownbutton = _G[scrollbarName.."ScrollBarScrollDownButton"];

--     -- all of these objects will need to be re-anchored (if not, they appear outside the frame and about 30 pixels too high)
--     frameHolder.scrollupbutton:ClearAllPoints();
--     frameHolder.scrollupbutton:SetPoint("TOPRIGHT", frameHolder.scrollframe, "TOPRIGHT", -2, -2);

--     frameHolder.scrolldownbutton:ClearAllPoints();
--     frameHolder.scrolldownbutton:SetPoint("BOTTOMRIGHT", frameHolder.scrollframe, "BOTTOMRIGHT", -2, 2);

--     frameHolder.scrollbar:ClearAllPoints();
--     frameHolder.scrollbar:SetPoint("TOP", frameHolder.scrollupbutton, "BOTTOM", 0, -2);
--     frameHolder.scrollbar:SetPoint("BOTTOM", frameHolder.scrolldownbutton, "TOP", 0, 2);

--     -- now officially set the scrollchild as your Scroll Frame's scrollchild (this also parents frameHolder.scrollchild to frameHolder.scrollframe)
--     -- IT IS IMPORTANT TO ENSURE THAT YOU SET THE SCROLLCHILD'S SIZE AFTER REGISTERING IT AS A SCROLLCHILD:
--     frameHolder.scrollframe:SetScrollChild(frameHolder.scrollchild);

--     -- set frameHolder.scrollframe points to the first frame that you created (in this case, frameHolder)
--     frameHolder.scrollframe:SetAllPoints(frameHolder);

--     -- now that SetScrollChild has been defined, you are safe to define your scrollchild's size. Would make sense to make it's height > scrollframe's height,
--     -- otherwise there's no point having a scrollframe!
--     -- note: you may need to define your scrollchild's height later on by calculating the combined height of the content that the scrollchild's child holds.
--     -- (see the bit below about showing content).
--     frameHolder.scrollchild:SetSize(frameHolder.scrollframe:GetWidth(), ( frameHolder.scrollframe:GetHeight() * 2 ));


--     -- THE SCROLLFRAME IS COMPLETE AT THIS POINT.  THE CODE BELOW DEMONSTRATES HOW TO SHOW DATA ON IT.


--     -- you need yet another frame which will be used to parent your widgets etc to.  This is the frame which will actually be seen within the Scroll Frame
--     -- It is parented to the scrollchild.  I like to think of scrollchild as a sort of 'pin-board' that you can 'pin' a piece of paper to (or take it back off)
--     frameHolder.moduleoptions = frameHolder.moduleoptions or CreateFrame("Frame", nil, frameHolder.scrollchild);
--     frameHolder.moduleoptions:SetAllPoints(frameHolder.scrollchild);

--     -- a good way to immediately demonstrate the new scrollframe in action is to do the following...

--     -- create a fontstring or a texture or something like that, then place it at the bottom of the frame that holds your info (in this case frameHolder.moduleoptions)
--     frameHolder.moduleoptions.fontstring = frameHolder.moduleoptions:CreateFontString("ScrollFrameFontString", "OVERLAY", "GameFontNormal")
--     frameHolder.moduleoptions.fontstring:SetText("This is a test.");
--     frameHolder.moduleoptions.fontstring:SetPoint("BOTTOMLEFT", frameHolder.moduleoptions, "BOTTOMLEFT", 20, 60);

--     -- you should now need to scroll down to see the text "This is a test."

--     frameHolder:Show()
--     return frameHolder
-- end


-- Try 2
function Reminders:CreateScrollFrame(mainFrame)
    local scrollWidth = 1000
    local scrollHeight = 300

    local scrollFrame = CreateFrame("ScrollFrame", "scrollFrame", mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("BOTTOMLEFT", 0, 10)
    scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMLEFT", scrollWidth - 30, 10)

    -- Not sure what this is even setting.  Changing it doesn't seem to do anything
    -- but the scrollbar won't show up w/o it.
    scrollFrame:SetSize(scrollWidth, scrollHeight)

    local scrollChild = CreateFrame("Frame", "scrollChild", scrollFrame)
    scrollChild:SetSize(scrollWidth, scrollHeight)
    scrollChild:SetPoint("TOPLEFT", 0, 0)

    scrollFrame:SetScrollChild(scrollChild)

    mainFrame.scrollList = scrollChild

    for i = 0, 100 do
        local childFrame = _G.CreateFrame("Button", "elementFrame"..i, scrollChild, "UIPanelButtonTemplate")
        childFrame:SetSize(scrollWidth - 60, 50)
        childFrame:SetPoint("TOP", 0, -(50 * (i - 1)))
        childFrame:SetText("text - "..i)
    end
end

-- -- Try 3
-- function Reminders:CreateScrollFrame3()
--     local scrollframe = CreateFrame("ScrollFrame", nil, UIParent)
--     scrollframe:SetWidth(128)
--     scrollframe:SetHeight(420)
--     scrollframe:SetPoint("CENTER")

--     local content = CreateFrame("Frame", nil, scrollframe)
--     content:SetPoint("TOPLEFT")
--     content:SetPoint("TOPRIGHT")
--     content:SetHeight(1280)
--     content:SetWidth(128)
--     scrollframe:SetScrollChild(content)


--     scrollFrame.scrollbar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
--     scrollFrame.scrollbar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -1, -16)
--     scrollFrame.scrollbar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -1, 15)
--     scrollFrame.scrollbar:SetValueStep(SCROLL_STEP_VALUE)
--     scrollFrame.scrollbar.scrollStep = SCROLL_STEP_VALUE
--     scrollFrame.scrollbar:SetValue(1)
--     scrollFrame.scrollbar:SetWidth(SLIDERUI_WIDTH)
--     scrollFrame:SetClipsChildren(true)


--     for i = 0, 10 do
--       local button = CreateFrame("BUTTON", nil, content, "UIPanelButtonTemplate")
--       button:SetHeight(128)
--       button:SetWidth(128)

--       -- local texture = button:CreateTexture(nil, "OVERLAY")
--       -- texture:SetAllPoints()
--       -- texture:SetTexture("Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-46")

--       button:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -i*128)
--       button:SetText("test - "..i)

--       button:SetScript("OnEnter", function() print("hover") end)
--       button:SetScript("OnClick", function() print("CLICKED") end)

--       -- local closeButton = CreateFrame("Button", frameName.."Close", reminderAction, "UIPanelButtonTemplate")
--       -- closeButton:SetScript("OnClick", function(self) gui:Hide() end)
--       -- closeButton:SetPoint("BOTTOMRIGHT", -27, 17)
--       -- closeButton:SetHeight(20)
--       -- closeButton:SetWidth(100)
--       -- closeButton:SetText("Close")
--     end
-- end

-- -- Try 4
-- function Reminders:CreateScrollFrame4()
--     --frame
--     local frame = CreateFrame("Frame", "rTestFrame", UIParent)
--     frame:SetPoint("CENTER")
--     frame:SetSize(32,32)

--     --scrollFrame
--     local scrollFrame = CreateFrame("ScrollFrame", "$parentScrollFrame", frame, "UIPanelScrollFrameTemplate")
--     scrollFrame:SetPoint("CENTER")
--     scrollFrame:SetSize(300,300)

--     --scrollChild
--     local scrollChild = CreateFrame("Frame",nil,scrollFrame)
--     scrollChild:SetSize(300,1500)

--     --scrollFrame:SetScrollChild
--     scrollFrame:SetScrollChild(scrollChild)

--     --add test objects to scrollchild

--     --text
--     local text = scrollChild:CreateFontString(nil, "BACKGROUND")
--     text:SetFont(STANDARD_TEXT_FONT, 32, "OUTLINE")
--     text:SetPoint("TOPLEFT")
--     text:SetText("Hello World!")

--     --murloc model
--     local m = CreateFrame("PlayerModel",nil,scrollChild)
--     m:SetSize(200,200)
--     m:SetPoint("TOPLEFT",text,"BOTTOMLEFT",0,-10)
--     m:SetCamDistanceScale(0.8)
--     m:SetRotation(-0.4)
--     m:SetDisplayInfo(21723) --murcloc costume

--     --dwarf artifact model
--     local m2 = CreateFrame("PlayerModel",nil,scrollChild)
--     m2:SetSize(200,200)
--     m2:SetPoint("TOPLEFT",m,"BOTTOMLEFT",0,-10)
--     m2:SetCamDistanceScale(0.5)
--     m2:SetDisplayInfo(38699)

--     --change the scrollframe position
--     scrollFrame:SetVerticalScroll(150)
-- end
