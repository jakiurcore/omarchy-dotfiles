-- lua/plugins/indent-blankline.lua
return {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    main = "ibl",
    opts = {
        indent = { char = "│" },
        scope = { enabled = true },
        exclude = {
            filetypes = { "help", "alpha", "neo-tree", "lazy", "mason", "notify", "dashboard" },
        },
    },
}
