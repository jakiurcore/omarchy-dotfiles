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

| Plugin | Purpose |
|--------|---------|
| nvim-cmp | Autocompletion engine |
| mason + mason-lspconfig | LSP server installer |
| nvim-lspconfig | Language server protocol |
| nvim-treesitter | Syntax highlighting & parsing |
| telescope.nvim | Fuzzy file/text finder |
| neo-tree.nvim | File explorer sidebar |
| harpoon | Quick file bookmarks |
| gitsigns.nvim | Inline git blame & diff |
| noice.nvim | Improved UI for messages & cmdline |
| conform.nvim / nvim-lint | Formatting & linting |
| Comment.nvim | Toggle comments |
| vim-surround | Surround text objects |
| floaterm | Floating terminal |
| neoscroll.nvim | Smooth scrolling |
| render-markdown.nvim | In-buffer markdown preview |
| hardtime.nvim | Enforces better vim habits |
| alpha.nvim | Dashboard / start screen |
| Catppuccin / Rose Pine / Tokyo Night | Color schemes |

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
