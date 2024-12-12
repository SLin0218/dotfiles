-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "catppuccin-latte",
  hl_override = {
    CursorLine = { bg = "#181825" },
    Visual = { bg = "#45475a" },
    MatchWord = {
      fg = "yellow",
      bg = "#181825",
    },
    Normal = {
      -- bg = "none",
      -- guibg = nil,
      -- ctermbg = nil,
    },
    ExtraWhitespace = {
      guibg = "#6c7086",
    },
  },
}

M.mason = {
  cmd = true,
  pkgs = {
    "html-lsp",
    "lua-language-server",
    "isort",
    "stylua",
    "prettier",
    "pyright",
    "rust-analyzer",
    "go-debug-adapter",
    "clangd",
    "css-lsp",
    "deno",
    "emmet-ls",
    "gopls",
    "jdtls",
    "json-lsp",
    "marksman",
    "shfmt",
    "typescript-language-server",
    "vue-language-server",
    "autopep8",
    "xmlformatter",
    "shellcheck",
    "csharp-language-server",
  },
}

return M
