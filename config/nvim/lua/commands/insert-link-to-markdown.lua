-- Usage:
-- 1. Copy a URL to your clipboard.
-- 2. In a Markdown file, visually select the text you want to make a link.
-- 3. Press 'p' (paste) to transform the selected text into a Markdown link.

function InsertMarkdownLink()
  -- Save register 9 temporarily
  local old = vim.fn.getreg("9")

  -- Get URL from clipboard
  local clipboard_text = vim.fn.getreg("+")

  -- Check if clipboard content is a URL
  if clipboard_text:match("^https?://") then
    -- Yank the visual selection into register 9
    vim.cmd('normal! gv"9y')

    -- Get the selected text from register 9
    local word = vim.fn.getreg("9")

    -- Format as Markdown link
    local new_text = string.format("[%s](%s)", word, clipboard_text)

    -- Set the formatted text to register 9
    vim.fn.setreg("9", new_text)

    -- Return to visual mode and paste to replace the selection with the link
    vim.cmd('normal! gv"9p')

    -- Restore original register 9 content
    vim.fn.setreg("9", old)
  end
end

vim.api.nvim_create_augroup("markdown_insert_link", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  group = "markdown_insert_link",
  callback = function()
    vim.api.nvim_buf_set_keymap(
      0,
      "v",
      "p",
      ":<C-u>lua InsertMarkdownLink()<CR>",
      { noremap = true, silent = true }
    )
  end,
})
