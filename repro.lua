vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.o.tabstop = 4
vim.o.shiftwidth = 4

-- Run with `nvim -u repro.lua`
vim.env.LAZY_STDPATH = ".repro"
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
				require('nightride').setup({
					-- Test configuration
					player = 'auto',
					default_station = 'nightride',
					default_volume = 50,
					volume_step = 10,
					statusline = {
						enabled = true,
						format = '♪ [%s] %d%%',
					},
					keymaps = {
						toggle = '<leader>np',
						select = '<leader>ns',
						volume_up = '<leader>n+',
						volume_down = '<leader>n-',
					}
				})
				
				-- Show some helpful info
				vim.notify('nightride.nvim loaded! Try :Nightride select to get started', vim.log.levels.INFO)
			end,
			keys = {
				{ "<leader>np", "<cmd>Nightride toggle<cr>", desc = "Nightride: Toggle" },
				{ "<leader>ns", "<cmd>Nightride select<cr>", desc = "Nightride: Select Station" },
				{ "<leader>n+", "<cmd>Nightride volume " .. (vim.g.nightride_volume or 50) + 10 .. "<cr>", desc = "Nightride: Volume Up" },
				{ "<leader>n-", "<cmd>Nightride volume " .. math.max(0, (vim.g.nightride_volume or 50) - 10) .. "<cr>", desc = "Nightride: Volume Down" },
			},
		},
		-- Add snacks.nvim for enhanced picker UI
		{
			"folke/snacks.nvim",
			priority = 1000,
			lazy = false,
			config = function()
				require("snacks").setup({
					picker = { enabled = true },
					notifier = { enabled = true },
				})
			end
		},
		-- Add lualine for status line testing
		{
			"nvim-lualine/lualine.nvim",
			dependencies = { "nvim-tree/nvim-web-devicons" },
			config = function()
				require('lualine').setup({
					options = {
						theme = 'auto',
						component_separators = { left = '', right = ''},
						section_separators = { left = '', right = ''},
					},
					sections = {
						lualine_a = {'mode'},
						lualine_b = {'branch', 'diff', 'diagnostics'},
						lualine_c = {'filename'},
						lualine_x = {
							require('nightride').lualine_component(),
							'encoding', 
							'fileformat', 
							'filetype'
						},
						lualine_y = {'progress'},
						lualine_z = {'location'}
					},
				})
			end
		}
	},
})
