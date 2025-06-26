-- Usage:
-- This command copies the full path of the current active buffer (the file you're viewing)
-- to your system clipboard.
--
-- How to use:
-- 1. Ensure you have a file open in Neovim.
-- 2. Run the command: :CopyBufferPath
-- 3. The file path is now in your clipboard and can be pasted elsewhere.

-- Copy current buffer path to clipboard
vim.api.nvim_create_user_command(
  'CopyBufferPath',  -- Command name (e.g., :CopyBufferPath)
  function()
    local filename = vim.fn.expand('%:p') -- Get the full path of the current buffer
    local cmd = ''

    if vim.fn.has('mac') then
      -- For macOS
      cmd = 'echo "' .. filename .. '" | pbcopy'
    elseif vim.fn.has('win32') then
      -- For Windows
      cmd = 'echo "' .. filename .. '" | clip'
    elseif vim.fn.has('unix') then
      -- For Linux (assumes xclip is installed)
      -- For Wayland, you might need 'wl-copy' instead
      cmd = 'echo "' .. filename .. '" | xclip -selection clipboard'
    else
      -- Fallback for other OS or if clipboard command is not found
      print("Warning: Clipboard command not found for your OS.")
      return
    end

    vim.fn.system(cmd) -- Execute the command
    print("Buffer path copied to clipboard: " .. filename)
  end,
  {
    desc = 'Copy current buffer path to clipboard', -- Command description for which-key, etc.
    nargs = 0, -- Takes no arguments
  }
)
