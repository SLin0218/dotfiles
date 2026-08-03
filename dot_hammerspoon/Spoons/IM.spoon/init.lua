---@diagnostic disable: undefined-global
--- === IM Auto Switch ===

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "IM"
obj.version = "1.1.0"
obj.author = "DengShiLin <dengsl.dev@gmail.com>"

-- 1. 用于记录每个 App 选择的输入法，刚开始为空
obj.appInputSources = {}
obj.cjk = "im.rime.inputmethod.Squirrel.Hans"

-- 固定输入法的 App 规则（在 init() 中动态初始化，以避免 Hammerspoon 启动时系统输入法列表未加载完毕的问题）
obj.fixedApps = {}

-- 面板/代理类应用（这些应用在获得和失去焦点时不会触发系统的 applicationWatcher）
obj.panelApps = {
	["Raycast"] = true,
	["Alfred"] = true,
	["Spotlight"] = true,
	["Search"] = true,
}

-- 调试日志开关
obj.debug = false

-- 辅助函数：输出调试日志
local function logDebug(fmt, ...)
	if obj.debug then
		print(string.format("[IM] " .. fmt, ...))
	end
end

-- 统一的自动切换输入法逻辑
function obj:switchInputForApp(appName)
	if not appName then
		return
	end
	local targetInput = obj.fixedApps[appName] or obj.appInputSources[appName] or obj.defaultLayout
	local currentInput = hs.keycodes.currentSourceID()
	if currentInput ~= targetInput then
		logDebug("Auto Switch (%s): %s -> %s", "Focus/Activate", appName, targetInput)
		local success = hs.keycodes.currentSourceID(targetInput)
		if not success then
			print(string.format("[IM] Warning: Failed to switch input source to %s", targetInput))
		end
	end
end

-- 监听 App 激活事件（常规应用）
local function applicationWatcher(appName, eventType, _)
	if eventType == hs.application.watcher.activated then
		obj:switchInputForApp(appName)
	end
end

-- 监听输入法切换事件（订阅系统通知，比 hs.keycodes.inputSourceChanged 更稳定）
local function inputSourceCallback(_, _, _)
	-- 优先获取 frontmostApplication (避免调用慢速的 accessibility 接口)
	local frontApp = hs.application.frontmostApplication()
	local frontAppName = frontApp and frontApp:name()

	-- 如果是面板类特殊应用，或者无法获取 frontmostApp 名字，则降级获取 focusedWindow (较慢)
	local focusedApp = nil
	local focusedAppName = nil
	if not frontAppName or obj.panelApps[frontAppName] then
		local focusedWindow = hs.window.focusedWindow()
		focusedApp = focusedWindow and focusedWindow:application()
		focusedAppName = focusedApp and focusedApp:name()
	end

	logDebug("Debug Focus: focusedWindowApp=%s, frontmostApp=%s", focusedAppName or "nil", frontAppName or "nil")

	-- 优先通过当前获得键盘焦点的窗口来获取当前活动 App
	local activeApp = focusedApp or frontApp
	if activeApp then
		local appName = activeApp:name()
		if appName then
			-- 如果是 Raycast、Alfred 等特殊面板应用，我们不记录其输入法状态（避免污染前台应用记录）
			-- 而是开启一个临时的轻量级监听定时器，等它失焦后切回先前活动 App 的输入法
			if obj.panelApps[appName] then
				if not obj.panelFocusTimer then
					logDebug("Started temporary focus timer for panel app: %s", appName)
					obj.panelFocusTimer = hs.timer.doEvery(0.1, function()
						local fApp = hs.application.frontmostApplication()
						local currentAppName = fApp and fApp:name()

						if not currentAppName or obj.panelApps[currentAppName] then
							local w = hs.window.focusedWindow()
							local app = w and w:application()
							local name = app and app:name()
							if name then
								currentAppName = name
							end
						end

						-- 如果焦点已经不是这些面板应用了，说明面板已关闭或失焦
						if currentAppName and not obj.panelApps[currentAppName] then
							logDebug("Panel app lost focus. Restoring input source for active app: %s", currentAppName)
							obj:switchInputForApp(currentAppName)
							-- 停止并清理定时器
							if obj.panelFocusTimer then
								obj.panelFocusTimer:stop()
								obj.panelFocusTimer = nil
							end
						end
					end)
				end
			else
				-- 正常应用，如果不是固定输入法的 App，则记录其输入法变更
				if not obj.fixedApps[appName] then
					local currentInput = hs.keycodes.currentSourceID()
					-- 如果当前记录值与实际输入法不一致，更新并记录
					if obj.appInputSources[appName] ~= currentInput then
						obj.appInputSources[appName] = currentInput
						logDebug("Recorded: %s -> %s", appName, currentInput)
					end
				end
			end
		end
	end
end

function obj:init()
	-- 获取默认布局 (增加 nil 安全检查与 fallback)
	local layouts = hs.keycodes.layouts(true)
	obj.defaultLayout = (layouts and #layouts > 0) and layouts[1] or "com.apple.keylayout.ABC"

	-- 设置默认的固定输入法规则
	local defaultFixedApps = {
		["微信"] = obj.cjk,
		["WeChat"] = obj.cjk,
		["WeLink"] = obj.cjk,
		["Emacs"] = obj.defaultLayout,
		["IntelliJ IDEA"] = obj.defaultLayout,
	}

	-- 将默认规则合并到 obj.fixedApps 中（不覆盖用户已有的设置）
	obj.fixedApps = obj.fixedApps or {}
	for k, v in pairs(defaultFixedApps) do
		if obj.fixedApps[k] == nil then
			obj.fixedApps[k] = v
		end
	end

	-- 创建 App 监听器 (绑定在 obj 上以防止垃圾回收)
	obj.appWatcher = hs.application.watcher.new(applicationWatcher)

	-- 创建输入法变更监听器 (绑定在 obj 上以防止垃圾回收)
	obj.inputWatcher = hs.distributednotifications.new(
		inputSourceCallback,
		"com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged"
	)

	-- 自动启动
	obj:start()
end

function obj:start()
	if obj.appWatcher then
		obj.appWatcher:start()
	end
	if obj.inputWatcher then
		obj.inputWatcher:start()
	end
	return self
end

function obj:stop()
	if obj.appWatcher then
		obj.appWatcher:stop()
	end
	if obj.inputWatcher then
		obj.inputWatcher:stop()
	end
	if obj.panelFocusTimer then
		obj.panelFocusTimer:stop()
		obj.panelFocusTimer = nil
	end
	return self
end

return obj
