-- lua/plugins/markdown-preview.lua
-- Live-reloading, real-browser markdown preview (proper GFM rendering: code
-- block syntax highlighting, tables, etc.) — complements render-markdown.nvim,
-- which renders markdown in-buffer but can't fully replicate real HTML output.
return {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    ft = { "markdown" },
    -- The mkdp#util#install() Vimscript function isn't reliably resolvable
    -- here since this plugin is ft/cmd-lazy-loaded (its autoload/ isn't on
    -- the runtimepath yet when Lazy runs the build step) - call npm directly.
    build = "cd app && npm install",
    init = function()
        vim.g.mkdp_filetypes = { "markdown" }
        vim.g.mkdp_auto_close = false -- keep the browser tab open when switching buffers
        vim.g.mkdp_refresh_slow = false -- live-reload on every edit, not just on save
        vim.g.mkdp_theme = "dark"
    end,
    keys = {
        { "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", desc = "Markdown preview (browser)" },
    },
}
