-- replace ui for message, cmdline, popmenu
return {
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {},
  dependencies = {
    "muniftanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
  config = function()
    require("noice").setup({
      lsp = {
        signature = {
          enabled = false,
        },
      },
      presets = {
        command_palette = false,
      },
      messages = {
        enabled = true,
        view = "mini",
        view_error = "notify",
        view_warn = "notify",
        view_history = "messages",
        view_search = false,
      },
      routes = {
        {
          filter = {
            any = {
              { event = "msg_show", error = true,               find = "e486:" },
              { event = "msg_show", find = "no lines in buffer" },
              { event = "msg_show", find = "%d+ lines? yanked" },
              { event = "msg_show", find = "%d+ more lines?" },
              { event = "msg_show", find = "%d+ less lines?" },
              { event = "msg_show", find = "fewer line" },
              { event = "msg_show", find = "lines >ed 1 time" },
              { event = "msg_show", find = "changes?; before" },
              { event = "msg_show", find = "changes?; after" },
            },
          },
          opts = { skip = true },
        },
        {
          filter = {
            any = {
              { event = "msg_show", error = true,   find = "e20:" },
              { event = "msg_show", error = true,   find = "e42:" },
              { event = "msg_show", error = true,   find = "e492:" },
              { event = "msg_show", error = true,   find = "e5107:" },
              { event = "msg_show", warning = true, find = "search hit bottom, continuing at top" },
              { event = "msg_show", warning = true, find = "search hit top, continuing at bottom" },
              { event = "notify",   warning = true, find = "aborted" },
              { event = "notify",   kind = "info",  find = "cwd: " },
              { event = "notify",   kind = "info",  find = "was properly created" },
              { event = "notify",   kind = "info",  find = "was properly removed" },
              { event = "notify",   kind = "info",  find = "added to clipboard" },
              { event = "notify",   kind = "info",  find = " -> " },
              { event = "notify",   kind = "info",  find = "no information available" },
              { event = "notify",   kind = "info",  find = "no code actions available" },
              { event = "notify",   kind = "warn",  find = "no results for %*%*diagnostics%*%*" },
            },
          },
          view = "mini",
        },
        {
          filter = {
            any = {
              { event = "msg_showmode", find = "recording @.$" },
            },
          },
          view = "virtualtext",
        },
      },

      -- from recipes
      views = {
        cmdline_popup = {
          position = {
            row = 17,
            col = "50%",
          },
          size = {
            width = 60,
            height = "auto",
          },
        },
        popupmenu = {
          relative = "editor",
          position = {
            row = 20,
            col = "50%",
          },
          size = {
            width = 60,
            height = 10,
          },
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
          win_options = {
            winhighlight = { normal = "normal", floatborder = "diagnosticinfo" },
          },
        },
      },
    })
  end,
}
