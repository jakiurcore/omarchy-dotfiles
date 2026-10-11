return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
    },
    config = function()
        require("neo-tree").setup({
            close_if_last_window = true,
            filesystem = {
                follow_current_file = { enabled = true },
                filtered_items = {
                    visible = true,
                    show_hidden = true,
                },
            },
            default_component_configs = {
                indent = { indent_size = 2, padding = 1 },
                icon = {
                    folder_closed = "",
                    folder_open = "",
                    folder_empty = "",
                    folder_empty_open = "",
                    -- fallback only when devicons has no match for a file
                    default = "",
                },
                modified = { symbol = "" },
                git_status = {
                    symbols = {
                        added = "",
                        modified = "",
                        deleted = "",
                        renamed = "",
                        untracked = "󰓎",
                        ignored = "",
                        unstaged = "",
                        staged = "",
                        conflict = "󰀦",
                    },
                },
            },
            event_handlers = {
                {
                    event = "file_opened",
                    handler = function(file_path)
                        require("neo-tree.command").execute({ action = "close" })
                    end,
                },
            },
        })

        vim.keymap.set("n", "<leader>e", ":Neotree toggle left<CR>", {
            desc = "Toggle File Explorer",
        })

        -- Neo-tree's own close_if_last_window WinClosed autocmd (plugin/neo-tree.lua)
        -- reads vim.b[buf].neo_tree_source and passes it straight into
        -- sources.manager.get_state(), which asserts it's non-nil. That buffer var
        -- can be unset on a neo-tree buffer when some other plugin's nui.nvim popup
        -- (e.g. noice.nvim) closes and fires this "*" autocmd, crashing it. Guard
        -- here instead of patching the vendored file, which `:Lazy update` wipes.
        local manager = require("neo-tree.sources.manager")
        local get_state = manager.get_state
        manager.get_state = function(source_name, ...)
            if not source_name then
                return nil
            end
            return get_state(source_name, ...)
        end
    end,
}
