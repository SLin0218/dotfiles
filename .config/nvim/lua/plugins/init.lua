return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("nvchad.configs.lspconfig").defaults()
      require "configs.lspconfig"
    end,
  },
  {
    "stevearc/conform.nvim",
     opts = require "configs.conform"
  },
  {
    "mg979/vim-visual-multi",
    init = function()
      vim.g.VM_maps = {
        ["Find Under"] = "<M-n>",
        ["Find Subword Under"] = "<M-n>",
      }
    end,
    lazy = false,
  },
  -- 高亮结尾空格
  { "ntpeters/vim-better-whitespace", lazy = false },
  { "williamboman/mason.nvim" },
  { "mfussenegger/nvim-jdtls" },
  { "slin0218/nvim-class", lazy = false },
  { "oxy2dev/markview.nvim", lazy = false },
}
