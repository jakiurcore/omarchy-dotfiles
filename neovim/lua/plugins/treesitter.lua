-- lua/plugins/treesitter.lua
return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false, -- main does not support lazy-loading
	build = ":TSUpdate",
	config = function()
		local ensure = {
			"bash",
			"javascript",
			"typescript",
			"tsx",
			"json",
			"html",
			"css",
			"scss",
			"php",
			"python",
			"rust",
			"cpp",
			"go",
			"yaml",
			"toml",
			"dockerfile",
			"regex",
		}
		local installed = require("nvim-treesitter.config").get_installed()
		local missing = vim.tbl_filter(function(p)
			return not vim.tbl_contains(installed, p)
		end, ensure)
		if #missing > 0 then
			require("nvim-treesitter").install(missing)
		end

		vim.api.nvim_create_autocmd("FileType", {
			callback = function()
				if not pcall(vim.treesitter.start) then
					return
				end
				vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end,
		})
	end,
}
