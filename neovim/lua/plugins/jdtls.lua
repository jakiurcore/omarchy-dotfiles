-- lua/plugins/jdtls.lua
return {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    dependencies = {
        "mfussenegger/nvim-dap",
        "williamboman/mason.nvim",
    },
    config = function()
        local function setup_jdtls()
            local ok_registry, mason_registry = pcall(require, "mason-registry")
            if not ok_registry or not mason_registry.is_installed("jdtls") then
                vim.notify("jdtls not installed yet (Mason is still installing tools)", vim.log.levels.WARN)
                return
            end

            local jdtls = require("jdtls")
            local jdtls_path = mason_registry.get_package("jdtls"):get_install_path()
            local launcher_jar = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
            local lombok_jar = jdtls_path .. "/lombok.jar"

            -- jdtls itself requires a Java 21+ runtime to run (independent of the JDK
            -- a given project targets, which is set up below via
            -- settings.java.configuration.runtimes). Don't rely on PATH: it may point
            -- at an older JDK (e.g. via mise/asdf shims or a distro default symlink).
            -- Discovered dynamically from /usr/lib/jvm (Arch/Omarchy's standard layout)
            -- so this works regardless of which JDKs a given machine has installed.
            local function discover_jvms()
                local jvms = {}
                local seen_major = {}
                for _, dir in ipairs(vim.fn.glob("/usr/lib/jvm/*", false, true)) do
                    local basename = vim.fn.fnamemodify(dir, ":t")
                    -- skip alias symlinks (e.g. "default", "default-runtime") so a
                    -- real versioned dir isn't listed twice under different names
                    if basename ~= "default" and basename ~= "default-runtime" then
                        local release_file = dir .. "/release"
                        local java_bin = dir .. "/bin/java"
                        if vim.fn.filereadable(release_file) == 1 and vim.fn.executable(java_bin) == 1 then
                            for _, line in ipairs(vim.fn.readfile(release_file)) do
                                local ver = line:match('^JAVA_VERSION="?(%d+)')
                                if ver then
                                    local major = tonumber(ver)
                                    if major and not seen_major[major] then
                                        seen_major[major] = true
                                        table.insert(jvms, { path = dir, java = java_bin, major = major })
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
                table.sort(jvms, function(a, b)
                    return a.major > b.major
                end)
                return jvms
            end
            local jvms = discover_jvms()

            local function find_jdtls_runtime()
                for _, jvm in ipairs(jvms) do
                    if jvm.major >= 21 then
                        return jvm.java
                    end
                end
                vim.notify(
                    "No JDK 21+ found under /usr/lib/jvm - jdtls needs one to run itself "
                        .. "(install one, e.g. `sudo pacman -S jdk21-openjdk`). Falling back to "
                        .. "`java` on PATH, which will likely fail to start jdtls.",
                    vim.log.levels.WARN
                )
                return "java"
            end
            local java_runtime = find_jdtls_runtime()

            -- JDKs project code may target (Android/Spring Boot projects vary);
            -- separate from the JDK 21+ runtime jdtls itself runs on above. Built
            -- from whatever JDKs discover_jvms() actually found on this machine.
            local runtimes = {}
            for i, jvm in ipairs(jvms) do
                table.insert(runtimes, {
                    name = "JavaSE-" .. jvm.major,
                    path = jvm.path,
                    default = (i == 1) or nil,
                })
            end

            local root_markers = {
                "gradlew",
                "mvnw",
                "pom.xml",
                "build.gradle",
                "build.gradle.kts",
                "settings.gradle",
                "settings.gradle.kts",
                ".git",
            }
            local root_dir = require("jdtls.setup").find_root(root_markers) or vim.fn.getcwd()
            local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
            local workspace_dir = vim.fn.stdpath("cache") .. "/jdtls-workspace/" .. project_name

            -- Debug + test bundles from mason (java-debug-adapter, java-test)
            local bundles = {}
            local debug_pkg_name = "java-debug-adapter"
            local test_pkg_name = "java-test"
            if mason_registry.is_installed(debug_pkg_name) then
                local debug_jar = vim.fn.glob(
                    mason_registry.get_package(debug_pkg_name):get_install_path()
                        .. "/extension/server/com.microsoft.java.debug.plugin-*.jar"
                )
                if debug_jar ~= "" then
                    table.insert(bundles, debug_jar)
                end
            end
            if mason_registry.is_installed(test_pkg_name) then
                local test_jars = vim.split(
                    vim.fn.glob(mason_registry.get_package(test_pkg_name):get_install_path() .. "/extension/server/*.jar"),
                    "\n"
                )
                for _, jar in ipairs(test_jars) do
                    if jar ~= "" then
                        table.insert(bundles, jar)
                    end
                end
            end

            local cmd = {
                java_runtime,
                "-Declipse.application=org.eclipse.jdt.ls.core.id1",
                "-Dosgi.bundles.defaultStartLevel=4",
                "-Declipse.product=org.eclipse.jdt.ls.core.product",
                "-Dlog.protocol=true",
                "-Dlog.level=ALL",
                "-Xms1g",
                "--add-modules=ALL-SYSTEM",
                "--add-opens",
                "java.base/java.util=ALL-UNNAMED",
                "--add-opens",
                "java.base/java.lang=ALL-UNNAMED",
            }
            if vim.fn.filereadable(lombok_jar) == 1 then
                table.insert(cmd, "-javaagent:" .. lombok_jar)
            end
            vim.list_extend(cmd, {
                "-jar",
                launcher_jar,
                "-configuration",
                jdtls_path .. "/config_linux",
                "-data",
                workspace_dir,
            })

            local config = {
                cmd = cmd,
                root_dir = root_dir,
                settings = {
                    java = {
                        signatureHelp = { enabled = true },
                        completion = { favoriteStaticMembers = {} },
                        eclipse = { downloadSources = true },
                        maven = { downloadSources = true },
                        implementationsCodeLens = { enabled = true },
                        referencesCodeLens = { enabled = true },
                        format = { enabled = true },
                        configuration = {
                            updateBuildConfiguration = "interactive",
                            runtimes = #runtimes > 0 and runtimes or nil,
                        },
                    },
                },
                init_options = { bundles = bundles },
                on_attach = function(_, bufnr)
                    local opts = { buffer = bufnr, silent = true }
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
                    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
                    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
                    vim.keymap.set("n", "<leader>jo", jdtls.organize_imports, opts)
                    vim.keymap.set("n", "<leader>jv", jdtls.extract_variable, opts)
                    vim.keymap.set("n", "<leader>jc", jdtls.extract_constant, opts)
                    vim.keymap.set("v", "<leader>jm", function()
                        jdtls.extract_method(true)
                    end, opts)
                    vim.keymap.set("n", "<leader>jt", jdtls.test_class, opts)
                    vim.keymap.set("n", "<leader>jn", jdtls.test_nearest_method, opts)
                    pcall(jdtls.setup_dap, { hotcodereplace = "auto" })
                end,
            }

            jdtls.start_or_attach(config)
        end

        vim.api.nvim_create_autocmd("FileType", {
            pattern = "java",
            callback = setup_jdtls,
        })
    end,
}
