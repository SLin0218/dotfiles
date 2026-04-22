---@diagnostic disable: undefined-global
local obj = {}
obj.__index = obj

function obj:init() end

local function current_selection()
	local elem = hs.uielement.focusedElement()
	local sel = nil
	if elem then
		sel = elem:selectedText()
	end
	if (not sel) or (sel == "") then
		hs.eventtap.keyStroke({ "cmd" }, "c")
		hs.timer.usleep(100000)
		sel = hs.pasteboard.getContents()
	else
		print("sel:" .. sel)
	end
	return (sel or "")
end

MY_CANVAS = nil
MY_CANVAS_CLOSE_KEY = nil

local function closeCanva()
	-- 关闭并销毁画布
	if MY_CANVAS ~= nil then
		MY_CANVAS:delete()
		MY_CANVAS = nil
	end
	if MY_CANVAS_CLOSE_KEY ~= nil then
		-- 注销 Esc 键监听，避免影响后续正常的 Esc 使用
		MY_CANVAS_CLOSE_KEY:delete()
		MY_CANVAS_CLOSE_KEY = nil
	end
end

local function translate(text)
	closeCanva()

	-- 2. 获取当前鼠标位置
	local mousePos = hs.mouse.absolutePosition()
	local padding = 25
	local canvasW = 600
	local canvasH = 500

	-- 3. 创建 Canvas 窗口
	MY_CANVAS = hs.canvas.new({
		x = mousePos.x,
		y = mousePos.y,
		w = canvasW,
		h = canvasH,
	})

	-- 背景矩形
	MY_CANVAS[1] = {
		type = "rectangle",
		action = "fill",
		fillColor = { hex = "#11111b" },
		roundedRectRadii = { xRadius = 7, yRadius = 7 },
	}

	-- 文字内容
	MY_CANVAS[2] = {
		type = "text",
		text = text,
		textSize = 16,
		lineBreak = "wordWrap",
		textColor = { hex = "#cdd6f4" },
		textAlignment = "left",
		frame = { x = padding, y = padding, w = "95%", h = "95%" },
	}

	-- 让窗口始终在最前并显示
	MY_CANVAS:level(hs.canvas.windowLevels.overlay)
	MY_CANVAS:show()
	MY_CANVAS_CLOSE_KEY = hs.hotkey.bind({}, "escape", closeCanva)
end

hs.hotkey.bind("alt", "e", nil, function()
	local text = current_selection()
	text = string.gsub(text, '"', '\\"')
	text = string.gsub(text, "\n", "\\n")
	translate(text)
end)

return obj
