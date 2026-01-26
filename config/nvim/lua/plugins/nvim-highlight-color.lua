-- realtime color highlighting
return {
  "brenoprata10/nvim-highlight-colors",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    -- @usage 'background'|'foreground'|'virtual'
    render = "background",
    enable_tailwind = true,
  },
}
