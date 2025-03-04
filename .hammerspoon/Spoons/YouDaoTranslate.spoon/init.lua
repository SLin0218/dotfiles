---@diagnostic disable: undefined-global
local obj={}
obj.__index = obj

-- Metadata
obj.name = "YouDaoTranslate"
obj.version = "1.0"
obj.author = "DengShiLin <slin_0218@163.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.secret = "FQVc4qyp1A5zJtnySzY74qxoQZXNHWkA"
obj.salt = "96C9FDA4-534E-4FBF-8A33-210E4DA2CCA4"
obj.signType = "v3"
obj.appKey = "6f5dfad8958633ba"
obj.apiUrl = "https://openapi.youdao.com/api"
obj.log = hs.logger.new('YouDaoTranslate', 4)

function obj:init()
    self.translationCanvas = nil
end


-- get JCK char ascii 0 start length
local function getAsciiLenth(str, length)
  local index = 1
  local sign = length < 0
  if sign then
    index = #str
  end
  while true do
    ::CONTINUE::
    local curByteNum = string.byte(str,index)
    if curByteNum >= 0 and curByteNum <= 127 then
      index = sign and index - 1 or index + 1
    elseif curByteNum >= 194 and curByteNum <= 223 then
      index = sign and index - 2 or index + 2
    elseif curByteNum >= 224 and curByteNum <= 239 then
      index = sign and index - 1 or index + 3
    elseif curByteNum >= 240 and curByteNum < 247 then
      index = sign and index - 1 or index + 4
    else
      index = index - 1
      goto CONTINUE
    end
    length = sign and length + 1 or length - 1
    if sign then
      if index <= 0 or length >= 0 then break end
    else
      if index > #str or length <= 0 then break end
    end
  end
  return sign and index + 0 or index - 1
end

