-- lua/xhup/english_len_filter.lua
-- 当输入码长度 <= 4 时屏蔽来自外部英文词库的候选，>= 5 时放行英文单词联想

local M = {}

function M.init(env)
    local config = env.engine.schema.config
    env.name_space = env.name_space:gsub("^*", "")
    M.min_length = config:get_int(env.name_space .. "/min_length") or 5
end

function M.func(input, env)
    local code = env.engine.context.input
    local pure_code = code:gsub("[^%a]", "")
    local code_len = #pure_code

    for cand in input:iter() do
        -- 外部英文词库（melt_eng）产生的候选具有负质量（quality < 0）或 type == "completion"
        local is_eng = (cand.quality < 0 or cand.type == "completion")

        if is_eng and code_len < M.min_length then
            -- 码长未达到阈值（默认 5 码），丢弃外部英文词库候选，完全不污染 1~4 码中文候选
        else
            yield(cand)
        end
    end
end

return M
