-- lua/plugins/smart-splits.lua
-- Navigate and resize splits so working across multiple files at once
-- (e.g. two source files side by side) is quick. Uses <A-...> since
-- <C-h/j/k/l> aren't free here (<C-j>/<C-k> already move lines up/down).
return {
    "mrjones2014/smart-splits.nvim",
    keys = {
        {
            "<A-h>",
            function()
                require("smart-splits").move_cursor_left()
            end,
            desc = "Go to left split",
        },
        {
            "<A-j>",
            function()
                require("smart-splits").move_cursor_down()
            end,
            desc = "Go to split below",
        },
        {
            "<A-k>",
            function()
                require("smart-splits").move_cursor_up()
            end,
            desc = "Go to split above",
        },
        {
            "<A-l>",
            function()
                require("smart-splits").move_cursor_right()
            end,
            desc = "Go to right split",
        },
        {
            "<A-Left>",
            function()
                require("smart-splits").resize_left()
            end,
            desc = "Resize split left",
        },
        {
            "<A-Down>",
            function()
                require("smart-splits").resize_down()
            end,
            desc = "Resize split down",
        },
        {
            "<A-Up>",
            function()
                require("smart-splits").resize_up()
            end,
            desc = "Resize split up",
        },
        {
            "<A-Right>",
            function()
                require("smart-splits").resize_right()
            end,
            desc = "Resize split right",
        },
    },
    config = function()
        require("smart-splits").setup()
    end,
}
