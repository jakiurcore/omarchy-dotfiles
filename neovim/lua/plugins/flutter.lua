-- lua/plugins/flutter.lua
return {
    "akinsho/flutter-tools.nvim",
    ft = "dart",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "mfussenegger/nvim-dap",
    },
    config = function()
        require("flutter-tools").setup({
            widget_guides = { enabled = true },
            closing_tags = { highlight = "Comment", prefix = "// " },
            dev_log = { enabled = true, open_cmd = "tabedit" },
            dev_tools = { autostart = false, auto_open_browser = false },
            debugger = { enabled = true, run_via_dap = true },
            lsp = {
                on_attach = function(_, bufnr)
                    local opts = { buffer = bufnr, silent = true }
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
                    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
                    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
                end,
                settings = {
                    showTodos = true,
                    completeFunctionCalls = true,
                },
            },
        })

        vim.keymap.set("n", "<leader>fr", "<cmd>FlutterRun<CR>", { desc = "Flutter run" })
        vim.keymap.set("n", "<leader>fR", "<cmd>FlutterRestart<CR>", { desc = "Flutter hot restart" })
        vim.keymap.set("n", "<leader>fq", "<cmd>FlutterQuit<CR>", { desc = "Flutter quit" })
        vim.keymap.set("n", "<leader>fd", "<cmd>FlutterDevices<CR>", { desc = "Flutter devices" })
        vim.keymap.set("n", "<leader>fe", "<cmd>FlutterEmulators<CR>", { desc = "Flutter emulators" })
        vim.keymap.set("n", "<leader>fo", "<cmd>FlutterOutlineToggle<CR>", { desc = "Flutter outline" })
    end,
}
