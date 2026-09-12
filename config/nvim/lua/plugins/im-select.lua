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
    -- FocusGained は入れない。日本語変換中に入力ソースを奪って未確定文字列を壊すうえ、
    -- InsertLeave 直後に発火すると復帰用の保存値が ABC で上書きされ、英数しか入らなくなる
    set_default_events = { "VimEnter", "InsertLeave", "CmdlineLeave" },
    -- 以下のイベント時に、前回使われていたIMEになる
    set_previous_events = { "InsertEnter" },
  },
}
