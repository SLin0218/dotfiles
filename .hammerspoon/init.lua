---@diagnostic disable: undefined-global, lowercase-global
local obj = {}
obj.__index = obj

--------------------------------------------------------------------------------------------------------------------------
-- Metadata
--------------------------------------------------------------------------------------------------------------------------
obj.name = "Slin Hammerspoon"
obj.version = "0.0.1"
obj.author = "DengShiLin <slin_0218@163.com>"
obj.license = "MIT"
obj.homepage = ""
--------------------------------------------------------------------------------------------------------------------------

hs.hotkey.alertDuration = 0
hs.hints.showTitleThresh = 0
hs.window.animationDuration = 0

-- Use the standardized config location, if present
custom_config = hs.fs.pathToAbsolute(os.getenv("HOME") .. '/.config/hammerspoon/private/config.lua')
if custom_config then
    print("Loading custom config")
    dofile( os.getenv("HOME") .. "/.config/hammerspoon/private/config.lua")
    privatepath = hs.fs.pathToAbsolute(hs.configdir .. '/private/config.lua')
    if privatepath then
        hs.alert("You have config in both .config/hammerspoon and .hammerspoon/private.\nThe .config/hammerspoon one will be used.")
    end
else
    -- otherwise fallback to 'classic' location.
    if not privatepath then
        privatepath = hs.fs.pathToAbsolute(hs.configdir .. '/private')
        -- Create `~/.hammerspoon/private` directory if not exists.
        hs.fs.mkdir(hs.configdir .. '/private')
    end
    privateconf = hs.fs.pathToAbsolute(hs.configdir .. '/private/config.lua')
    if privateconf then
        -- Load awesomeconfig file if exists
        require('private/config')
    end
end

hsreload_keys = hsreload_keys or {{"cmd", "shift", "ctrl"}, "R"}
if string.len(hsreload_keys[2]) > 0 then
    hs.hotkey.bind(hsreload_keys[1], hsreload_keys[2], "Reload Configuration", function() hs.reload() end)
end

-- ModalMgr Spoon must be loaded explicitly, because this repository heavily relies upon it.
hs.loadSpoon("ModalMgr")

-- Define default Spoons which will be loaded later
if not hspoon_list then
    hspoon_list = {
        "SpeedMenu",
        "WinWin"
    }
end

-- Load those Spoons
for _, v in pairs(hspoon_list) do
    hs.loadSpoon(v)
end

----------------------------------------------------------------------------------------------------
-- Then we create/register all kinds of modal keybindings environments.
----------------------------------------------------------------------------------------------------
-- Register windowHints (Register a keybinding which is NOT modal environment with modal supervisor)
--hs.hints.style = 'vimperator'
-- 使用右手选择
hs.hints.hintChars = {'U', 'I', 'O', 'P', 'H', 'J', 'K', 'L', 'B', 'N', 'M'}
hs.hints.titleMaxSize = 20
hs.hints.showTitleThresh = 20
hswhints_keys = hswhints_keys or {"alt", "tab"}
if string.len(hswhints_keys[2]) > 0 then
    spoon.ModalMgr.supervisor:bind(hswhints_keys[1], hswhints_keys[2], 'Show Window Hints', function()
        spoon.ModalMgr:deactivateAll()
        hs.hints.windowHints()
    end)
end

----------------------------------------------------------------------------------------------------
-- Register Hammerspoon API manual: Open Hammerspoon manual in default browser
hsman_keys = hsman_keys or {"alt", "H"}
if string.len(hsman_keys[2]) > 0 then
    spoon.ModalMgr.supervisor:bind(hsman_keys[1], hsman_keys[2], "Read Hammerspoon Manual", function()
        hs.doc.hsdocs.forceExternalBrowser(true)
        hs.doc.hsdocs.browserDarkMode(0)
        hs.doc.hsdocs.moduleEntitiesInSidebar(true)
        hs.doc.hsdocs.help()
    end)
end

----------------------------------------------------------------------------------------------------
-- Register lock screen
hslock_keys = hslock_keys or {"alt", "L"}
if string.len(hslock_keys[2]) > 0 then
    spoon.ModalMgr.supervisor:bind(hslock_keys[1], hslock_keys[2], "Lock Screen", function()
        hs.caffeinate.lockScreen()
    end)
end

