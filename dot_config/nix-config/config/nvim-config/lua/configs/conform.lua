local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    sh = { "shellcheck", "shfmt" },

    xml = { "xmlformatter" },

    javascript = { "prettier" },
    typescript = { "prettier" },
    js = { "prettier" },
    vue = { "prettier" },
    css = { "prettier" },
    html = { "prettier" },
    markdown = { "prettier" },
    yaml = { "prettier" },
    json = { "prettier" },

    go = { "gofmt" },

    python = { "isort", "black" },
    sql = { "sqlfluff" },
  },

  -- format_on_save = {
  --   -- These options will be passed to conform.format()
  --   timeout_ms = 500,
  --   lsp_fallback = true,
  -- },
}

return options
