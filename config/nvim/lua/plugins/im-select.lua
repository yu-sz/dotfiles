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
    -- FocusGained: 他アプリ/ペインで日本語入力したままノーマルモードに戻るケースを補足
    set_default_events = { "VimEnter", "FocusGained", "InsertLeave", "CmdlineLeave" },
    -- 以下のイベント時に、前回使われていたIMEになる
    set_previous_events = { "InsertEnter" },
  },
}
