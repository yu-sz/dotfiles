local section_gap = require("helpers.section_gap")

-- 左: Apple メニュー
require("items.apple")("left")
section_gap.add("section.gap.left1", "left")
-- 左: ワークスペース (aerospace モード + spaces)
require("items.mode")("left")
require("items.spaces")("left")
section_gap.add("section.gap.left2", "left")
-- 左: tmux セッション
require("items.tmux")("left")

-- 右: 日時
require("items.date")("right")
section_gap.add("section.gap.right1", "right", 12)
-- 右: ステータス (status.bracket)
require("items.battery")("right")
require("items.volume")("right")
require("items.input")("right")
section_gap.add("section.gap.right2", "right")
-- 右: システムメトリクス (metrics.bracket)
require("items.network")("right")
require("items.memory")("right")
require("items.cpu")("right")

-- 右側ブラケット定義 (status.bracket / metrics.bracket)
require("items.right")()
