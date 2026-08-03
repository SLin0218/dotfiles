---@diagnostic disable: undefined-global
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

-- Define default Spoons which will be loaded later
local hspoon_list = {
	-- ModalMgr Spoon must be loaded explicitly, because this repository heavily relies upon it.
	"ModalMgr",
	"WinWin",
	"IM",
}

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
hs.hints.hintChars = { "U", "I", "O", "P", "H", "J", "K", "L", "B", "N", "M" }
hs.hints.titleMaxSize = 20
hs.hints.showTitleThresh = 20
local hswhints_keys = hswhints_keys or { "alt", "tab" }
if string.len(hswhints_keys[2]) > 0 then
	spoon.ModalMgr.supervisor:bind(hswhints_keys[1], hswhints_keys[2], "Show Window Hints", function()
		spoon.ModalMgr:deactivateAll()
		hs.hints.windowHints()
	end)
end

----------------------------------------------------------------------------------------------------
-- Register lock screen
local hslock_keys = hslock_keys or { "alt", "L" }
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
	cmodal:bind("", "escape", "Deactivate resizeM", function()
		spoon.ModalMgr:deactivate({ "resizeM" })
	end)
	cmodal:bind("", "Q", "Deactivate resizeM", function()
		spoon.ModalMgr:deactivate({ "resizeM" })
	end)
	cmodal:bind("", "tab", "Toggle Cheatsheet", function()
		spoon.ModalMgr:toggleCheatsheet()
	end)
	cmodal:bind(
		"",
		"A",
		"Move Leftward",
		function()
			spoon.WinWin:stepMove("left")
		end,
		nil,
		function()
			spoon.WinWin:stepMove("left")
		end
	)
	cmodal:bind(
		"",
		"D",
		"Move Rightward",
		function()
			spoon.WinWin:stepMove("right")
		end,
		nil,
		function()
			spoon.WinWin:stepMove("right")
		end
	)
	cmodal:bind(
		"",
		"W",
		"Move Upward",
		function()
			spoon.WinWin:stepMove("up")
		end,
		nil,
		function()
			spoon.WinWin:stepMove("up")
		end
	)
	cmodal:bind(
		"",
		"S",
		"Move Downward",
		function()
			spoon.WinWin:stepMove("down")
		end,
		nil,
		function()
			spoon.WinWin:stepMove("down")
		end
	)
	cmodal:bind("", "H", "Lefthalf of Screen", function()
		spoon.WinWin:moveAndResize("halfleft")
	end)
	cmodal:bind("", "H", "Lefthalf of Screen", function()
		spoon.WinWin:moveAndResize("halfleft")
	end)
	cmodal:bind("", "L", "Righthalf of Screen", function()
		spoon.WinWin:moveAndResize("halfright")
	end)
	cmodal:bind("", "K", "Uphalf of Screen", function()
		spoon.WinWin:moveAndResize("halfup")
	end)
	cmodal:bind("", "J", "Downhalf of Screen", function()
		spoon.WinWin:moveAndResize("halfdown")
	end)
	cmodal:bind("", "Y", "NorthWest Corner", function()
		spoon.WinWin:moveAndResize("cornerNW")
	end)
	cmodal:bind("", "O", "NorthEast Corner", function()
		spoon.WinWin:moveAndResize("cornerNE")
	end)
	cmodal:bind("", "U", "SouthWest Corner", function()
		spoon.WinWin:moveAndResize("cornerSW")
	end)
	cmodal:bind("", "I", "SouthEast Corner", function()
		spoon.WinWin:moveAndResize("cornerSE")
	end)
	--cmodal:bind('', 'F', 'Fullscreen', function() spoon.WinWin:moveAndResize("fullscreen") end)
	cmodal:bind("", "F", "Fullscreen", function()
		spoon.WinWin:moveAndResize("maximize")
	end)
	cmodal:bind("", "C", "Center Window", function()
		spoon.WinWin:moveAndResize("center")
	end)
	cmodal:bind(
		"",
		"=",
		"Stretch Outward",
		function()
			spoon.WinWin:moveAndResize("expand")
		end,
		nil,
		function()
			spoon.WinWin:moveAndResize("expand")
		end
	)
	cmodal:bind(
		"",
		"-",
		"Shrink Inward",
		function()
			spoon.WinWin:moveAndResize("shrink")
		end,
		nil,
		function()
			spoon.WinWin:moveAndResize("shrink")
		end
	)
	cmodal:bind(
		"shift",
		"H",
		"Move Leftward",
		function()
			spoon.WinWin:stepResize("left")
		end,
		nil,
		function()
			spoon.WinWin:stepResize("left")
		end
	)
	cmodal:bind(
		"shift",
		"L",
		"Move Rightward",
		function()
			spoon.WinWin:stepResize("right")
		end,
		nil,
		function()
			spoon.WinWin:stepResize("right")
		end
	)
	cmodal:bind(
		"shift",
		"K",
		"Move Upward",
		function()
			spoon.WinWin:stepResize("up")
		end,
		nil,
		function()
			spoon.WinWin:stepResize("up")
		end
	)
	cmodal:bind(
		"shift",
		"J",
		"Move Downward",
		function()
			spoon.WinWin:stepResize("down")
		end,
		nil,
		function()
			spoon.WinWin:stepResize("down")
		end
	)
	cmodal:bind("", "left", "Move to Left Monitor", function()
		spoon.WinWin:moveToScreen("left")
	end)
	cmodal:bind("", "right", "Move to Right Monitor", function()
		spoon.WinWin:moveToScreen("right")
	end)
	cmodal:bind("", "up", "Move to Above Monitor", function()
		spoon.WinWin:moveToScreen("up")
	end)
	cmodal:bind("", "down", "Move to Below Monitor", function()
		spoon.WinWin:moveToScreen("down")
	end)
	cmodal:bind("", "space", "Move to Next Monitor", function()
		spoon.WinWin:moveToScreen("next")
	end)
	cmodal:bind("", "[", "Undo Window Manipulation", function()
		spoon.WinWin:undo()
	end)
	cmodal:bind("", "]", "Redo Window Manipulation", function()
		spoon.WinWin:redo()
	end)
	--cmodal:bind('', '`', 'Center Cursor', function() spoon.WinWin:centerCursor() end)
	hs.hotkey.bind("alt", "G", nil, function()
		spoon.WinWin:centerCursor()
	end)

	-- Register resizeM with modal supervisor
	local hsresizeM_keys = hsresizeM_keys or { "alt", "R" }
	if string.len(hsresizeM_keys[2]) > 0 then
		spoon.ModalMgr.supervisor:bind(hsresizeM_keys[1], hsresizeM_keys[2], "Enter resizeM Environment", function()
			-- Deactivate some modal environments or not before activating a new one
			spoon.ModalMgr:deactivateAll()
			-- Show an status indicator so we know we're in some modal environment now
			spoon.ModalMgr:activate({ "resizeM" }, "#FF0000")
		end)
	end
end

----------------------------------------------------------------------------------------------------
-- Register Hammerspoon console
local hsconsole_keys = hsconsole_keys or { "alt", "Z" }
if string.len(hsconsole_keys[2]) > 0 then
	spoon.ModalMgr.supervisor:bind(hsconsole_keys[1], hsconsole_keys[2], "Toggle Hammerspoon Console", function()
		hs.toggleConsole()
	end)
end

----------------------------------------------------------------------------------------------------
-- Finally we initialize ModalMgr supervisor
spoon.ModalMgr.supervisor:enter()

----------------------------------------------------------------------------------------------------
