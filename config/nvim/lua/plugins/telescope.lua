-- fuzzy finder(and more...)
return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.5",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope-file-browser.nvim",
    "prochri/telescope-all-recent.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  keys = {
    {
      "<leader>ff",
      function()
        require("telescope.builtin").find_files({
          no_ignore = false,
          hidden = true,
        })
      end,
      desc = "Find File",
    },
    {
      "<leader>fg",
      function()
        require("telescope.builtin").live_grep({
          additional_args = { "--hidden" },
        })
      end,
      desc = "Live Grep (search files by content)"
    },
    {
      "<leader>fc",
      function()
        require("telescope.builtin").current_buffer_fuzzy_find()
      end,
      desc = "fuzzy search inside of the currently open buffer",
    },

    {
      "<leader>fb",
      function()
        local telescope = require("telescope")

        local function telescope_buffer_dir()
          return vim.fn.expand("%:p:h")
        end

        telescope.extensions.file_browser.file_browser({
          path = "%:p:h",
          cwd = telescope_buffer_dir(),
          respect_gitignore = false,
          hidden = true,
          grouped = true,
          initial_mode = "normal",
        })
      end,
      desc = "file browser",
    },
    {
      "<leader>ls",
      function()
        require("telescope.builtin").buffers({
          initial_mode = "normal",
          sort_mru = true,
        })
      end,
      desc = "show open buffers",
    },
    {
      "<leader>fj",
      function()
        local jumplist = vim.fn.getjumplist()
        require("telescope.builtin").jumplist({
          on_complete = {
            function(self)
              local n = #jumplist[1]
              if n ~= jumplist[2] then
                self:move_selection(jumplist[2] - #jumplist[1] + 1)
              end
            end,
          },
        })
      end,
      desc = "view jumplist (select current)",
    },
    {
      "<leader>ft",
      function()
        vim.cmd("TodoTelescope")
      end,
      desc = "Run ToDo telescope Command",
    },
    {
      "<leader>fh",
      function()
        require("telescope.builtin").help_tags()
      end,
    },
  },
  config = function(_, opts)
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local fb_actions = require("telescope").extensions.file_browser.actions

    opts.defaults = {
      file_ignore_patterns = {
        -- 検索から除外するものを指定
        "^.git/",
        "^.cache/",
        "^Library/",
        "Parallels",
        "^Movies",
        "^Music",
      },
      vimgrep_arguments = {
        -- ripggrepコマンドのオプション
        "rg",
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--smart-case",
        "-uu",
      },
      sorting_strategy = "ascending",
      layout_config = {
        prompt_position = "top",
      },
    }
    opts.extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = "smart_case",
      },
      file_browser = {
        -- theme = "dropdown",
        hijack_netrw = true,
        mappings = {
          ["n"] = {
            ["N"] = fb_actions.create,
            ["h"] = fb_actions.goto_parent_dir,
            ["<C-u>"] = function(prompt_bufnr)
              for i = 1, 10 do
                actions.move_selection_previous(prompt_bufnr)
              end
            end,
            ["<C-d>"] = function(prompt_bufnr)
              for i = 1, 10 do
                actions.move_selection_next(prompt_bufnr)
              end
            end,
            ["<PageUp>"] = actions.preview_scrolling_up,
            ["<PageDown>"] = actions.preview_scrolling_down,
          },
        },
      },
    }
    telescope.setup(opts)
    require("telescope").load_extension("fzf")
    require("telescope").load_extension("file_browser")
  end,
}
