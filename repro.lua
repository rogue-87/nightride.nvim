vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.o.tabstop = 4
vim.o.shiftwidth = 4

-- Run with `nvim -u repro.lua`
vim.env.LAZY_STDPATH = ".repro"
---@diagnostic disable-next-line: need-check-nil
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

---@diagnostic disable-next-line: missing-fields
require("lazy.minit").repro({
	spec = {
		{
			"nightride.nvim",
			lazy = false,
			dir = vim.fn.getcwd(),
			dev = true,
			config = function()
				require("nightride").setup({
					player = "auto",
					default_station = "nightride",
					default_volume = 50,
					volume_step = 10,
					keymaps = {
						toggle = "<leader>np",
						volume_up = "<leader>n+",
						volume_down = "<leader>n-",
					},
				})
			end,
			keys = {
				{ "<leader>np", "<cmd>Nightride toggle<cr>", desc = "Nightride: Toggle" },
				{
					"<leader>n+",
					"<cmd>Nightride volume " .. (vim.g.nightride_volume or 50) + 10 .. "<cr>",
					desc = "Nightride: Volume Up",
				},
				{
					"<leader>n-",
					"<cmd>Nightride volume " .. math.max(0, (vim.g.nightride_volume or 50) - 10) .. "<cr>",
					desc = "Nightride: Volume Down",
				},
			},
		},
		{
			"nvim-lualine/lualine.nvim",
			event = "VeryLazy",
			config = function()
				local statusline = require("nightride.statusline")
				statusline.setup()

				require("lualine").setup({
					options = {
						theme = "auto",
					},
					sections = {
						lualine_c = {
							statusline.component,
						},
					},
				})
			end,
		},
	},
})