function obj:subUtf8String(str, startIndex, endIndex)
    if not str or #str <= 0 then
        return 0
    end
    if startIndex > 1 then
      startIndex = getAsciiLenth(str, startIndex)
    elseif startIndex < 0 then
      startIndex = getAsciiLenth(str, startIndex)
      return string.sub(str, -(#str - startIndex))
    end
    endIndex = getAsciiLenth(str, endIndex)
    return string.sub(str, startIndex, endIndex)
end

local function getYouDaoInput(q)
  if utf8.len(q) <= 20 then
    return q
  end
  local input = obj:subUtf8String(q, 1, 10) .. utf8.len(q) .. obj:subUtf8String(q, -10)
  print("拼接input=" .. input)
  return input
end

function obj:currentSelection()
   local elem = hs.uielement.focusedElement()
   local sel = nil
   if elem then
      sel = elem:selectedText()
   end
   if (not sel) or (sel == "") then
      hs.eventtap.keyStroke({"cmd"}, "c")
      -- 20 ms
      hs.timer.usleep(20000)
      sel=hs.pasteboard.getContents()
   else
      obj.log:i("sel:" .. sel)
   end
   return (sel or "")
end

function obj:getFormParamsStr(form)
  local formParamsStr = ""
  for k,v in pairs(form) do
    if formParamsStr ~= "" then
      formParamsStr = formParamsStr .. "&"
    end
    formParamsStr = formParamsStr .. k .. "=" .. v
  end
  return formParamsStr
end

function obj:translate(from, to)
  local params = {
    from, to,
    appKey = obj.appKey,
    salt = obj.salt,
    signType = obj.signType,
    curtime = os.time()
  }
  local contents = obj:currentSelection()
  params.q = hs.http.encodeForQuery(contents)
  if params.q == nil or params.q == "" then
    return -1, "请选择或复制要翻译的文本"
  end
  if params.q == obj.q then
    obj.log:i("Same as before: ")
    return obj.code, obj.response
  end
  obj.q = params.q
  params.sign = hs.hash.SHA256(params.appKey .. getYouDaoInput(contents) .. params.salt .. params.curtime .. obj.secret)
  local code, response, _ = hs.http.post(obj.apiUrl, obj:getFormParamsStr(params))
  obj.log:i("code: " .. code)
  obj.log:i("body: " .. response)
  obj.code = code
  obj.response = response
  return code, response
end

function obj:showTipWindow(text)
  if (obj.translationCanvas == nil) then
    local mainScreen = hs.screen.mainScreen():frame()
    local sp = hs.mouse.getAbsolutePosition()
    local x = #text > 700 and mainScreen.w - 500 or sp.x
    local y = #text > 700 and mainScreen.y or sp.y - 20
    obj.translationCanvas = hs.canvas.new{x = x,y = y,h=300,w=500}:appendElements({
      action = "fill", type = "rectangle",
      frame = { x = "0", y = "0", h = "1.0", w = "1.0", },
      fillColor = { alpha = 1.0, white = 0.9, black = 0.1},
      roundedRectRadii = {xRadius = 10, yRadius = 10}
    }, {
      action = "fill", type = "text", text = text, textSize = 25,
      textColor = { alpha = 1.0, black = 1.0 },
      frame = { x = ".06", y = "0.06", h = ".96", w = ".82" }
    }):show(0.3)
    local add = math.floor(#text / 500)
    if add > 1 then
      obj.translationCanvas:size({h=300*add, w= 500})
    end
  end
end

function obj:layout(code, response)
  response = hs.json.decode(response)
  if code ~= 200 then
    return hs.styledtext.new(response, {font = {size = 16}})
  end

  if response.errorCode ~= nil and response.errorCode ~= "0" then
    return hs.styledtext.new("发生错误" .. response.errorCode, {font = {size = 16}})
  end

  local text = response.translation[1]

  if response.basic ~= nil and response.basic.phonetic ~= nil and response.basic.phonetic ~= "" then
    text = text .. "  [" .. response.basic.phonetic .. "]"
  end

  text = text .. "\n"

  if response.basic ~= nil and response.basic.explains ~= nil then
    text = text .. "释义：" .. response.basic.explains[1] .. "\n"
  else
  end
  --if not response.isWord and #text < 600 then
    --text = text .. response.query
  --end
  if response.basic ~= nil then
    if response.basic['us-phonetic'] ~= nil then
      text = text .. "美 [" .. response.basic['us-phonetic'] .. "]  "
    end
    if response.basic['uk-phonetic'] ~= nil and response.basic['uk-phonetic'] ~= "" then
      text = text .. "英 [" .. response.basic['uk-phonetic'] .. "]"
    end
    text = text .. "\n"
  end
  if response.web ~= nil then
    --if not response.isWord and #text < 600 then
      --text = text .. "\n--------------------------------------------------------\n"
    --end
    text = text .. "--------------------------------------------------------\n"
    for _, item in pairs(response.web) do
      text = text .. item.key .. " : "
      for i = 1, #item.value do
        text = text .. item.value[i]
        if i ~= #item.value then text = text .. ", " end
      end
      text = text .. "\n"
    end
  end

  return hs.styledtext.new(text, {font = {size = 16}, paragraphStyle = {minimumLineHeight = 25}})
end

-- escape or leftMouse or Mouse
local eventTypes = {hs.eventtap.event.types.keyDown, hs.eventtap.event.types.leftMouseDown, hs.eventtap.event.types.rightMouseUp}

hs.hotkey.bind('alt', 'y', nil, function()
  local code, response = obj:translate("en", "zh-CHS")
  obj:showTipWindow(obj:layout(code, response))
  if obj.eventType == nuil then
    obj.exitevent = hs.eventtap.new(eventTypes, function(event)
      local eventType = hs.eventtap.event.types[event:getType()]
      local keyName = hs.keycodes.map[event:getKeyCode()]
      if keyName == 'escape' or eventType ~= "keyDown" then
        if obj.translationCanvas ~= nil then
          obj.translationCanvas:delete(1)
          obj.translationCanvas = nil
        end
      end
    end):start()
  end
end)

return obj
