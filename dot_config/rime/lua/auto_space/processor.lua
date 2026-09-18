-- 直接上屏文本的自动空格。
--
-- filter.lua 只能修改候选，无法处理不经候选直接上屏的数字，所以需要
-- processor 拦截「汉字后输入第一个数字」。后续数字仍交给 Rime，因此
-- 3.14、2026 之类的内部不会被插入空格。
--
-- 另外在英文候选或已上屏英文后拦截句点，直接输出半角「.」；
-- 中文候选后的句点仍由 punctuator 输出「。」。
--
-- 在英文模式、使用修饰键或关闭 auto_space 时不介入。

local common = require("auto_space.common")
local processor = {}

local function unmodified_key(key)
    return not key:release() and not key:ctrl() and not key:alt() and not key:super()
end

function processor.func(key, env)
    local context = env.engine.context
    if not context:get_option("auto_space") or context:get_option("ascii_mode") or not unmodified_key(key) then
        return common.kNoop
    end

    local key_repr = key:repr()

    -- 中文模式的句点默认映射为「。」。当前是英文候选时，先正常确认、
    -- 上屏候选（保留用户词频学习），然后单独上屏半角句点。
    if key_repr == "period" or key_repr == "." then
        if context:is_composing() then
            local candidate = context:get_selected_candidate()
            if candidate and common.is_ascii_token(candidate.text) and context:confirm_current_selection() then
                context:commit()
                env.engine:commit_text(".")
                return common.kAccepted
            end
        else
            local latest_text = context.commit_history:latest_text()
            if common.last_category(latest_text) == "latin" then
                env.engine:commit_text(".")
                return common.kAccepted
            end
        end
    end

    if not context:is_composing() and key_repr:match("^%d$") then
        local latest_text = context.commit_history:latest_text()
        if common.needs_space(common.last_category(latest_text), "digit") then
            env.engine:commit_text(" " .. key_repr)
            return common.kAccepted
        end
    end

    -- Return 在方案中是 commit_raw_input。仅当原始输入以英文/数字开头，
    -- 且上次上屏以汉字结尾时，才接管这次上屏。
    if context:is_composing() and key_repr == "Return" then
        local raw_input = context.input
        local latest_text = context.commit_history:latest_text()
        if raw_input and raw_input ~= "" and
            common.needs_space(common.last_category(latest_text), common.first_category(raw_input)) then
            context:clear()
            env.engine:commit_text(" " .. raw_input)
            return common.kAccepted
        end
    end

    return common.kNoop
end

return processor
