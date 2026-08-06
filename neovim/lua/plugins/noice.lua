return {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
        lsp = {
            progress = { enabled = true },
        },
        routes = {
            {
                filter = { event = "msg_show", find = "written" },
                view = "mini", -- save messages become a quiet corner note
            },
        },
    },
    dependencies = {
        "MunifTanjim/nui.nvim",
        {
            "rcarriga/nvim-notify",
            on_open = function(win)
                vim.api.nvim_win_set_config(win, { border = "rounded" })
                vim.wo[win].winblend = 10
            end,
            config = function()
                require("notify").setup({
                    background_colour = "#000000",
                    stages = "fade_in_slide_out",
                    render = "wrapped-compact",
                    timeout = 3000,
                    fps = 60,
                    icons = {
                        ERROR = "",
                        WARN = "",
                        INFO = "",
                        DEBUG = "",
                        TRACE = "",
                    },
                })
                local function set_notify_hl()
                    local hl = vim.api.nvim_set_hl
                    hl(0, "NotifyERRORBody", { bg = "NONE" })
                    hl(0, "NotifyWARNBody", { bg = "NONE" })
                    hl(0, "NotifyINFOBody", { bg = "NONE" })
                    hl(0, "NotifyDEBUGBody", { bg = "NONE" })
                    hl(0, "NotifyTRACEBody", { bg = "NONE" })

                    hl(0, "NotifyERRORBorder", { fg = "#f7768e", bg = "NONE" })
                    hl(0, "NotifyERRORIcon", { fg = "#f7768e" })
                    hl(0, "NotifyERRORTitle", { fg = "#f7768e", bold = true })

                    hl(0, "NotifyWARNBorder", { fg = "#e0af68", bg = "NONE" })
                    hl(0, "NotifyWARNIcon", { fg = "#e0af68" })
                    hl(0, "NotifyWARNTitle", { fg = "#e0af68", bold = true })

                    hl(0, "NotifyINFOBorder", { fg = "#7aa2f7", bg = "NONE" })
                    hl(0, "NotifyINFOIcon", { fg = "#7aa2f7" })
                    hl(0, "NotifyINFOTitle", { fg = "#7aa2f7", bold = true })

                    hl(0, "NotifyDEBUGBorder", { fg = "#565f89", bg = "NONE" })
                    hl(0, "NotifyDEBUGIcon", { fg = "#565f89" })
                    hl(0, "NotifyDEBUGTitle", { fg = "#565f89", bold = true })

                    hl(0, "NotifyTRACEBorder", { fg = "#9ece6a", bg = "NONE" })
                    hl(0, "NotifyTRACEIcon", { fg = "#9ece6a" })
                    hl(0, "NotifyTRACETitle", { fg = "#9ece6a", bold = true })
                end

                set_notify_hl()
                vim.api.nvim_create_autocmd("ColorScheme", { callback = set_notify_hl })
            end,
        },
    },
}