----------------------------------------------------------------------------------------------------
-- resizeM modal environment
if spoon.WinWin then
    spoon.ModalMgr:new("resizeM")
    local cmodal = spoon.ModalMgr.modal_list["resizeM"]
    cmodal:bind('', 'escape', 'Deactivate resizeM', function() spoon.ModalMgr:deactivate({"resizeM"}) end)
    cmodal:bind('', 'Q', 'Deactivate resizeM', function() spoon.ModalMgr:deactivate({"resizeM"}) end)
    cmodal:bind('', 'tab', 'Toggle Cheatsheet', function() spoon.ModalMgr:toggleCheatsheet() end)
    cmodal:bind('', 'A', 'Move Leftward', function() spoon.WinWin:stepMove("left") end, nil, function() spoon.WinWin:stepMove("left") end)
    cmodal:bind('', 'D', 'Move Rightward', function() spoon.WinWin:stepMove("right") end, nil, function() spoon.WinWin:stepMove("right") end)
    cmodal:bind('', 'W', 'Move Upward', function() spoon.WinWin:stepMove("up") end, nil, function() spoon.WinWin:stepMove("up") end)
    cmodal:bind('', 'S', 'Move Downward', function() spoon.WinWin:stepMove("down") end, nil, function() spoon.WinWin:stepMove("down") end)
    cmodal:bind('', 'H', 'Lefthalf of Screen', function() spoon.WinWin:moveAndResize("halfleft") end)
    cmodal:bind('', 'H', 'Lefthalf of Screen', function() spoon.WinWin:moveAndResize("halfleft") end)
    cmodal:bind('', 'L', 'Righthalf of Screen', function()spoon.WinWin:moveAndResize("halfright") end)
    cmodal:bind('', 'K', 'Uphalf of Screen', function() spoon.WinWin:moveAndResize("halfup") end)
    cmodal:bind('', 'J', 'Downhalf of Screen', function() spoon.WinWin:moveAndResize("halfdown") end)
    cmodal:bind('', 'Y', 'NorthWest Corner', function() spoon.WinWin:moveAndResize("cornerNW") end)
    cmodal:bind('', 'O', 'NorthEast Corner', function() spoon.WinWin:moveAndResize("cornerNE") end)
    cmodal:bind('', 'U', 'SouthWest Corner', function() spoon.WinWin:moveAndResize("cornerSW") end)
    cmodal:bind('', 'I', 'SouthEast Corner', function() spoon.WinWin:moveAndResize("cornerSE") end)
    --cmodal:bind('', 'F', 'Fullscreen', function() spoon.WinWin:moveAndResize("fullscreen") end)
    cmodal:bind('', 'F', 'Fullscreen', function() spoon.WinWin:moveAndResize("maximize") end)
    cmodal:bind('', 'C', 'Center Window', function() spoon.WinWin:moveAndResize("center") end)
    cmodal:bind('', '=', 'Stretch Outward', function() spoon.WinWin:moveAndResize("expand") end, nil, function() spoon.WinWin:moveAndResize("expand") end)
    cmodal:bind('', '-', 'Shrink Inward', function() spoon.WinWin:moveAndResize("shrink") end, nil, function() spoon.WinWin:moveAndResize("shrink") end)
    cmodal:bind('shift', 'H', 'Move Leftward', function() spoon.WinWin:stepResize("left") end, nil, function() spoon.WinWin:stepResize("left") end)
    cmodal:bind('shift', 'L', 'Move Rightward', function() spoon.WinWin:stepResize("right") end, nil, function() spoon.WinWin:stepResize("right") end)
    cmodal:bind('shift', 'K', 'Move Upward', function() spoon.WinWin:stepResize("up") end, nil, function() spoon.WinWin:stepResize("up") end)
    cmodal:bind('shift', 'J', 'Move Downward', function() spoon.WinWin:stepResize("down") end, nil, function() spoon.WinWin:stepResize("down") end)
    cmodal:bind('', 'left', 'Move to Left Monitor', function() spoon.WinWin:moveToScreen("left") end)
    cmodal:bind('', 'right', 'Move to Right Monitor', function() spoon.WinWin:moveToScreen("right") end)
    cmodal:bind('', 'up', 'Move to Above Monitor', function() spoon.WinWin:moveToScreen("up") end)
    cmodal:bind('', 'down', 'Move to Below Monitor', function() spoon.WinWin:moveToScreen("down") end)
    cmodal:bind('', 'space', 'Move to Next Monitor', function() spoon.WinWin:moveToScreen("next") end)
    cmodal:bind('', '[', 'Undo Window Manipulation', function() spoon.WinWin:undo() end)
    cmodal:bind('', ']', 'Redo Window Manipulation', function() spoon.WinWin:redo() end)
    --cmodal:bind('', '`', 'Center Cursor', function() spoon.WinWin:centerCursor() end)
    hs.hotkey.bind('alt', 'G', nil, function() spoon.WinWin:centerCursor() end)

    -- Register resizeM with modal supervisor
    hsresizeM_keys = hsresizeM_keys or {"alt", "R"}
    if string.len(hsresizeM_keys[2]) > 0 then
        spoon.ModalMgr.supervisor:bind(hsresizeM_keys[1], hsresizeM_keys[2], "Enter resizeM Environment", function()
            -- Deactivate some modal environments or not before activating a new one
            spoon.ModalMgr:deactivateAll()
            -- Show an status indicator so we know we're in some modal environment now
            spoon.ModalMgr:activate({"resizeM"}, "#FF0000")
        end)
    end
