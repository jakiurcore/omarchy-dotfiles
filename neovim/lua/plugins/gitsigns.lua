-- lua/plugins/gitsigns.lua
return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        signs = {
            add = { text = "▎" },
            change = { text = "▎" },
            delete = { text = "󰍵" },
            topdelete = { text = "‾" },
            changedelete = { text = "▎" },
            untracked = { text = "▎" },
        },
        signs_staged = {
            add = { text = "▎" },
            change = { text = "▎" },
            delete = { text = "󰍵" },
            topdelete = { text = "‾" },
            changedelete = { text = "▎" },
        },
        signs_staged_enable = true, -- distinct signs for staged hunks
        signcolumn = true, -- always draw signs
        numhl = false, -- set true to also tint the line number
        linehl = false, -- set true to highlight the whole changed line
        word_diff = false, -- set true for inline word-level diff
        attach_to_untracked = true, -- show signs on untracked files too
        watch_gitdir = { follow_files = true },
        current_line_blame = true, -- inline blame on the current line
        current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = "eol",
            delay = 300,
            ignore_whitespace = false,
        },
        current_line_blame_formatter = "  <author>, <author_time:%Y-%m-%d> · <summary>",
        preview_config = { border = "rounded" },
        on_attach = function(bufnr)
            local gs = require("gitsigns")
            local function map(mode, l, r, desc)
                vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
            end

            -- Jump between changes
            map("n", "]c", function()
                if vim.wo.diff then
                    vim.cmd.normal({ "]c", bang = true })
                else
                    gs.nav_hunk("next")
                end
            end, "Next git change")
            map("n", "[c", function()
                if vim.wo.diff then
                    vim.cmd.normal({ "[c", bang = true })
                else
                    gs.nav_hunk("prev")
                end
            end, "Prev git change")

            -- Stage / reset
            map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
            map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
            map("v", "<leader>hs", function()
                gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
            end, "Stage selection")
            map("v", "<leader>hr", function()
                gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
            end, "Reset selection")
            map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
            map("n", "<leader>hR", gs.reset_buffer, "Reset buffer")

            -- Preview / blame / diff
            map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
            map("n", "<leader>hb", function()
                gs.blame_line({ full = true })
            end, "Blame line")
            map("n", "<leader>hB", gs.toggle_current_line_blame, "Toggle inline blame")
            map("n", "<leader>hd", gs.diffthis, "Diff against index")

            -- Hunk text object (e.g. vih, dih)
            map({ "o", "x" }, "ih", gs.select_hunk, "Select hunk")
        end,
    },
    config = function(_, opts)
        require("gitsigns").setup(opts)
    end,
}
