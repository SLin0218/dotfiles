return {
	{
		"neovim/nvim-lspconfig",
		config = function()
			require("nvchad.configs.lspconfig").defaults()
			require("configs.lspconfig")
		end,
		cond = not vim.g.vscode,
	},
	{
		"stevearc/conform.nvim",
		opts = require("configs.conform"),
		cond = not vim.g.vscode,
	},
	{
		"mg979/vim-visual-multi",
		init = function()
			vim.g.VM_maps = {
				["Find Under"] = "<M-n>",
				["Find Subword Under"] = "<M-n>",
			}
		end,
		lazy = false,
	},
	-- 高亮结尾空格
	{ "ntpeters/vim-better-whitespace", lazy = false, cond = not vim.g.vscode },
	{ "williamboman/mason.nvim", cond = not vim.g.vscode },
	{ "mfussenegger/nvim-jdtls", cond = not vim.g.vscode },
	{ "slin0218/nvim-class", lazy = false, cond = not vim.g.vscode },
	{
		"mikesmithgh/kitty-scrollback.nvim",
		enabled = true,
		lazy = true,
		cmd = {
			"KittyScrollbackGenerateKittens",
			"KittyScrollbackCheckHealth",
			"KittyScrollbackGenerateCommandLineEditing",
		},
		event = { "User KittyScrollbackLaunch" },
		-- version = '*', -- latest stable version, may have breaking changes if major version changed
		-- version = '^6.0.0', -- pin major version, include fixes and features that do not have breaking changes
		config = function()
			require("kitty-scrollback").setup()
		end,
		cond = not vim.g.vscode,
	},
	{
		"kevinhwang91/nvim-ufo",
		dependencies = "kevinhwang91/promise-async",
		event = "BufReadPost",
		config = function()
			local handler = function(virtText, lnum, endLnum, width, truncate)
				local newVirtText = {}
				local suffix = (" 󰁂 %d "):format(endLnum - lnum)
				local sufWidth = vim.fn.strdisplaywidth(suffix)
				local targetWidth = width - sufWidth
				local curWidth = 0
				for _, chunk in ipairs(virtText) do
					local chunkText = chunk[1]
					local chunkWidth = vim.fn.strdisplaywidth(chunkText)
					if targetWidth > curWidth + chunkWidth then
						table.insert(newVirtText, chunk)
					else
						chunkText = truncate(chunkText, targetWidth - curWidth)
						local hlGroup = chunk[2]
						table.insert(newVirtText, { chunkText, hlGroup })
						chunkWidth = vim.fn.strdisplaywidth(chunkText)
						-- str width returned from truncate() may less than 2nd argument, need padding
						if curWidth + chunkWidth < targetWidth then
							suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
						end
						break
					end
					curWidth = curWidth + chunkWidth
				end
				table.insert(newVirtText, { suffix, "MoreMsg" })
				return newVirtText
			end
			vim.o.fillchars = "eob: ,fold: ,foldopen:,foldsep: ,foldinner: ,foldclose:"
			vim.o.foldlevel = 99
			vim.o.foldlevelstart = 99
			vim.o.foldcolumn = "1"
			require("ufo").setup({
				fold_virt_text_handler = handler,
				provider_selector = function()
					return { "treesitter", "indent" }
				end,
			})
		end,
	},
	{
		"cap153/peek.nvim",
		event = { "VeryLazy" },
		build = "deno task --quiet build:fast",
		config = function()
			local peek = require("peek")
			peek.setup({
				port = 12345,
				app = { "kitty", "@", "launch", "--dont-take-focus", "--bias", "40", "awrit http://localhost:12345" },
			})
			vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
			vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
		end,
	},
	-- 避免被卸载
	{ "nvim-lua/plenary.nvim", cond = not vim.g.vscode },
	{ "nvchad/base46", cond = not vim.g.vscode },
	{ "nvchad/ui", cond = not vim.g.vscode },
	{ "nvzone/volt", cond = not vim.g.vscode },
	{ "nvzone/menu", cond = not vim.g.vscode },
	{ "nvzone/minty", cond = not vim.g.vscode },
	{ "nvim-tree/nvim-web-devicons", cond = not vim.g.vscode },
	{ "lukas-reineke/indent-blankline.nvim", cond = not vim.g.vscode },
	{ "nvim-tree/nvim-tree.lua", cond = not vim.g.vscode },
	{ "folke/which-key.nvim", cond = not vim.g.vscode },
	{ "stevearc/conform.nvim", cond = not vim.g.vscode },
	{ "lewis6991/gitsigns.nvim", cond = not vim.g.vscode },
	{ "mason-org/mason.nvim", cond = not vim.g.vscode },
	{ "neovim/nvim-lspconfig", cond = not vim.g.vscode },
	{ "hrsh7th/nvim-cmp", cond = not vim.g.vscode },
	{ "windwp/nvim-autopairs", cond = not vim.g.vscode },
	{ "nvim-telescope/telescope.nvim", cond = not vim.g.vscode },
	{
		"nvim-treesitter/nvim-treesitter",
		cond = not vim.g.vscode,
		ensure_installed = {
			"lua",
			"vim",
			"vimdoc",
			"query",
			"typescript",
			"javascript",
			"tsx",
			"html",
			"css",
			"c",
			"cpp",
			"go",
			"python",
			"rust",
			"sql",
		},
	},
	{ "saadparwaiz1/cmp_luasnip", cond = not vim.g.vscode },
	{ "NvChad/NvChad", cond = not vim.g.vscode },
	{ "hrsh7th/cmp-nvim-lua", cond = not vim.g.vscode },
	{ "hrsh7th/cmp-nvim-lsp", cond = not vim.g.vscode },
	{ "hrsh7th/cmp-buffer", cond = not vim.g.vscode },
	{ "hrsh7th/cmp-path", cond = not vim.g.vscode },
	{ "rafamadriz/friendly-snippets", cond = not vim.g.vscode },
	{ "L3MON4D3/LuaSnip", cond = not vim.g.vscode },
}
