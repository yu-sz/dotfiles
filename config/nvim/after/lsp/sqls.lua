---@type vim.lsp.Config
return {
  -- settings に直接書くと vim.lsp.enable の config 解決 (起動時) に catalog 読み込みが
  -- 走るため、before_init (クライアント初回起動時) で注入して真に遅延させる。
  -- client.settings はクライアント構築時に config.settings の参照を取るため、
  -- テーブルの置き換えではなく in-place で書き込むこと
  settings = { sqls = {} },
  before_init = function(_, config)
    config.settings.sqls.connections = require("db.catalog").sqls_connections()
  end,
}