end

----------------------------------------------------------------------------------------------------
-- Register browser tab typist: Type URL of current tab of running browser in markdown format. i.e. [title](link)
hstype_keys = hstype_keys or {"alt", "V"}
if string.len(hstype_keys[2]) > 0 then
    spoon.ModalMgr.supervisor:bind(hstype_keys[1], hstype_keys[2], "Type Browser Link", function()
        local safari_running = hs.application.applicationsForBundleID("com.apple.Safari")
        local chrome_running = hs.application.applicationsForBundleID("com.google.Chrome")
        local brave_running = hs.application.applicationsForBundleID("com.brave.Browser")
        if #safari_running > 0 then
            local stat, data = hs.applescript('tell application "Safari" to get {URL, name} of current tab of window 1')
            if stat then hs.eventtap.keyStrokes("[" .. data[2] .. "](" .. data[1] .. ")") end
        elseif #chrome_running > 0 then
            local stat, data = hs.applescript('tell application "Google Chrome" to get {URL, title} of active tab of window 1')
            if stat then hs.eventtap.keyStrokes("[" .. data[2] .. "](" .. data[1] .. ")") end
        elseif #brave_running > 0 then
            local stat, data = hs.applescript('tell application "Brave Browser" to get {URL, title} of active tab of window 1')
            if stat then hs.eventtap.keyStrokes("[" .. data[2] .. "](" .. data[1] .. ")") end
        end
    end)
end

----------------------------------------------------------------------------------------------------
-- Register Hammerspoon console
hsconsole_keys = hsconsole_keys or {"alt", "Z"}
if string.len(hsconsole_keys[2]) > 0 then
    spoon.ModalMgr.supervisor:bind(hsconsole_keys[1], hsconsole_keys[2], "Toggle Hammerspoon Console", function() hs.toggleConsole() end)
end

----------------------------------------------------------------------------------------------------
-- Finally we initialize ModalMgr supervisor
spoon.ModalMgr.supervisor:enter()

----------------------------------------------------------------------------------------------------
-- switch current focus application
--local focus_window_title = ''
--local app_windows_switcher = nil
---- style
--hs.window.switcher.ui.textColor = {240,240,240}
--hs.window.switcher.ui.backgroundColor = {0,0,0,0.7}
--hs.window.switcher.ui.titleBackgroundColor = {0,0,0}
--hs.window.switcher.ui.fontName = 'Helvetica'
--hs.window.switcher.ui.textSize = 22
---- Don't show thumbnails, Improve loading speed
--hs.window.switcher.ui.showThumbnails = false
--hs.window.switcher.ui.showSelectedThumbnail = false

--hsswitch_focus_keys = hsswitch_focus_keys or {"cmd", "`"}
--hs.hotkey.bind(hsswitch_focus_keys[1], hsswitch_focus_keys[2], nil,
--function ()
  --local cur_focus_window_app_name = hs.window.frontmostWindow():application():name()
  ---- Get the switcher based on the app name
  --local focus_window_filter = hs.window.filter.new(cur_focus_window_app_name)
  ---- Ignore apps with less than 1 window
  --if (#(focus_window_filter:getWindows()) <= 1) then return end
  ---- Current focus app changes
  --if (cur_focus_window_app_name ~= focus_window_title)
  --then
    ---- Reset focus window title
    --focus_window_title = cur_focus_window_app_name
    ---- Reset current focus window switcher
    --app_windows_switcher = hs.window.switcher.new(focus_window_filter)
  --end
  ---- Switch to the next window
  --app_windows_switcher:next()
--end)
