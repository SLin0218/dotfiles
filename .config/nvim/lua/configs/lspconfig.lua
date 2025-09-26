-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local nvlsp = require "nvchad.configs.lspconfig"

local servers = {
  "html",
  "cssls",
  "clangd",
  -- "jsonls",
  "pyright",
  "rust_analyzer",
  "marksman",
  "clangd",
  "gopls",
  "csharp_ls",
  "ts_ls",
}

vim.lsp.enable(servers)

-- lsps with default config
for _, lsp in ipairs(servers) do
  vim.lsp.config(lsp, {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  })
end

vim.lsp.enable { "lua_ls" }

vim.lsp.config("lua_ls", {
  on_attach = nvlsp.on_attach,
  capabilities = nvlsp.capabilities,
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
})
