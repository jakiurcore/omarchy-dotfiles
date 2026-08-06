return {
    "ajdm-jakiur/fleury.nvim",
    lazy = false, -- load during startup, not on demand
    priority = 1000, -- load before other plugins so highlights aren't overridden
    config = function()
        vim.o.termguicolors = true
        vim.cmd.colorscheme("fleury")
    end,
}
