-- lua/plugins/todo-comments.lua
return {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "Todo list (Trouble)" },
        {
            "]t",
            function()
                require("todo-comments").jump_next()
            end,
            desc = "Next TODO",
        },
        {
            "[t",
            function()
                require("todo-comments").jump_prev()
            end,
            desc = "Prev TODO",
        },
    },
    opts = {},
}
