-- copy-mode.lua: tmux-like in-place copy mode with full ANSI color support for Zellij
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.signcolumn = "no"
vim.opt.laststatus = 0
vim.opt.showmode = true
vim.opt.ruler = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = false
vim.opt.wrap = true
vim.opt.cursorline = true
vim.opt.scrolloff = 0

-- Normal mode keymaps: q or Esc to exit immediately back to terminal, yy/Y to copy current line
vim.keymap.set("n", "q", "<cmd>qa!<CR>", { silent = true })
vim.keymap.set("n", "<Esc>", "<cmd>qa!<CR>", { silent = true })
vim.keymap.set("n", "yy", '"+yy<cmd>qa!<CR>', { silent = true })
vim.keymap.set("n", "Y", '"+yy<cmd>qa!<CR>', { silent = true })

-- Visual mode keymaps: y or Enter to yank to clipboard and exit immediately!
vim.keymap.set("v", "y", '"+y<cmd>qa!<CR>', { silent = true })
vim.keymap.set("v", "<CR>", '"+y<cmd>qa!<CR>', { silent = true })
vim.keymap.set("v", "q", "<Esc>", { silent = true })

-- 退出时确保 Zellij 状态栏切回 normal 模式
local function restore_zellij_mode()
    pcall(vim.fn.system, "zellij action switch-mode normal")
end

vim.api.nvim_create_autocmd({ "VimLeavePre", "VimLeave" }, {
    callback = restore_zellij_mode,
})

-- --- Catppuccin Mocha 终端一致配色 ---
local mocha = {
    base = "#1E1E2E",      -- Catppuccin Mocha 主背景色
    mantle = "#181825",    -- 状态栏背景色
    crust = "#11111B",
    text = "#CDD6F4",      -- 主文本颜色
    subtext0 = "#A6ADC8",
    overlay0 = "#6C7086",  -- 提示辅助灰
    surface0 = "#313244",  -- 光标行高亮背景
    surface1 = "#45475A",  -- 选中区域高亮 (Visual)
    surface2 = "#585B70",
    blue = "#89B4FA",
    yellow = "#F9E2AF",    -- Normal 模式金黄
    pink = "#F5C2E7",      -- Visual 模式粉紫
    red = "#F38BA8",       -- 只读警告红
}

-- 全局基础配色设定，确保进入复制模式时背景与终端完全融为一体
vim.api.nvim_set_hl(0, "Normal", { bg = mocha.base, fg = mocha.text })
vim.api.nvim_set_hl(0, "NormalNC", { bg = mocha.base, fg = mocha.text })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = mocha.base, fg = mocha.text })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = mocha.base, fg = mocha.base })
vim.api.nvim_set_hl(0, "CursorLine", { bg = mocha.surface0 })
vim.api.nvim_set_hl(0, "Visual", { bg = mocha.surface1, fg = mocha.text, bold = true })
vim.api.nvim_set_hl(0, "Cursor", { bg = mocha.blue, fg = mocha.crust })
vim.api.nvim_set_hl(0, "ModeMsg", { fg = mocha.yellow, bg = mocha.base, bold = true })
vim.api.nvim_set_hl(0, "MsgArea", { bg = mocha.base, fg = mocha.text })

-- --- ANSI Color Palette (Catppuccin Mocha aligned) ---
local ansi_colors = {
    [0] = "#45475a", [1] = "#f38ba8", [2] = "#a6e3a1", [3] = "#f9e2af",
    [4] = "#89b4fa", [5] = "#f5c2e7", [6] = "#94e2d5", [7] = "#cdd6f4",
    [8] = "#585b70", [9] = "#f38ba8", [10] = "#a6e3a1", [11] = "#f9e2af",
    [12] = "#89b4fa", [13] = "#f5c2e7", [14] = "#94e2d5", [15] = "#ffffff",
}

local hl_cache = {}
local function get_hl_group(fg_color, bg_color, is_bold, is_italic, is_underline)
    local key = string.format("%s_%s_%s_%s_%s", tostring(fg_color), tostring(bg_color), tostring(is_bold), tostring(is_italic), tostring(is_underline))
    if hl_cache[key] then return hl_cache[key] end
    local hl_name = "ZellijAnsi_" .. string.gsub(key, "#", "")
    local opts = {}
    if fg_color then opts.fg = fg_color end
    if bg_color then opts.bg = bg_color end
    if is_bold then opts.bold = true end
    if is_italic then opts.italic = true end
    if is_underline then opts.underline = true end
    vim.api.nvim_set_hl(0, hl_name, opts)
    hl_cache[key] = hl_name
    return hl_name
end

