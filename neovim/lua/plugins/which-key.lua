-- lua/plugins/which-key.lua
return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        delay = 500,
        icons = { mappings = true },
        spec = {
            { "<leader>f", group = "find" },
            { "<leader>h", group = "git hunks" },
            { "<leader>r", group = "rename/refactor" },
            { "<leader>c", group = "code action" },
        },
    },
}
