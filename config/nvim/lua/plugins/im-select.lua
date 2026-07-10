-- ime control
return {
  "keaising/im-select.nvim",
  -- VimEnter での IME リセットを効かせるため意図的に eager load
  lazy = false,
  main = "im_select",
  opts = {
    -- デフォルトのIME
    default_im_select = "com.apple.keylayout.ABC",
    -- command
    default_command = "macism",
    -- 以下のイベント時に、デフォルトのIMEになる
    set_default_events = { "VimEnter", "InsertEnter", "InsertLeave" },
    -- 以下のイベント時に、前回使われていたIMEになる（無効にしている）
    set_previous_events = {},
  },
}
