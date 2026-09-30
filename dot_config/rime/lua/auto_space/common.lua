-- 中英数字自动空格的共用边界判断。
--
-- 只在「汉字 ↔ ASCII 英文/数字」之间加空格，故意不处理：
-- - 英文 ↔ 数字：GPT-5.6、iPhone15 保持原样；
-- - 标点边界：URL、邮箱、小数、路径和中英标点不做猜测；
-- - 已有空格：不再重复添加。

local M = {
    kAccepted = 1,
    kNoop = 2,
}

local function is_han(codepoint)
    return codepoint == 0x3007 or
        (codepoint >= 0x3400 and codepoint <= 0x4DBF) or
        (codepoint >= 0x4E00 and codepoint <= 0x9FFF) or
        (codepoint >= 0xF900 and codepoint <= 0xFAFF) or
        (codepoint >= 0x20000 and codepoint <= 0x323AF)
end

function M.category(codepoint)
    if is_han(codepoint) then return "han" end
    if (codepoint >= 0x41 and codepoint <= 0x5A) or (codepoint >= 0x61 and codepoint <= 0x7A) then
        return "latin"
    end
    if codepoint >= 0x30 and codepoint <= 0x39 then return "digit" end
    return nil
end

function M.first_category(text)
    if not text or text == "" then return nil end
    for _, codepoint in utf8.codes(text) do return M.category(codepoint) end
    return nil
end

function M.last_category(text)
    if not text or text == "" then return nil end
    local result
    for _, codepoint in utf8.codes(text) do result = M.category(codepoint) end
    return result
end

function M.needs_space(left, right)
    if left == "han" then return right == "latin" or right == "digit" end
    if right == "han" then return left == "latin" or left == "digit" end
    return false
end

-- 判断当前候选是否适合在其后直接输出半角句点。
-- 允许常见英文词、缩写和代码名（iPad、GPT-5、C++），不接管汉字候选。
function M.is_ascii_token(text)
    if not text then return false end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text:match("^[%a][%a%d_'%+%-]*$") ~= nil
end

function M.add_inner_spaces(text)
    if not text or text == "" then return text end

    local result = {}
    local previous_category
    for _, codepoint in utf8.codes(text) do
        local current_category = M.category(codepoint)
        if M.needs_space(previous_category, current_category) then result[#result + 1] = " " end
        result[#result + 1] = utf8.char(codepoint)
        previous_category = current_category
    end
    return table.concat(result)
end

return M
