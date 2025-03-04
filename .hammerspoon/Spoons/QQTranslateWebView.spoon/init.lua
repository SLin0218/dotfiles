---@diagnostic disable: undefined-global
local obj={}
obj.__index = obj
obj.webview = nil

obj.popup_size = hs.geometry.size(900, 700)

obj.popup_style = hs.webview.windowMasks.utility|hs.webview.windowMasks.HUD|hs.webview.windowMasks.titled|hs.webview.windowMasks.closable
-- 获取当前脚本路径
local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end

function obj:init()
  local file = io.open(script_path() .. '/inject.js', 'r')
  self.js = file:read('*a')
  io.close(file)
end

local function current_selection()
   local elem=hs.uielement.focusedElement()
   local sel=nil
   if elem then
      sel=elem:selectedText()
   end
   if (not sel) or (sel == "") then
      hs.eventtap.keyStroke({"cmd"}, "c")
      hs.timer.usleep(100000)
      sel=hs.pasteboard.getContents()
   else
      print("sel:" .. sel)
   end
   return (sel or "")
end

local function translate(text)
  if obj.webview == nil then
    local rect = hs.geometry.rect(0, 0, obj.popup_size.w, obj.popup_size.h)
    rect.center = hs.screen.mainScreen():frame().center
    local usercontent = hs.webview.usercontent.new('initScript')
    usercontent:injectScript({
      source=obj.js .. "window.inputValue(\"" .. text .. "\");",
      injectionTime="documentEnd"
    })
    obj.webview = hs.webview.new(rect, {}, usercontent) :allowTextEntry(true)
       :windowStyle(obj.popup_style)
       :closeOnEscape(true)
       :size({w=obj.popup_size.w, h=obj.popup_size.h})
    obj.webview:url("https://fanyi.qq.com")
        :bringToFront()
        :show()
  else
    obj.webview:evaluateJavaScript("window.inputValue(\"" .. text .. "\");")
  end
  obj.webview:bringToFront():show()
  obj.webview:hswindow():focus()
end

hs.hotkey.bind('alt', 'i', nil, function()
  local text = current_selection()
  text = string.gsub(text, "\"", "\\\"")
  text = string.gsub(text, "\n", "\\n")
  print(text)
  translate(text)
end)

return obj

