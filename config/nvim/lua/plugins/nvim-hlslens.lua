-- improve text search
return {
  "kevinhwang91/nvim-hlslens",
  event = { "BufNewFile", "BufRead" },
  dependencies = {
    "rapan931/lasterisk.nvim",
  },
  config = function()
    require("scrollbar.handlers.search").setup({
      override_lens = function(render, posList, nearest, idx)
        local text, chunks
        ---@diagnostic disable-next-line: deprecated
        local lnum, col = unpack(posList[idx])
        local cnt = #posList
        text = ("[%d/%d]"):format(idx, cnt)
        if nearest then
          chunks = { { " ", "Ignore" }, { text, "HlSearchLensNear" } }
        else
          chunks = { { " ", "Ignore" }, { text, "HlSearchLens" } }
        end
        render.setVirt(0, lnum - 1, col - 1, chunks, nearest)
      end,
    })
    local kopts = { silent = true }

    vim.keymap.set(
      "n",
      "n",
      [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
      kopts
    )
    vim.keymap.set(
      "n",
      "N",
      [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
      kopts
    )

    vim.keymap.set("n", "*", function()
      require("lasterisk").search()
      require("hlslens").start()
    end)
    -- g* は lasterisk 版に一本化（部分一致検索 + lens 表示）
    vim.keymap.set({ "n", "x" }, "g*", function()
      require("lasterisk").search({ is_whole = false, silent = true })
      require("hlslens").start()
    end)

    vim.keymap.set("n", "#", [[#<Cmd>lua require('hlslens').start()<CR>]], kopts)
    vim.keymap.set("n", "g#", [[g#<Cmd>lua require('hlslens').start()<CR>]], kopts)

    vim.cmd([[
        highlight HlSearchLensNear guifg=white guibg=olive
        highlight HlSearchLens guifg=#777777 guibg=#FFFFFF
      ]])
  end,
}
