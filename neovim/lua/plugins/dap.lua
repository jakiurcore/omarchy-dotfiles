-- lua/plugins/dap.lua
return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
        "theHamsta/nvim-dap-virtual-text", -- inline variable values next to code while debugging
    },
    config = function()
        local dap = require("dap")
        local dapui = require("dapui")

        -- ---- breakpoint/stopped-line signs -------------------------------
        -- Linked to the same Diagnostic* highlights LSP signs already use, so
        -- they stay consistent across catppuccin/rose-pine/tokyonight/fleury
        -- instead of hardcoding colors that might clash with one of them.
        local function set_dap_highlights()
            vim.api.nvim_set_hl(0, "DapBreakpoint", { link = "DiagnosticSignError", default = true })
            vim.api.nvim_set_hl(0, "DapBreakpointCondition", { link = "DiagnosticSignWarn", default = true })
            vim.api.nvim_set_hl(0, "DapLogPoint", { link = "DiagnosticSignInfo", default = true })
            vim.api.nvim_set_hl(0, "DapStopped", { link = "DiagnosticSignHint", default = true })
            vim.api.nvim_set_hl(0, "DapBreakpointRejected", { link = "Comment", default = true })
            vim.api.nvim_set_hl(0, "DapStoppedLine", { link = "ColorColumn", default = true })
        end
        set_dap_highlights()
        vim.api.nvim_create_autocmd("ColorScheme", { callback = set_dap_highlights })

        vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint" })
        vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DapBreakpointCondition" })
        vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DapLogPoint" })
        vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DapStopped", linehl = "DapStoppedLine" })
        vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DapBreakpointRejected" })

        -- ---- inline variable values ---------------------------------------
        require("nvim-dap-virtual-text").setup({
            enabled = true,
            highlight_changed_variables = true,
            show_stop_reason = true,
        })

        -- ---- dap-ui: sidebar (variables/watches/breakpoints/stacks) +
        -- bottom panel (console/repl), rounded floats to match the rest of
        -- this config (Mason/LSP already use border = "rounded").
        --
        -- "console" (not "repl") is the debuggee's actual terminal — that's
        -- where a program's cin/scanf input goes and its printf/cout output
        -- appears. "repl" is a separate lldb command line (evaluate
        -- expressions, run raw lldb commands) - typing program input there
        -- gets read as an lldb command and rejected. Console is listed first
        -- and bigger here specifically so it's the one you land on.
        dapui.setup({
            icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
            controls = {
                enabled = true,
                element = "console",
                icons = {
                    pause = "⏸",
                    play = "▶",
                    step_into = "⏎",
                    step_over = "⏭",
                    step_out = "⏮",
                    step_back = "b",
                    run_last = "▶▶",
                    terminate = "⏹",
                    disconnect = "⏏",
                },
            },
            floating = {
                border = "rounded",
                mappings = { close = { "q", "<Esc>" } },
            },
            layouts = {
                {
                    elements = {
                        { id = "scopes", size = 0.35 },
                        { id = "breakpoints", size = 0.25 },
                        { id = "watches", size = 0.25 },
                        { id = "stacks", size = 0.15 },
                    },
                    size = 45,
                    position = "left",
                },
                {
                    elements = {
                        { id = "console", size = 0.6 },
                        { id = "repl", size = 0.4 },
                    },
                    size = 12,
                    position = "bottom",
                },
            },
        })

        dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
        end
        dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
        end
        dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
        end

        -- ---- keymaps --------------------------------------------------------
        local widgets = require("dap.ui.widgets")

        vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
        vim.keymap.set("n", "<leader>dB", function()
            dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end, { desc = "Conditional breakpoint" })
        vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Debug continue/start" })
        vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Debug step into" })
        vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "Debug step over" })
        vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "Debug step out" })
        vim.keymap.set("n", "<leader>dp", dap.pause, { desc = "Debug pause" })
        vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Debug terminate" })
        vim.keymap.set("n", "<leader>dR", dap.run_last, { desc = "Debug restart last" })
        vim.keymap.set("n", "<leader>dh", widgets.hover, { desc = "Debug hover value" })
        vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle Dap UI" })
        vim.keymap.set("n", "<leader>dr", dap.repl.toggle, { desc = "Toggle Dap REPL" })
        vim.keymap.set("n", "<leader>dC", function()
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "dapui_console" then
                    vim.api.nvim_set_current_win(win)
                    vim.cmd("startinsert")
                    return
                end
            end
            vim.notify("No DAP Console window (start a debug session first)", vim.log.levels.WARN)
        end, { desc = "Jump to Debug Console (program stdin/stdout)" })
    end,
}
