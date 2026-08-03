-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local nvlsp = require "nvchad.configs.lspconfig"

local servers = {
  html = {},
  cssls = {},
  clangd = {},
  jsonls = {},
  pyright = {},
  rust_analyzer = {},
  marksman = {},
  gopls = {},
  csharp_ls = {},
  ts_ls = {},
  lua_ls = {
    settings = {
      Lua = {
        diagnostics = { globals = { "vim" } },
        runtime = {
          version = "LuaJIT",
        },
      },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
        },
      },
    },
  },
}

local default_opts = {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
}

-- lsps with default config
for name, opts in pairs(servers) do
  local final_opts = vim.tbl_deep_extend("keep", opts, default_opts)
  vim.lsp.config(name, final_opts)
  vim.lsp.enable(name)
end
