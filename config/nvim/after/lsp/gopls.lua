---@type vim.lsp.Config
return {
  on_attach = function(client, bufnr)
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function()
        local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
        params.context = { only = { "source.organizeImports" } }
        local result = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 1000)
        for _, res in pairs(result or {}) do
          for _, action in pairs(res.result or {}) do
            if action.edit then
              vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
            end
          end
        end
      end,
    })
  end,
  settings = {
    gopls = {
      gofumpt = true,
      staticcheck = true,
      analyses = {
        unusedparams = true,
        unusedwrite = true,
        useany = true,
        nilness = true,
      },
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  },
}
