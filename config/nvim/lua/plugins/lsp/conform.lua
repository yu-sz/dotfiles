-- formatter settings
return {
	"stevearc/conform.nvim",
	event = "VeryLazy",
	opts = function()
		local web_formatter_config = function()
			return { "biome-check", "prettier", stop_after_first = true }
		end

		return {
			format_on_save = {
				timeout_ms = 1500,
				lsp_fallback = true,
			},
			formatters_by_ft = {
				lua = { "stylua" },
				bash = { "shfmt" },
				typescript = web_formatter_config,
				javascript = web_formatter_config,
				typescriptreact = web_formatter_config,
				javascriptreact = web_formatter_config,
				html = web_formatter_config,
				css = web_formatter_config,
				scss = web_formatter_config,
				less = web_formatter_config,
				json = web_formatter_config,
				jsonc = web_formatter_config,
				yaml = { "prettier" },
				markdown = { "prettier" },
			},
			formatters = {
				stylua = {
					command = "stylua", -- 固定パスを削除
				},
				shfmt = {
					command = "shfmt", -- 固定パスを削除
				},
				["biome-check"] = {
					command = "biome", -- 固定パスを削除 (Masonは 'biome' と表示しているのでこれに合わせる)
					args = { "format", "--stdin-file-path", "$FILENAME", "-" },
					stdin = true,
				},
				prettier = {
					command = "prettier", -- 固定パスを削除
					args = { "--stdin-filepath", "$FILENAME" },
					stdin = true,
				},
			},
		}
	end,
	config = function(_, opts)
		local conform = require("conform")
		conform.setup(opts)
		vim.keymap.set({ "n", "v" }, "<leader>lF", function()
			conform.format({
				lsp_fallback = true,
				async = false,
				timeout_ms = 500,
			})
		end, { desc = "Format file or range (in visual mode)" })
	end,
}
