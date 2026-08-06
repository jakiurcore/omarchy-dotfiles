# omarchy-dotfiles

Personal development environment built on top of [Omarchy](https://omarchy.org) — an opinionated Arch Linux setup. Covers Neovim, Kitty, and Zsh with a single automated installer that works across Linux distros and macOS.

## What's inside

| Config | Location | Description |
|--------|----------|-------------|
| Neovim | `neovim/` | Full IDE setup via lazy.nvim |
| Kitty | `kitty/` | GPU-accelerated terminal with Catppuccin Mocha |
| Zsh | `scripts/zshrc` | Oh-My-Zsh shell with modern CLI replacements |

## Quick start

```bash
git clone https://github.com/jakiur/omarchy-dotfiles ~/.dotfiles
cd ~/.dotfiles
./setup.sh
```

The script detects your OS, installs all dependencies, and symlinks configs into place. Any existing config files are backed up as `*.backup.<timestamp>` — nothing is deleted.

Do **not** run as root. The script escalates with `sudo` only where needed.

## What gets installed

- **Zsh** + Oh-My-Zsh with plugins: `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-history-substring-search`
- **Neovim** (latest stable)
- **Kitty** terminal emulator
- **Modern CLI tools**: `eza` (ls), `bat` (cat), `fd` (find), `fzf` (fuzzy finder), `ripgrep` (grep)
- **FiraCode Nerd Font**
- **NVM** (Node Version Manager)

## Supported operating systems

| OS | Package manager |
|----|----------------|
| Arch Linux | pacman |
| Debian / Ubuntu | apt |
| Fedora / RHEL | dnf |
| openSUSE | zypper |
| macOS | Homebrew (auto-installed if missing) |

## Symlinks created

```
~/.config/nvim   →  neovim/
~/.config/kitty  →  kitty/
~/.zshrc         →  scripts/zshrc
```

## Neovim plugins

Managed by [lazy.nvim](https://github.com/folke/lazy.nvim).

### Core editing

| Plugin | Purpose |
|--------|---------|
| nvim-cmp | Autocompletion engine with LSP, buffer, path, snippet sources |
| nvim-autopairs | Auto-close brackets, quotes, and parens; integrated with cmp |
| Comment.nvim | Toggle line and block comments |
| vim-surround | Add, change, delete surrounding characters |
| indent-blankline.nvim | Visual indent guide lines |

### LSP & tooling

| Plugin | Purpose |
|--------|---------|
| nvim-lspconfig | Language server protocol client |
| mason + mason-lspconfig | LSP server installer and manager |
| conform.nvim | Format on save (stylua, prettier, pint, gofumpt, etc.) |
| nvim-lint | Async linting (eslint_d, shellcheck, ruff, etc.) |
| nvim-treesitter | Syntax highlighting and parsing (no indent override) |

### Navigation

| Plugin | Purpose |
|--------|---------|
| telescope.nvim | Fuzzy finder for files, grep, buffers, help |
| neo-tree.nvim | File explorer sidebar |
| harpoon | Quick per-project file bookmarks |
| trouble.nvim | Diagnostics, LSP references, quickfix panel (`<leader>xx`) |
| todo-comments.nvim | Highlight and jump between TODO/FIXME/HACK/NOTE tags |

### Git

| Plugin | Purpose |
|--------|---------|
| gitsigns.nvim | Inline blame, hunk staging/reset, diff preview |
| lazygit.nvim | Full LazyGit UI inside nvim (`<leader>gg`) |

### UI

| Plugin | Purpose |
|--------|---------|
| lualine.nvim | Statusline — mode, branch, diagnostics, filetype, position |
| noice.nvim + nvim-notify | Improved cmdline, messages, and notifications |
| which-key.nvim | Keybinding hint popup after `<leader>` pause |
| alpha.nvim | Dashboard / start screen |
| nvim-web-devicons | File type icons |
| neoscroll.nvim | Smooth scrolling |
| render-markdown.nvim | In-buffer markdown preview |
| hardtime.nvim | Enforces better vim motion habits |
| floaterm | Floating terminal window |
| nvim-ts-autotag | Auto-close and rename HTML / JSX / TSX tags |
| transparency.lua | Custom plugin — strips backgrounds from all major highlight groups so Kitty's wallpaper shows through |
| Catppuccin / Rose Pine / Tokyo Night | Color schemes |

### LSP servers (auto-installed via Mason)

`lua_ls`, `ts_ls`, `pyright`, `gopls`, `rust_analyzer`, `clangd`, `intelephense`, `html`, `cssls`, `jsonls`, `yamlls`, `dockerls`, `marksman`, `bashls`

## Neovim editor settings

| Setting | Value |
|---------|-------|
| Tab width | 4 spaces (`expandtab`, `tabstop=4`, `shiftwidth=4`) |
| Line numbers | Absolute on current line, relative on others |
| Auto-indent | On — new line inherits current line's indent level |
| Clipboard | System clipboard (`unnamedplus`) |
| Undo | Persistent across sessions (`undofile`) |
| Spell check | Enabled |

## Key bindings (custom)

| Key | Action |
|-----|--------|
| `<leader>ff` | Telescope find files |
| `<leader>fg` | Telescope live grep |
| `<leader>fb` | Telescope buffers |
| `<leader>gg` | Open LazyGit |
| `<leader>xx` | Toggle diagnostics panel (Trouble) |
| `<leader>xt` | Toggle TODO list (Trouble) |
| `<leader>fm` | Format buffer |
| `<leader>hs` | Stage git hunk |
| `<leader>hr` | Reset git hunk |
| `<leader>ca` | LSP code action |
| `<leader>rn` | LSP rename |
| `]t` / `[t` | Jump to next/prev TODO |
| `]c` / `[c` | Jump to next/prev git change |

## Kitty config highlights

- Font: JetBrainsMono Nerd Font Mono, 11pt
- Theme: Catppuccin Mocha (`current-theme.conf`)
- Background: pulled from Omarchy's current wallpaper (`~/.config/omarchy/current/background`)
- Cursor trail effect with amber highlight (`#ffcb47`)
- Powerline tab bar, no window decorations, 5000-line scrollback
- Remote control enabled for theme switching

## Zsh config highlights

- Shell: Zsh + Oh-My-Zsh (`robbyrussell` theme)
- `ls` → `eza` with icons and directory-first grouping
- `cat` → `bat` with no paging
- `fzf` wired to `fd` for file search (`FZF_DEFAULT_COMMAND`)
- OS-aware package manager aliases: `mupdate`, `minstall`, `mremove`
- NVM sourced from `~/.config/nvm`
- Wayland env vars set conditionally when `XDG_SESSION_TYPE=wayland`
- 10,000-line history with deduplication and cross-session sharing

## License

MIT