local function colorize_ansi(bufnr)
    bufnr = bufnr or 0
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local ns = vim.api.nvim_create_namespace("zellij_ansi")
    local new_lines = {}
    local line_marks = {}

    local cur_fg, cur_bg, cur_bold, cur_italic, cur_underline = nil, nil, false, false, false
    local has_any_ansi = false

    for row_idx, line in ipairs(lines) do
        local clean_text = {}
        local marks = {}
        local last_pos = 1
        local col = 0

        for start_pos, codes_str, end_pos in line:gmatch("()(\27%[[%d;]*m)()") do
            has_any_ansi = true
            if start_pos > last_pos then
                local segment = line:sub(last_pos, start_pos - 1)
                table.insert(clean_text, segment)
                local seg_len = #segment
                if (cur_fg or cur_bg or cur_bold or cur_italic or cur_underline) and seg_len > 0 then
                    local hl = get_hl_group(cur_fg, cur_bg, cur_bold, cur_italic, cur_underline)
                    table.insert(marks, { col = col, end_col = col + seg_len, hl = hl })
                end
                col = col + seg_len
            end

            local inner = codes_str:sub(3, -2)
            if inner == "" or inner == "0" then
                cur_fg, cur_bg, cur_bold, cur_italic, cur_underline = nil, nil, false, false, false
            else
                local parts = {}
                for num in inner:gmatch("%d+") do
                    table.insert(parts, tonumber(num))
                end
                local i = 1
                while i <= #parts do
                    local n = parts[i]
                    if n == 0 then
                        cur_fg, cur_bg, cur_bold, cur_italic, cur_underline = nil, nil, false, false, false
                    elseif n == 1 then cur_bold = true
                    elseif n == 3 then cur_italic = true
                    elseif n == 4 then cur_underline = true
                    elseif n == 22 then cur_bold = false
                    elseif n == 23 then cur_italic = false
                    elseif n == 24 then cur_underline = false
                    elseif n >= 30 and n <= 37 then
                        cur_fg = ansi_colors[n - 30]
                    elseif n == 39 then
                        cur_fg = nil
                    elseif n >= 40 and n <= 47 then
                        cur_bg = ansi_colors[n - 40]
                    elseif n == 49 then
                        cur_bg = nil
                    elseif n >= 90 and n <= 97 then
                        cur_fg = ansi_colors[n - 90 + 8]
                    elseif n >= 100 and n <= 107 then
                        cur_bg = ansi_colors[n - 100 + 8]
                    elseif n == 38 and parts[i+1] == 2 and parts[i+2] and parts[i+3] and parts[i+4] then
                        cur_fg = string.format("#%02x%02x%02x", parts[i+2], parts[i+3], parts[i+4])
                        i = i + 4
                    elseif n == 48 and parts[i+1] == 2 and parts[i+2] and parts[i+3] and parts[i+4] then
                        cur_bg = string.format("#%02x%02x%02x", parts[i+2], parts[i+3], parts[i+4])
                        i = i + 4
                    elseif n == 38 and parts[i+1] == 5 and parts[i+2] then
                        local c = parts[i+2]
                        if c < 16 then cur_fg = ansi_colors[c] end
                        i = i + 2
                    elseif n == 48 and parts[i+1] == 5 and parts[i+2] then
                        local c = parts[i+2]
                        if c < 16 then cur_bg = ansi_colors[c] end
                        i = i + 2
                    end
                    i = i + 1
                end
            end
            last_pos = end_pos
        end

        if last_pos <= #line then
            local segment = line:sub(last_pos)
            table.insert(clean_text, segment)
            local seg_len = #segment
            if (cur_fg or cur_bg or cur_bold or cur_italic or cur_underline) and seg_len > 0 then
                local hl = get_hl_group(cur_fg, cur_bg, cur_bold, cur_italic, cur_underline)
                table.insert(marks, { col = col, end_col = col + seg_len, hl = hl })
            end
        end

        table.insert(new_lines, table.concat(clean_text))
        table.insert(line_marks, marks)
    end

    if has_any_ansi then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
        for r, marks in ipairs(line_marks) do
            for _, m in ipairs(marks) do
                vim.api.nvim_buf_set_extmark(bufnr, ns, r - 1, m.col, {
                    end_col = m.end_col,
                    hl_group = m.hl,
                })
            end
        end
    end
end

-- Hook into VimEnter: Colorize and precisely restore cursor position
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        -- 确保进入复制模式时 Zellij 顶部状态栏显示 COPY (locked 模式)
        pcall(vim.fn.system, "zellij action switch-mode locked")

        colorize_ansi(0)

        -- 1. 将窗口最底部对齐到缓冲区最后一行，保证视口与终端当前屏幕 100% 重合
        vim.cmd("normal! Gzb")

        -- 2. 自底向上寻找最后一个有内容的行（即命令行 Prompt 或最后一行命令输出）
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local target_row = #lines
        local target_col = 0

        for i = #lines, 1, -1 do
            local line = lines[i]
            if line:match("%S") then
                target_row = i
                local last_char_pos = line:match(".*()%S")
                target_col = last_char_pos or #line
                break
            end
        end

        -- 3. 将光标精准投放到原本终端光标所在的行列位置（不引起屏幕跳动）
        pcall(vim.api.nvim_win_set_cursor, 0, { target_row, math.max(0, target_col - 1) })

        -- 4. 锁定缓冲区为只读，避免误编辑终端历史内容
        vim.bo.modifiable = false
        vim.bo.readonly = true
        vim.bo.buftype = "nofile"
    end,
})
