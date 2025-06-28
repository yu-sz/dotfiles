-- formatter settings
return {
  "stevearc/conform.nvim",
  event = "VeryLazy",
  opts = function()
    local web_formatter = function()
      return { "biome-check", "prettier", stop_after_first = true }
    end

    return {
      web_formatter = {
        lua = { "stylua" },
        bash = { "shfmt" },
        sql = { "sleek" },
        -- Web
        typescript = web_formatter,
        javascript = web_formatter,
        typescriptreact = web_formatter,
        javascriptreact = web_formatter,
        json = web_formatter,
        jsonc = web_formatter,
        yaml = { "prettier" },
        html = web_formatter,
        css = web_formatter,
        scss = web_formatter,
        less = web_formatter,
      },
      format_on_save = {
        timeout_ms = 1500,
        -- conformで定義したformatterが存在しないならLSPのフォーマッターを使う
        lsp_format = "fallback",
      },
    }
  end
}
