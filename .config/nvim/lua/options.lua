require "nvchad.options"
require "jdtls-conf"

local autocmd = vim.api.nvim_create_autocmd
local o = vim.o
local g = vim.g

o.colorcolumn = "121"
o.foldenable = false
o.foldmethod = "expr"
o.foldexpr = "nvim_treesitter#foldexpr()"
o.foldlevel = 3
o.foldminlines = 20
o.foldtext = "v:lua.custom_fold_text()"
o.fileencodings = "utf-8,gbk"
o.relativenumber = true
o.fillchars = "eob:-,fold: "
o.guicursor = "n-v-c-sm:block,i-ci-ve:hor25-blinkon250,r-cr-o:hor20"

g.vscode_snippets_path = vim.fn.stdpath "config" .. "/lua/snippets"

o.guifont = "JetbrainsMono Nerd Font:h14"
g.neovide_theme = 'auto'
g.neovide_window_blurred = true
g.neovide_transparency = 1.0
g.neovide_cursor_vfx_mode = "sonicboom"
g.neovide_padding_top = 30
g.neovide_padding_bottom = 0
g.neovide_padding_right = 0
g.neovide_padding_left = 0

-- g.transparency = 1.0
-- local alpha = function()
--   return string.format("%x", math.floor(255 * g.transparency or 0.8))
-- end
-- g.neovide_background_color = "#1e1e2e" .. alpha()

-- opt.viewoptions:remove { "options" }

vim.cmd "silent! command! EnableShade lua require('shade').toggle()"

function _G.custom_fold_text()
  local line = vim.fn.getline(vim.v.foldstart)
  local line_count = vim.v.foldend - vim.v.foldstart + 1
  -- local i, j = string.find(line, "^%s+")
  -- return string.sub(line, i, j) .. "🤡" .. string.sub(line, j) .. "    :" .. line_count .. " lines"
  return "🤡" .. string.sub(line, 3) .. "    :" .. line_count .. " lines"
end

-- vim leave change cursor style to underline and blinking
autocmd("VimLeave", {
  callback = function()
    o.guicursor = "a:hor25-blinkon250"
  end,
})

-- Open a file from its last left off position
autocmd("BufReadPost", {
  callback = function()
    if not vim.fn.expand("%:p"):match ".git" and vim.fn.line "'\"" > 1 and vim.fn.line "'\"" <= vim.fn.line "$" then
      vim.cmd "normal! g'\""
      vim.cmd "normal zz"
    end
  end,
})

autocmd("InsertEnter", {
  callback = function()
    o.relativenumber = false
  end,
})

autocmd("InsertLeave", {
  callback = function()
    o.relativenumber = true
  end,
})

-- Enable spellchecking in markdown, text and gitcommit files
autocmd("FileType", {
  -- pattern = { "gitcommit", "markdown", "text" },
  pattern = { "markdown" },
  callback = function()
    vim.cmd "EnableWhitespace"
    -- vim.opt_local.spell = true
    -- vim.opt_local.spelllang = "en_us, cjk"
  end,
})

-- File extension specific tabbing
autocmd("Filetype", {
  pattern = "python",
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
  end,
})

-- autocmd("FileType", {
--   pattern = { "java" },
--   callback = function()
--     vim.cmd "set tabstop=4"
--     vim.cmd "set shiftwidth=4"
--     vim.cmd "set expandtab"
--     require("custom.plugins.jdtls").setup()
--   end,
-- })

-- the rasi filetype will use the css parser and queries.
autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.rasi" },
  callback = function()
    vim.cmd("set filetype=rasi")
    vim.treesitter.language.register("css", "rasi")
    vim.cmd("set syntax=css")
  end,
})
