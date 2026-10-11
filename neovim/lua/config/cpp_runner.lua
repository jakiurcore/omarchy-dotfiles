-- lua/config/cpp_runner.lua
-- Shared build/run/debug logic for C and C++ buffers, wired up from
-- ftplugin/c.lua and ftplugin/cpp.lua.
local M = {}

local dap_configured = false

local function project_root()
    return vim.fs.root(0, { "Makefile", "makefile", ".git" }) or vim.fn.getcwd()
end

-- Standalone builds put the binary in a build/ folder next to the source.
local function out_path()
    return vim.fn.expand("%:p:h") .. "/build/" .. vim.fn.expand("%:t:r")
end

local function has_makefile()
    local root = project_root()
    return vim.fn.filereadable(root .. "/Makefile") == 1 or vim.fn.filereadable(root .. "/makefile") == 1
end

-- codelldb (installed via mason-tool-installer) backs debugging for C/C++.
-- Configured once, lazily, the first time a c/cpp buffer is opened.
local function setup_dap()
    if dap_configured then
        return
    end
    dap_configured = true

    local ok_registry, mason_registry = pcall(require, "mason-registry")
    if not ok_registry or not mason_registry.is_installed("codelldb") then
        return
    end
    local ok_dap, dap = pcall(require, "dap")
    if not ok_dap then
        return
    end

    local codelldb_path = mason_registry.get_package("codelldb"):get_install_path() .. "/extension/adapter/codelldb"
    dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
            command = codelldb_path,
            args = { "--port", "${port}" },
        },
    }

    local cpp_config = {
        {
            name = "Launch executable",
            type = "codelldb",
            request = "launch",
            program = function()
                -- Default to what <leader>cb/<leader>cr actually produce, so
                -- hitting Enter just works instead of launching the .cpp
                -- source file by mistake (its most common failure mode).
                local default_path = has_makefile() and (project_root() .. "/") or out_path()
                local path = vim.fn.input("Path to executable: ", default_path, "file")
                if vim.fn.filereadable(path) == 0 then
                    vim.notify("No executable at: " .. path .. " (build first with <leader>cb)", vim.log.levels.WARN)
                end
                return path
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
            args = {},
            -- codelldb's "console" mode (its default here otherwise) leaves
            -- stdin unavailable, so a program reading via cin/scanf hangs
            -- forever. "integrated" opens a real terminal split with stdin.
            terminal = "integrated",
        },
    }
    dap.configurations.c = cpp_config
    dap.configurations.cpp = cpp_config
end

-- Libraries a standalone file needs at link time. Libraries must come after
-- the source on the gcc command line. -lm is always added (math.h), and
-- raylib is added when the buffer includes raylib.h.
local function link_flags()
    local flags = { "-lm" }
    local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    if text:find("[<\"]raylib%.h[>\"]") then
        local pc = vim.fn.system("pkg-config --libs raylib 2>/dev/null")
        if vim.v.shell_error == 0 and vim.trim(pc) ~= "" then
            table.insert(flags, 1, vim.trim(pc))
        else
            table.insert(flags, 1, "-lraylib -lGL -lpthread -ldl -lrt -lX11")
        end
    end
    return table.concat(flags, " ")
end

-- Compile via `:make`, using Neovim's built-in gcc/clang errorformat so
-- errors land in the quickfix list either way:
--   - Makefile project: `make -C <root>` (explicit -C so this works no
--     matter what Neovim's own cwd happens to be).
--   - standalone file (competitive-programming style): compile just this
--     file with gcc/g++.
local function build()
    if has_makefile() then
        vim.bo.makeprg = "make -C " .. vim.fn.shellescape(project_root())
    else
        local compiler = vim.bo.filetype == "c" and "gcc" or "g++"
        local std = vim.bo.filetype == "c" and "-std=c17" or "-std=c++20"
        vim.fn.mkdir(vim.fn.expand("%:p:h") .. "/build", "p")
        vim.bo.makeprg = string.format(
            "%s %s -Wall -Wextra -g %%:S -o %s %s",
            compiler, std, vim.fn.shellescape(out_path()), link_flags()
        )
    end

    vim.cmd("silent! update")
    vim.cmd("make!")

    -- Only pop the quickfix window for genuine diagnostics; `make -C` also
    -- emits non-error "Entering/Leaving directory" lines that would
    -- otherwise trigger it on every successful build.
    local has_diagnostics = false
    for _, item in ipairs(vim.fn.getqflist()) do
        if item.valid == 1 then
            has_diagnostics = true
            break
        end
    end
    vim.cmd(has_diagnostics and "copen" or "cclose")
end

-- Build, then run in a floating terminal (vim-floaterm, already used
-- elsewhere in this config). A sibling input.txt next to a standalone file
-- is piped in automatically (the common competitive-programming test setup).
local function run()
    build()
    if vim.v.shell_error ~= 0 then
        vim.notify("Build failed - see quickfix list", vim.log.levels.ERROR)
        return
    end

    local cmd
    if has_makefile() then
        cmd = "make -C " .. vim.fn.shellescape(project_root()) .. " run"
    else
        cmd = vim.fn.shellescape(out_path())
        local input_file = vim.fn.expand("%:p:h") .. "/input.txt"
        if vim.fn.filereadable(input_file) == 1 then
            cmd = cmd .. " < " .. vim.fn.shellescape(input_file)
        end
    end
    vim.cmd("FloatermNew --autoclose=never " .. cmd)
end

function M.attach()
    if vim.b.did_cpp_runner_ftplugin then
        return
    end
    vim.b.did_cpp_runner_ftplugin = true

    setup_dap()

    local opts = { buffer = true, silent = true }
    vim.keymap.set("n", "<leader>cb", build, vim.tbl_extend("force", opts, { desc = "C/C++: Build" }))
    vim.keymap.set("n", "<leader>cr", run, vim.tbl_extend("force", opts, { desc = "C/C++: Build & run" }))
    vim.keymap.set("n", "<leader>cn", "<cmd>cnext<CR>", vim.tbl_extend("force", opts, { desc = "Next quickfix error" }))
    vim.keymap.set("n", "<leader>cp", "<cmd>cprev<CR>", vim.tbl_extend("force", opts, { desc = "Prev quickfix error" }))
end

return M
