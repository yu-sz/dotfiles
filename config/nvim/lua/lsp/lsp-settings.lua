vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    if vim.bo[ev.buf].filetype == "markdown" then
      return
    end

    local keymap = vim.keymap
    local opts = { noremap = true, silent = true, buffer = ev.buf }

    -- jump definition
    keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    -- jump implementation
    keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    -- hover symbol documents (vim.lsp.buf.hover)
    keymap.set("n", "K", "<cmd>Lspsaga hover_doc<CR>", opts)
    -- hover type (extends vim.lsp.buf.type_definition)
    keymap.set("n", "gt", "<cmd>Lspsaga peek_type_definition<CR>", opts)
    -- view all reff (vim.lsp.buf.references)
    keymap.set("n", "gr", "<cmd>Lspsaga finder ref<CR>", opts)

    -- view code action (vim.lsp.buf.code_action)
    keymap.set("n", "gra", "<cmd>Lspsaga code_action<CR>", opts)
    -- rename symbol (vim.lsp.buf.rename)
    keymap.set("n", "grn", "<cmd>Lspsaga rename<CR>", opts)

    -- jump next diagnostic (vim.diagnostic.goto_next)
    keymap.set("n", "]d", "<cmd>Lspsaga diagnostic_jump_next<CR>", opts)
    -- jump previous diagnostic (vim.diagnostic.goto_prev)
    keymap.set("n", "[d", "<cmd>Lspsaga diagnostic_jump_prev<CR>", opts)
    -- open float message
    keymap.set("n", "gl", vim.diagnostic.open_float, opts)

    -- reboot LSP
    keymap.set("n", "<leader><leader>r", "<cmd>LspRestart<CR>", opts)

    -- inlayhint settings
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
      -- Toggle inlay hints
      keymap.set("n", "<leader><leader>i", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
      end, opts)

      -- Enable inlay hints by default
      vim.lsp.inlay_hint.enable()
    end

    -- 深刻度が高い方を優先して表示
    vim.diagnostic.config({ severity_sort = true })

    local signs = { Error = "●", Warn = "●", Hint = "●", Info = "●" }
    vim.diagnostic.config({
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = signs.Error,
          [vim.diagnostic.severity.WARN] = signs.Warn,
          [vim.diagnostic.severity.INFO] = signs.Info,
          [vim.diagnostic.severity.HINT] = signs.Hint,
        },
      },
    })
  end,
})
