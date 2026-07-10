vim.lsp.enable({
  "lua_ls",
  "nixd",
  "vtsls",
  "bashls",
  "html",
  "cssls",
  "tailwindcss",
  "prismals",
  "terraformls",
  "eslint",
  "biome",
  "gopls",
  "rust_analyzer",
  "jsonls",
  "yamlls",
  "sqls",
  "copilot",
})

-- 深刻度が高い方を優先して表示し、サインを ● に統一
vim.diagnostic.config({
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "●",
      [vim.diagnostic.severity.WARN] = "●",
      [vim.diagnostic.severity.INFO] = "●",
      [vim.diagnostic.severity.HINT] = "●",
    },
  },
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    if vim.bo[ev.buf].filetype == "markdown" then
      return
    end

    ---@param lhs string
    ---@param rhs string|function
    ---@param desc string
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { silent = true, buffer = ev.buf, desc = desc })
    end

    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("gi", vim.lsp.buf.implementation, "Go to implementation")
    map("K", "<cmd>Lspsaga hover_doc<CR>", "Hover documentation")
    map("gt", "<cmd>Lspsaga peek_type_definition<CR>", "Peek type definition")
    map("gr", "<cmd>Lspsaga finder ref<CR>", "Find references")
    map("gra", "<cmd>Lspsaga code_action<CR>", "Code action")
    map("grn", "<cmd>Lspsaga rename<CR>", "Rename symbol")
    map("]d", "<cmd>Lspsaga diagnostic_jump_next<CR>", "Next diagnostic")
    map("[d", "<cmd>Lspsaga diagnostic_jump_prev<CR>", "Previous diagnostic")
    map("gl", vim.diagnostic.open_float, "Show diagnostics in float")
    map("gs", "<cmd>LspRestart<CR>", "Restart LSP")

    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method("textDocument/inlayHint") then
      map("gh", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
      end, "Toggle inlay hints")

      -- Enable inlay hints by default
      vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
    end
  end,
})
