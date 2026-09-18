-- 候选词自动空格：
-- 1. 处理同一候选内部，如「iPad很好」→「iPad 很好」；
-- 2. 根据上次上屏文本处理跨候选边界，如「使用」+「iPad」。
--
-- 必须放在 search 辅码过滤之后、uniquifier 之前；否则前导空格会导致
-- 小鹤音形 fn/bm 辅码无法用原始候选文字做匹配。

local common = require("auto_space.common")
local filter = {}

local function has_selected_prefix(context)
    local composition = context.composition
    if not composition or composition:empty() then return false end

    -- 数字键选中单字后，Rime 会把它保留为当前 composition 的已选分段，
    -- 并继续为剩余编码生成候选。此时 commit_history 仍指向组合开始前
    -- 的上屏文本；若每个剩余分段都据此补空格，就会得到「张 三 丰」。
    local segmentation = composition:toSegmentation()
    return segmentation and segmentation:get_confirmed_position() > 0
end

function filter.func(input, env)
    local context = env.engine.context
    if not context:get_option("auto_space") then
        for cand in input:iter() do yield(cand) end
        return
    end

    local previous_category
    if not has_selected_prefix(context) then
        previous_category = common.last_category(context.commit_history:latest_text())
    end

    for cand in input:iter() do
        local text = common.add_inner_spaces(cand.text)
        if common.needs_space(previous_category, common.first_category(text)) then text = " " .. text end

        if text ~= cand.text then
            cand = cand:to_shadow_candidate("auto_space", text, cand.comment)
        end
        yield(cand)
    end
end

return filter
