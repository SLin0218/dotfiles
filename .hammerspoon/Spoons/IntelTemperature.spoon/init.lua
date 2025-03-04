-- Must be installedIntel Power Gadget.dmg

local obj = {}

obj.__index = obj

-- Metadata
obj.name = "IntelTemperature"
obj.version = "1.0"
obj.author = "DengShiLin <DengShiLin0218@gmail.com>"
obj.homepage = "https://github.com/slin_0218/Hammerspoon-config"
obj.license = "MIT - https://opensource.org/licenses/MIT"

function obj:init()
    self.menubar = hs.menubar.new(false)
end

function obj:start()
    obj.menubar:returnToMenuBar()
    obj:rescan()
end

function obj:stop()
    obj.menubar:removeFromMenuBar()
    obj.timer:stop()
end

function obj:toggle()
    if obj.timer:running()
    then
        obj:stop()
    else
        obj:start()
    end
end

-- 获取当前脚本路径
local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end

local function getCpuTemperature()
  local intel = hs.execute(script_path() .. '/PowerGadgetAPI')
  local title = hs.styledtext.new(intel, {font={size=13.0}})
  obj.menubar:setTitle(title)
end

function obj:rescan()
  if obj.timer
  then
      obj.timer:stop()
      obj.timer = nil
  end

  obj.timer = hs.timer.doEvery(2, getCpuTemperature)
  obj.timer:fire()
end

return obj
