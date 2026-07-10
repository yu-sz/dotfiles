-- resizing vim windows
-- press keys Ctrl + E or execute :WinResizerStartResize
return {
  "simeji/winresizer",
  cmd = "WinResizerStartResize",
  keys = {
    { "<C-e>", desc = "Start window resize mode" },
  },
}
