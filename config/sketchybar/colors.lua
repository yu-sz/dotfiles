-- folke/tokyonight.nvim style=night より移植 (lua/tokyonight/colors/night.lua)
return {
  bg = 0xff1a1b26,
  bg_dark = 0xff16161e,
  bg_dark1 = 0xff0c0e14,
  bg_highlight = 0xff292e42,
  fg = 0xffc0caf5,
  fg_dark = 0xffa9b1d6,
  comment = 0xff565f89,
  blue = 0xff7aa2f7,
  cyan = 0xff7dcfff,
  magenta = 0xffbb9af7,
  green = 0xff9ece6a,
  yellow = 0xffe0af68,
  orange = 0xffff9e64,
  red = 0xfff7768e,
  purple = 0xff9d7cd8,
  transparent = 0x00000000,

  bar = {
    bg = 0xf01a1b26,
    border = 0xff292e42,
  },
  popup = {
    bg = 0xc01a1b26,
    border = 0xff7aa2f7,
  },

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then
      return color
    end
    return (color % 0x01000000) + (math.floor(alpha * 255.0) * 0x01000000)
  end,
}
