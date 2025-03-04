
local obj = {}

obj.__index = obj

-- Metadata
obj.name = "Watcher"
obj.version = "1.0"
obj.author = "DengShiLin <DengShiLin0218@gmail.com>"
obj.homepage = "https://github.com/Slin_0218/Hammerspoon-config"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.city = 'GuangZhou'
obj.lang = 'zh'
obj.rescan_interval = 10

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

local url = 'https://wttr.in/' .. obj.city .. '?lang=' .. obj.lang .. '&format=%25C%25c%25t&m'

local function get_data()
  hs.http.asyncGet(url, nil, function(code, response, err)
    -- 错误重试
    if code ~= 200
    then
      obj.menubar:setTitle('获取天气中（重试中）...')
      print('获取天气失败 response = ' .. response)
      hs.timer.doAfter(4, function() obj.timer:fire() end)
      return
    end
    local title = hs.styledtext.new(response, {font = {size = 13.0}})
    obj.menubar:setTitle(title)
  end)
end

function obj:rescan()
  if obj.timer
  then
      obj.timer:stop()
      obj.timer = nil
  end
  obj.menubar:setTitle('获取天气中...')
  obj.timer = hs.timer.doEvery(obj.rescan_interval * 60, get_data)
  obj.timer:fire()
end

return obj
