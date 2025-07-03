-- TypeScript lsp (wrapper for ts extension of vscode)

local root_markers = {
  ".git",
  "tsconfig.json",
  "jsconfig.json",
  "bun.lockb",      -- Bun
  "pnpm-lock.yaml", -- pnpm
  "yarn.lock",      -- Yarn
  "package.json",   -- npm and more...
}

-- プロジェクトのルートディレクトリを見つけるためのヘルパー関数。
-- 現在のファイルパスから親ディレクトリを遡り、指定されたマーカーファイルが存在するかをチェックします。
local function find_root_dir(start_path, markers)
  local current_dir = vim.fn.fnamemodify(start_path, ':p:h') -- Get directory of the file
  while current_dir ~= nil and current_dir ~= '' do
    for _, marker in ipairs(markers) do
      if vim.uv.fs_stat(current_dir .. '/' .. marker) then
        return current_dir
      end
    end
    local parent_dir = vim.fn.fnamemodify(current_dir, ':h')
    if parent_dir == current_dir then -- Reached filesystem root
      break
    end
    current_dir = parent_dir
  end
  return nil -- No root found
end

return {
  cmd = { 'vtsls' },
  workspace_folders_required = false,
  filetypes = {
    'javascript',
    'javascriptreact',
    'javascript.jsx',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
  },
  root_dir = function(fname)
    return find_root_dir(fname, root_markers)
  end,
  -- tssrver deep setting
  init_options = {
    hostInfo = 'neovim',
    -- completon
    includeCompletionsForModuleExports = true,
    includeCompletionsForImportStatements = true,
  },
  settings = {
    complete_function_calls = true,
    vtsls = {
      enableMoveToFileCodeAction = true,
      autoUseWorkspaceTsdk = true,
      experimental = {
        maxInlayHintLength = 30,
        completion = {
          enableServerSideFuzzyMatch = true,
        },
      },
    },
    typescript = {
      updateImportsOnFileMove = "always", -- "never" | "prompt" |"always"
      suggest = {
        completeFunctionCalls = true,
      },
      inlayHints = {
        includeInlayEnumMemberValueHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
        includeInlayParameterNameHintsWhenArgumentMatchesName = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayVariableTypeHints = false,
      },
    },
    javascript = {
      updateImportsOnFileMove = "always", -- "never" | "prompt" |"always"
      suggest = {
        completeFunctionCalls = true,
      },
      inlayHints = {
        includeInlayEnumMemberValueHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
        includeInlayParameterNameHintsWhenArgumentMatchesName = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayVariableTypeHints = false,
      },
    },
  }
}
