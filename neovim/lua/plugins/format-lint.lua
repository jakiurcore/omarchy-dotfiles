-- lua/plugins/format-lint.lua
return {
    -- Formatter
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        opts = {
            format_on_save = { timeout_ms = 1000, lsp_fallback = true },
            formatters_by_ft = {
                lua = { "stylua" },
                javascript = { "prettierd", "prettier" },
                typescript = { "prettierd", "prettier" },
                javascriptreact = { "prettierd", "prettier" },
                typescriptreact = { "prettierd", "prettier" },
                json = { "prettierd", "prettier" },
                html = { "prettierd", "prettier" },
                css = { "prettierd", "prettier" },
                scss = { "prettierd", "prettier" },
                markdown = { "prettierd", "prettier" },
                yaml = { "prettierd", "prettier" },
                toml = { "taplo" },
                sh = { "shfmt" },
                php = { "pint" },
                go = { "gofumpt" },
                c = { "clang-format" },
                cpp = { "clang-format" },
                python = { "ruff", "black" },
                blade = { "blade-formatter" },
            },
            formatters = {
                ["clang-format"] = {
                    -- clang-format's own default (no .clang-format found) is
                    -- the LLVM style, which is 2-space indent — that silently
                    -- overwrote 4-space code on every save. Only fall back to
                    -- a 4-space style (matching options.lua's tabstop/
                    -- shiftwidth) when no project .clang-format exists;
                    -- a project-level .clang-format still wins as-is.
                    args = function(self, ctx)
                        local has_project_style = #vim.fs.find(".clang-format", { path = ctx.dirname, upward = true }) > 0
                        if has_project_style then
                            return { "-assume-filename", "$FILENAME" }
                        end
                        return {
                            "-assume-filename",
                            "$FILENAME",
                            "--style={BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4, UseTab: Never}",
                        }
                    end,
                },
            },
        },
        config = function(_, opts)
            require("conform").setup(opts)
            -- optional: keymap to format
            vim.keymap.set({ "n", "v" }, "<leader>fm", function()
                require("conform").format({ async = true, lsp_fallback = true })
            end, { desc = "Format buffer" })
        end,
    },

    -- Linter
    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPost", "BufWritePost", "InsertLeave" },
        config = function()
            local lint = require("lint")
            lint.linters_by_ft = {
                javascript = { "eslint_d" },
                typescript = { "eslint_d" },
                javascriptreact = { "eslint_d" },
                typescriptreact = { "eslint_d" },
                markdown = { "markdownlint" },
                yaml = { "yamllint" },
                dockerfile = { "hadolint" },
                sh = { "shellcheck" },
                python = { "ruff" },
                -- php = { "pint" },
                go = { "golangcilint" },
            }
            vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
                callback = function()
                    require("lint").try_lint()
                end,
            })
            vim.keymap.set("n", "<leader>ll", function()
                require("lint").try_lint()
            end, { desc = "Lint now" })
        end,
    },
}
