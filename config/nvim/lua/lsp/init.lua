vim.lsp.enable({
  "lua_ls",
  "vtsls",
  "bashls",
  "html",
  "cssls",
  "tailwindcss",
  "prisma",
  "terraform-ls",
  "eslint",
  "biome",
  "jsonls",
  "yamlls",
  "copilot",
})

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
    keymap.set("n", "gs", "<cmd>LspRestart<CR>", opts)

    -- HACK: デフォルトでlspから返ってくるtypescriptのinlay hintsが長々すぎるので、クライアント側で無理やり切り詰める
    -- lsp設定などでサーバ側で切り詰めるなどは現状できないらしい
    -- @See: https://www.reddit.com/r/neovim/comments/1c3iz5j/hack_truncate_long_typescript_inlay_hints/
    local methods = vim.lsp.protocol.Methods
    local inlay_hint_handler = vim.lsp.handlers[methods.textDocument_inlayHint]
    vim.lsp.handlers[methods.textDocument_inlayHint] = function(err, result, ctx, config)
      local client = vim.lsp.get_client_by_id(ctx.client_id)
      if client and client.name == "vtsls" then
        result = vim
          .iter(result)
          :map(function(hint)
            local label = hint.label
            if type(label) == "string" then
              if label:len() >= 30 then
                label = label:sub(1, 29) .. "…"
              end
              hint.label = label
            elseif type(label) == "table" then
              -- label is InlayHintLabelPart[]
              local total_len = 0
              for _, part in ipairs(label) do
                total_len = total_len + part.value:len()
              end
              if total_len >= 30 then
                local current_len = 0
                hint.label = vim
                  .iter(label)
                  :map(function(part)
                    if current_len >= 29 then
                      return nil
                    end
                    local remaining = 29 - current_len
                    if part.value:len() > remaining then
                      part.value = part.value:sub(1, remaining) .. "…"
                      current_len = 29
                    else
                      current_len = current_len + part.value:len()
                    end
                    return part
                  end)
                  :totable()
              end
            end
            return hint
          end)
          :totable()
      end

      inlay_hint_handler(err, result, ctx, config)
    end

    -- inlayhint settings
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
      -- Toggle inlay hints
      keymap.set("n", "gh", function()
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
