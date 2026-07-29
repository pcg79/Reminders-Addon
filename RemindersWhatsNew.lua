-- What's New window (#55)
--
-- Shows the changelog in-game: the full history in a scrollable window, newest
-- version first. It auto-opens once after the addon updates (see
-- MaybeShowWhatsNewOnLogin) and can be reopened any time from the "What's New"
-- button on the main Reminders window.
--
-- The changelog data lives in RemindersChangelog.lua, which is generated from
-- CHANGELOG.md (the WoW client can't read files at runtime, so we ship the
-- notes as an embedded Lua table).

local AceGUI = LibStub("AceGUI-3.0")

-- AceGUI labels default to a small font; bump the changelog body up a bit for
-- readability. We reuse the standard highlight font's path so it still respects
-- the client's locale font.
local FONT_PATH = GameFontHighlight:GetFont()
local ENTRY_FONT_SIZE = 14
local HEADER_FONT_SIZE = 16

-- Only one window at a time; reopening while it's up just focuses the existing one.
local whatsNewFrame

-- Toggle the window: open it if closed, close it if open. The main window's
-- "What's New" button uses this; the login auto-open uses ShowWhatsNew directly.
function Reminders:ToggleWhatsNew()
    if whatsNewFrame then
        AceGUI:Release(whatsNewFrame)
        whatsNewFrame = nil
        return
    end
    Reminders:ShowWhatsNew()
end

-- Builds and shows the scrollable changelog window.
function Reminders:ShowWhatsNew()
    if whatsNewFrame then
        whatsNewFrame:Show()
        return
    end

    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Reminders \226\128\148 What's New")
    frame:SetStatusText("Reminders v" .. (Reminders.version or "?"))
    frame:SetLayout("Fill")
    frame:SetWidth(560)
    frame:SetHeight(520)
    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        whatsNewFrame = nil
    end)
    whatsNewFrame = frame

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")
    frame:AddChild(scroll)

    local changelog = Reminders.changelog or {}
    if #changelog == 0 then
        local empty = AceGUI:Create("Label")
        empty:SetFullWidth(true)
        empty:SetText("No changelog is available.")
        scroll:AddChild(empty)
        return
    end

    for _, release in ipairs(changelog) do
        local heading = AceGUI:Create("Heading")
        heading:SetFullWidth(true)
        -- Bump the version header a bit above the body; the divider lines anchor
        -- to the label's edges, so they resize with it. Set before SetText.
        heading.label:SetFont(FONT_PATH, HEADER_FONT_SIZE, "")
        heading:SetText("v" .. release.version .. "   (" .. release.date .. ")")
        scroll:AddChild(heading)

        for _, entry in ipairs(release.entries or {}) do
            local bullet = AceGUI:Create("Label")
            bullet:SetFullWidth(true)
            bullet:SetFont(FONT_PATH, ENTRY_FONT_SIZE, "") -- set before SetText so height is measured with the new size
            bullet:SetText("\226\128\162 " .. entry) -- "• " + entry
            scroll:AddChild(bullet)
        end

        -- A little breathing room between versions.
        local spacer = AceGUI:Create("Label")
        spacer:SetFullWidth(true)
        spacer:SetText(" ")
        scroll:AddChild(spacer)
    end
end

-- Called on every login/reload. Auto-opens the window the first time the player
-- logs in after the addon version changes. Skips the very first run (fresh
-- install, or existing users upgrading to this feature) so we don't greet new
-- users with a changelog for software they've never run -- we just record the
-- current version so the popup fires on the *next* update.
function Reminders:MaybeShowWhatsNewOnLogin()
    local current = Reminders.version
    if not current then return end

    local seen = RemindersDB.global.lastSeenVersion

    if seen == nil then
        RemindersDB.global.lastSeenVersion = current
        return
    end

    if seen ~= current then
        RemindersDB.global.lastSeenVersion = current
        Reminders:ShowWhatsNew()
    end
end
