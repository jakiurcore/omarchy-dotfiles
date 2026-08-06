-- lua/plugins/floaterm.lua
return {
    "voldikss/vim-floaterm",
    cmd = { "FloatermToggle", "FloatermNew", "FloatermNext", "FloatermPrev" },
    init = function()
        -- Window look
        vim.g.floaterm_width = 0.7
        vim.g.floaterm_height = 0.5
        vim.g.floaterm_borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
        -- We draw our own kitty-style tab bar in the winbar, so the border
        -- title is redundant. Leave it empty.
        vim.g.floaterm_title = ""
        vim.g.floaterm_titleposition = "center"
    end,
    keys = function()
        local K = {}
        -- helper to make mappings work from both normal & terminal mode
        local function map_bimode(lhs, rhs, desc)
            table.insert(K, { lhs, rhs, desc = desc, mode = "n" })
            table.insert(K, { lhs, ([[<C-\><C-n>]] .. rhs), desc = desc, mode = "t" })
        end

        map_bimode("<leader>tt", "<cmd>FloatermToggle<CR>", "Toggle terminal")
        map_bimode("<leader>tn", "<cmd>FloatermNew<CR>", "New terminal")

        -- kitty-like tab switching
        map_bimode("<leader>t]", "<cmd>FloatermNext<CR>", "Next terminal")
        map_bimode("<leader>t[", "<cmd>FloatermPrev<CR>", "Prev terminal")
        map_bimode("<leader>tx", "<cmd>FloatermKill<CR>", "Kill terminal")

        -- t1..t9 → jump straight to the Nth terminal
        for i = 1, 9 do
            local lhs = string.format("<leader>t%d", i)
            local rhs = string.format("<cmd>%dFloatermToggle<CR>", i)
            map_bimode(lhs, rhs, string.format("Terminal #%d", i))
        end
        return K
    end,
    config = function()
        -- ---- kitty-style tab bar ------------------------------------------

        -- highlight groups (re-linked whenever the colorscheme changes)
        local function set_hl()
            vim.api.nvim_set_hl(0, "FloatermTabActive", { link = "TabLineSel", default = true })
            vim.api.nvim_set_hl(0, "FloatermTabInactive", { link = "TabLine", default = true })
            vim.api.nvim_set_hl(0, "FloatermTabFill", { link = "TabLineFill", default = true })
        end
        set_hl()
        vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })

        -- which buffer is the winbar being drawn for
        local function which_buf()
            local win = vim.g.statusline_winid
            if win and win ~= 0 and vim.api.nvim_win_is_valid(win) then
                return vim.api.nvim_win_get_buf(win)
            end
            return vim.api.nvim_get_current_buf()
        end

        local function label_for(_, index)
            return string.format(" %d ", index)
        end

        -- global so the winbar expression can reach it
        function _G.__floaterm_tabline()
            local ok, buflist = pcall(vim.fn["floaterm#buflist#gather"])
            if not ok or type(buflist) ~= "table" or #buflist == 0 then
                return ""
            end
            local cur = which_buf()
            local out = {}
            for i, bufnr in ipairs(buflist) do
                local grp = (bufnr == cur) and "FloatermTabActive" or "FloatermTabInactive"
                out[#out + 1] = string.format("%%#%s#%s", grp, label_for(bufnr, i))
            end
            out[#out + 1] = "%#FloatermTabFill#" -- fill the rest of the width
            return table.concat(out)
        end

        -- attach the tab bar to floaterm windows (on create and on buffer swap)
        local grp = vim.api.nvim_create_augroup("FloatermKittyTabs", { clear = true })
        local function attach()
            vim.opt_local.winbar = "%{%v:lua.__floaterm_tabline()%}"
        end
        vim.api.nvim_create_autocmd("FileType", {
            group = grp,
            pattern = "floaterm",
            callback = attach,
        })
        vim.api.nvim_create_autocmd("BufWinEnter", {
            group = grp,
            callback = function(a)
                if vim.bo[a.buf].filetype == "floaterm" then
                    attach()
                end
            end,
        })
    end,
}
