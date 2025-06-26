-- Usage:
-- This command copies the name of the current active buffer (the filename without its path)
-- to your system clipboard.
--
-- How to use:
-- 1. Ensure you have a file open in Neovim.
-- 2. Run the command: :CopyBufferName
-- 3. The filename is now in your clipboard and can be pasted elsewhere.

-- Copy current buffer name (filename only) to clipboard
vim.api.nvim_create_user_command(
  'CopyBufferName',  -- Command name (e.g., :CopyBufferName)
  function()
    local filename = vim.fn.expand('%:t') -- Get the filename only (tail of the path)
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
    print("Buffer name copied to clipboard: " .. filename)
  end,
  {
    desc = 'Copy current buffer name to clipboard', -- Command description for which-key, etc.
    nargs = 0, -- Takes no arguments
  }
)
