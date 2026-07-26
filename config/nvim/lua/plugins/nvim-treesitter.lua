local ensure_installed = {
  "lua",
  "vim",
  "vimdoc",
  "query",
  "javascript",
  "typescript",
  "tsx",
  "html",
  "css",
  "scss",
  "json",
  "yaml",
  "markdown",
  "markdown_inline",
  "bash",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "rust",
  "toml",
  "sql",
  "nix",
  "prisma",
  "terraform",
  "hcl",
  "dockerfile",
  "regex",
}

-- treesitter のクエリ compile は初回ファイル open で ~100ms かかる。
-- 起動直後の idle にプロジェクトの言語ぶんを先に compile して待ちを無くす。
local PROJECT_MARKERS = {
  ["tsconfig.json"] = { "typescript", "tsx" },
  ["package.json"] = { "typescript", "tsx" },
  ["go.mod"] = { "go" },
  ["Cargo.toml"] = { "rust" },
  ["flake.nix"] = { "nix" },
}
local PREWARM_QUERIES = { "highlights", "injections", "indents" }

---@return string[]
local function _detect_project_langs()
  local seen = { lua = true } -- 設定編集で常に使う
  local root = vim.fs.root(vim.uv.cwd(), vim.tbl_keys(PROJECT_MARKERS))
  if root then
    for marker, langs in pairs(PROJECT_MARKERS) do
      if vim.uv.fs_stat(root .. "/" .. marker) then
        for _, lang in ipairs(langs) do
          seen[lang] = true
        end
      end
    end
  end
  return vim.tbl_keys(seen)
end

---@param lang string
---@return nil
local function _prewarm_lang(lang)
  if not pcall(vim.treesitter.language.add, lang) then
    return
  end
  for _, query in ipairs(PREWARM_QUERIES) do
    pcall(vim.treesitter.query.get, lang, query)
  end
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter-start", {}),
        callback = function()
          pcall(vim.treesitter.start)
          pcall(function()
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end)
        end,
      })
    end,
    config = function()
      require("nvim-treesitter").setup({})
      require("nvim-treesitter").install(ensure_installed)

      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        group = vim.api.nvim_create_augroup("treesitter-prewarm", {}),
        callback = function()
          -- 単スレを塞ぎ続けないよう言語ごとに間隔を空ける
          for i, lang in ipairs(_detect_project_langs()) do
            vim.defer_fn(function()
              _prewarm_lang(lang)
            end, i * 200)
          end
        end,
      })
    end,
  },
}
