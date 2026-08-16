#!/usr/bin/env bash
#
# ─────────────────────────────────────────────────────────────────────────────
# Dotfiles Setup Script
# Automatically detects OS and installs all necessary dependencies.
# ─────────────────────────────────────────────────────────────────────────────

# Strict mode:
#   -E  ERR trap is inherited by functions/subshells
#   -e  exit on any unhandled error
#   -u  error on use of unset variables
#   -o pipefail  a pipeline fails if any stage fails
set -Eeuo pipefail
umask 022

# ─────────────────────────────────────────────────────────────────────────────
# Colors for output
# ─────────────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ─────────────────────────────────────────────────────────────────────────────
# Logging helpers (defined early so the ERR trap can use them)
# ─────────────────────────────────────────────────────────────────────────────
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

log_step() {
    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"
}

# Report where we failed instead of dying silently.
trap 'log_error "Setup failed at line ${LINENO}. Nothing further was run."' ERR

command_exists() { command -v "$1" >/dev/null 2>&1; }

# Ask a yes/no question. Returns non-zero for "no" or when there is no TTY
# (so non-interactive runs default to the safe/no path).
confirm() {
    local prompt="${1:-Continue?}"
    local reply
    if [[ ! -t 0 ]]; then
        return 1
    fi
    read -r -p "$prompt [y/N] " reply || return 1
    [[ "$reply" =~ ^[Yy]$ ]]
}

# Run a command, retrying with sudo only if the unprivileged attempt fails.
# We do NOT swallow stderr, so real errors stay visible.
run_cmd() {
    if "$@"; then
        return 0
    fi
    if command_exists sudo; then
        log_info "Retrying with sudo: $*"
        sudo "$@"
    else
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Paths
# ─────────────────────────────────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR

readonly NVIM_SRC="$DOTFILES_DIR/neovim"
readonly KITTY_SRC="$DOTFILES_DIR/kitty"
readonly HYPR_SRC="$DOTFILES_DIR/hypr"
readonly SCRIPTS_SRC="$DOTFILES_DIR/scripts"
readonly ZSH_SRC="$SCRIPTS_SRC/zshrc"

readonly NVIM_DEST="$HOME/.config/nvim"
readonly KITTY_DEST="$HOME/.config/kitty"
readonly HYPR_DEST="$HOME/.config/hypr"
readonly ZSH_DEST="$HOME/.zshrc"

# ─────────────────────────────────────────────────────────────────────────────
# OS Detection
# ─────────────────────────────────────────────────────────────────────────────
detect_os() {
    if [[ "${OSTYPE:-}" == "darwin"* ]]; then
        OS="macos"
        PACKAGE_MANAGER="brew"
    elif [[ -f /etc/arch-release ]]; then
        OS="arch"
        PACKAGE_MANAGER="pacman"
    elif [[ -f /etc/debian_version ]]; then
        OS="debian"
        PACKAGE_MANAGER="apt"
    elif [[ -f /etc/fedora-release ]]; then
        OS="fedora"
        PACKAGE_MANAGER="dnf"
    elif [[ -f /etc/redhat-release ]]; then
        OS="rhel"
        PACKAGE_MANAGER="dnf"
    elif [[ -f /etc/opensuse-release ]] || [[ -f /etc/SUSE-brand ]]; then
        OS="opensuse"
        PACKAGE_MANAGER="zypper"
    else
        OS="unknown"
        PACKAGE_MANAGER="unknown"
    fi
    log_info "Detected OS: $OS (Package Manager: $PACKAGE_MANAGER)"
}

# ─────────────────────────────────────────────────────────────────────────────
# Package Installation Functions
# ─────────────────────────────────────────────────────────────────────────────
install_package() {
    local package="$1"
    local package_alt="${2:-$1}" # Alternative name for different package managers

    case "$PACKAGE_MANAGER" in
    pacman) sudo pacman -S --noconfirm --needed "$package" ;;
    apt) sudo apt-get install -y "$package_alt" ;;
    dnf) sudo dnf install -y "$package_alt" ;;
    zypper) sudo zypper install -y "$package_alt" ;;
    brew) brew install "$package" ;;
    *)
        log_error "Unknown package manager"
        return 1
        ;;
    esac
}

update_system() {
    log_step "Updating System Package Lists"
    case "$PACKAGE_MANAGER" in
    pacman) sudo pacman -Sy ;;
    apt) sudo apt-get update ;;
    dnf) sudo dnf check-update || true ;;
    zypper) sudo zypper refresh ;;
    brew) brew update ;;
    esac
    log_success "Package lists updated"
}

# ─────────────────────────────────────────────────────────────────────────────
# Install Core Dependencies
# ─────────────────────────────────────────────────────────────────────────────
install_core_deps() {
    log_step "Installing Core Dependencies"
    local packages=()

    case "$PACKAGE_MANAGER" in
    pacman) packages=(git curl wget unzip tar gzip) ;;
    apt) packages=(git curl wget unzip tar gzip build-essential) ;;
    dnf) packages=(git curl wget unzip tar gzip gcc gcc-c++ make) ;;
    zypper) packages=(git curl wget unzip tar gzip) ;;
    brew) packages=(git curl wget) ;;
    esac

    local pkg
    for pkg in "${packages[@]}"; do
        if command_exists "$pkg"; then
            log_success "$pkg already installed"
        else
            log_info "Installing $pkg..."
            install_package "$pkg"
        fi
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# Install Zsh
# ─────────────────────────────────────────────────────────────────────────────
install_zsh() {
    log_step "Installing Zsh"
    if command_exists zsh; then
        log_success "Zsh already installed"
    else
        log_info "Installing Zsh..."
        install_package zsh
        log_success "Zsh installed"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Install Oh-My-Zsh
# ─────────────────────────────────────────────────────────────────────────────
install_oh_my_zsh() {
    log_step "Installing Oh-My-Zsh"
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_success "Oh-My-Zsh already installed"
        return 0
    fi

    log_info "Installing Oh-My-Zsh..."
    # Download the installer to a temp file first so a failed download can't
    # be executed, and so we clean it up regardless of outcome.
    local installer
    installer="$(mktemp)"
    trap 'rm -f "$installer"' RETURN

    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$installer"
    if [[ ! -s "$installer" ]]; then
        log_error "Oh-My-Zsh installer download was empty"
        return 1
    fi
    sh "$installer" "" --unattended
    log_success "Oh-My-Zsh installed"
}

# ─────────────────────────────────────────────────────────────────────────────
# Install Zsh Plugins
# ─────────────────────────────────────────────────────────────────────────────
clone_plugin() {
    local name="$1" url="$2" dest="$3"
    if [[ -d "$dest" ]]; then
        log_success "$name already installed"
    else
        log_info "Installing $name..."
        git clone --depth=1 "$url" "$dest"
        log_success "$name installed"
    fi
}

install_zsh_plugins() {
    log_step "Installing Zsh Plugins"
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    clone_plugin "zsh-autosuggestions" \
        "https://github.com/zsh-users/zsh-autosuggestions" \
        "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

    clone_plugin "zsh-syntax-highlighting" \
        "https://github.com/zsh-users/zsh-syntax-highlighting" \
        "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

    clone_plugin "zsh-history-substring-search" \
        "https://github.com/zsh-users/zsh-history-substring-search" \
        "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
}

# ─────────────────────────────────────────────────────────────────────────────
# Install Neovim
# ─────────────────────────────────────────────────────────────────────────────
install_neovim() {
    log_step "Installing Neovim"

    if command_exists nvim; then
        # pipefail-safe: head closing the pipe early must not fail the script.
        local nvim_version
        nvim_version="$(nvim --version 2>/dev/null | head -n1 || true)"
        log_success "Neovim already installed: ${nvim_version:-unknown version}"
        return 0
    fi

    log_info "Installing Neovim..."
    case "$PACKAGE_MANAGER" in
    pacman) sudo pacman -S --noconfirm --needed neovim ;;
    apt)
        if ! grep -q "neovim-ppa/unstable" /etc/apt/sources.list.d/* 2>/dev/null; then
            sudo apt-get install -y software-properties-common
            sudo add-apt-repository -y ppa:neovim-ppa/unstable
            sudo apt-get update
        fi
        sudo apt-get install -y neovim
        ;;
    dnf) sudo dnf install -y neovim ;;
    zypper) sudo zypper install -y neovim ;;
    brew) brew install neovim ;;
    esac
    log_success "Neovim installed"
}

# ─────────────────────────────────────────────────────────────────────────────
# Install Kitty Terminal
# ─────────────────────────────────────────────────────────────────────────────
install_kitty() {
    log_step "Installing Kitty Terminal"

    if command_exists kitty; then
        log_success "Kitty already installed"
        return 0
    fi

    log_info "Installing Kitty..."
    case "$PACKAGE_MANAGER" in
    pacman) sudo pacman -S --noconfirm --needed kitty ;;
    apt) sudo apt-get install -y kitty ;;
    dnf) sudo dnf install -y kitty ;;
    zypper) sudo zypper install -y kitty ;;
    brew) brew install --cask kitty ;;
    esac
    log_success "Kitty installed"
}

# ─────────────────────────────────────────────────────────────────────────────
# Install Modern CLI Tools
# ─────────────────────────────────────────────────────────────────────────────
install_cli_tools() {
    log_step "Installing Modern CLI Tools"

    # eza/exa (modern ls replacement)
    if command_exists eza || command_exists exa; then
        log_success "eza/exa already installed"
    else
        log_info "Installing eza (modern ls)..."
        case "$PACKAGE_MANAGER" in
        pacman) sudo pacman -S --noconfirm --needed eza ;;
        apt) sudo apt-get install -y eza 2>/dev/null || sudo apt-get install -y exa 2>/dev/null || log_warning "eza/exa not available in repos" ;;
        dnf) sudo dnf install -y eza 2>/dev/null || sudo dnf install -y exa 2>/dev/null || log_warning "eza/exa not available" ;;
        brew) brew install eza ;;
        *) log_warning "eza not available for this OS" ;;
        esac
    fi

    # bat (modern cat replacement)
    if command_exists bat || command_exists batcat; then
        log_success "bat already installed"
    else
        log_info "Installing bat (modern cat)..."
        case "$PACKAGE_MANAGER" in
        pacman) sudo pacman -S --noconfirm --needed bat ;;
        apt)
            sudo apt-get install -y bat
            if command_exists batcat && ! command_exists bat; then
                mkdir -p "$HOME/.local/bin"
                ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
            fi
            ;;
        dnf) sudo dnf install -y bat ;;
        brew) brew install bat ;;
        esac
    fi

    # fd (modern find replacement)
    if command_exists fd || command_exists fdfind; then
        log_success "fd already installed"
    else
        log_info "Installing fd (modern find)..."
        case "$PACKAGE_MANAGER" in
        pacman) sudo pacman -S --noconfirm --needed fd ;;
        apt)
            sudo apt-get install -y fd-find
            if command_exists fdfind && ! command_exists fd; then
                mkdir -p "$HOME/.local/bin"
                ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
            fi
            ;;
        dnf) sudo dnf install -y fd-find ;;
        brew) brew install fd ;;
        esac
    fi

    # fzf (fuzzy finder)
    if command_exists fzf; then
        log_success "fzf already installed"
    else
        log_info "Installing fzf (fuzzy finder)..."
        case "$PACKAGE_MANAGER" in
        pacman) sudo pacman -S --noconfirm --needed fzf ;;
        apt) sudo apt-get install -y fzf ;;
        dnf) sudo dnf install -y fzf ;;
        brew) brew install fzf ;;
        esac
    fi

    # ripgrep (modern grep replacement)
    if command_exists rg; then
        log_success "ripgrep already installed"
    else
        log_info "Installing ripgrep (modern grep)..."
        case "$PACKAGE_MANAGER" in
        pacman) sudo pacman -S --noconfirm --needed ripgrep ;;
        apt) sudo apt-get install -y ripgrep ;;
        dnf) sudo dnf install -y ripgrep ;;
        brew) brew install ripgrep ;;
        esac
    fi

    log_success "CLI tools installation complete"
}

# ─────────────────────────────────────────────────────────────────────────────
# Install Nerd Fonts
# ─────────────────────────────────────────────────────────────────────────────
install_nerd_fonts() {
    log_step "Installing Nerd Fonts (FiraCode)"

    local FONT_DIR
    if [[ "$OS" == "macos" ]]; then
        FONT_DIR="$HOME/Library/Fonts"
    else
        FONT_DIR="$HOME/.local/share/fonts"
    fi

    if fc-list 2>/dev/null | grep -qi "FiraCode.*Nerd" || [[ -f "$FONT_DIR/FiraCodeNerdFont-Regular.ttf" ]]; then
        log_success "FiraCode Nerd Font already installed"
        return 0
    fi

    if [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
        if pacman -Qi ttf-firacode-nerd &>/dev/null; then
            log_success "FiraCode Nerd Font already installed via pacman"
            return 0
        fi
        log_info "Installing FiraCode Nerd Font via pacman..."
        sudo pacman -S --noconfirm --needed ttf-firacode-nerd
        log_success "FiraCode Nerd Font installed"
        return 0
    fi

    log_info "Downloading FiraCode Nerd Font..."
    mkdir -p "$FONT_DIR"

    local TEMP_DIR
    TEMP_DIR="$(mktemp -d)"
    # Clean the temp dir up no matter how this function returns.
    trap 'rm -rf "$TEMP_DIR"' RETURN

    curl -fLo "$TEMP_DIR/FiraCode.zip" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
    unzip -q "$TEMP_DIR/FiraCode.zip" -d "$FONT_DIR"

    if command_exists fc-cache; then
        fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
    fi
    log_success "FiraCode Nerd Font installed"
}

# ─────────────────────────────────────────────────────────────────────────────
# Create Symlinks (existing configs are BACKED UP, never deleted)
# ─────────────────────────────────────────────────────────────────────────────
link_config() {
    local src="$1"
    local dest="$2"

    if [[ ! -e "$src" && ! -L "$src" ]]; then
        log_warning "Source $src not found, skipping"
        return 0
    fi

    # Already pointing where we want.
    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
        log_success "Already linked: $dest"
        return 0
    fi

    local parent_dir
    parent_dir="$(dirname "$dest")"
    [[ -d "$parent_dir" ]] || mkdir -p "$parent_dir"

    # If anything already exists at dest, move it aside instead of deleting.
    if [[ -e "$dest" || -L "$dest" ]]; then
        local backup="${dest}.backup.$(date +%Y%m%d_%H%M%S)"
        log_warning "Backing up existing $dest -> $backup"
        run_cmd mv "$dest" "$backup"
    fi

    log_info "Linking $src -> $dest"
    run_cmd ln -s "$src" "$dest"
    log_success "Linked: $(basename "$dest")"
}

create_symlinks() {
    log_step "Creating Symlinks"
    link_config "$NVIM_SRC" "$NVIM_DEST"
    link_config "$KITTY_SRC" "$KITTY_DEST"
    link_config "$ZSH_SRC" "$ZSH_DEST"
}

# ─────────────────────────────────────────────────────────────────────────────
# Hyprland Transparency (hypr/transparency.lua)
#
# Unlike the plain symlinks above, this file gets copied (not linked) and has
# its FLEURY_BLUR flag stamped in at install time, so it's safe to tweak per
# machine without editing the repo. Only runs if the user already has a Lua
# Hyprland config (~/.config/hypr/hyprland.lua) — i.e. Omarchy/Hyprland 0.55+.
# ─────────────────────────────────────────────────────────────────────────────
install_hypr_transparency() {
    log_step "Configuring Hyprland Transparency"

    local hyprland_lua="$HYPR_DEST/hyprland.lua"
    if [[ ! -f "$hyprland_lua" ]]; then
        log_warning "$hyprland_lua not found; skipping Hyprland transparency setup"
        return 0
    fi

    local blur_enabled="false"
    if [[ -n "${HYPR_BLUR:-}" ]]; then
        blur_enabled="$HYPR_BLUR"
    elif confirm "Enable frosted-glass blur behind transparent windows? (No = fully clear, no blur)"; then
        blur_enabled="true"
    fi

    local dest="$HYPR_DEST/transparency.lua"
    if [[ -e "$dest" || -L "$dest" ]]; then
        local backup="${dest}.backup.$(date +%Y%m%d_%H%M%S)"
        log_warning "Backing up existing $dest -> $backup"
        run_cmd mv "$dest" "$backup"
    fi

    log_info "Writing $dest (blur: $blur_enabled)"
    sed "s/^local FLEURY_BLUR = .*/local FLEURY_BLUR = ${blur_enabled} -- set by setup.sh/" \
        "$HYPR_SRC/transparency.lua" >"$dest"
    log_success "Hyprland transparency config installed"

    if grep -qF 'require("hypr.transparency")' "$hyprland_lua"; then
        log_success "hyprland.lua already loads transparency.lua"
        return 0
    fi

    local hypr_backup="${hyprland_lua}.backup.$(date +%Y%m%d_%H%M%S)"
    log_warning "Backing up existing $hyprland_lua -> $hypr_backup"
    run_cmd cp "$hyprland_lua" "$hypr_backup"

    printf '\nrequire("hypr.transparency")\n' >>"$hyprland_lua"
    log_success 'Added require("hypr.transparency") to hyprland.lua'
}

# ─────────────────────────────────────────────────────────────────────────────
# Set Zsh as Default Shell  +  switch the current session into zsh
# ─────────────────────────────────────────────────────────────────────────────
set_default_shell() {
    log_step "Setting Zsh as Default Shell"

    local zsh_path
    zsh_path="$(command -v zsh || true)"
    if [[ -z "$zsh_path" ]]; then
        log_warning "zsh not found on PATH; skipping default-shell change"
        return 0
    fi

    local current_shell
    current_shell="$(basename "${SHELL:-}")"
    if [[ "$current_shell" == "zsh" ]]; then
        log_success "Zsh is already the login shell"
        return 0
    fi

    # zsh must be listed in /etc/shells for chsh to accept it.
    if ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
        log_info "Registering $zsh_path in /etc/shells"
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    log_info "Changing login shell to $zsh_path (may prompt for your password)..."
    if chsh -s "$zsh_path"; then
        log_success "Login shell changed to zsh (effective next login)"
    else
        log_warning "Could not change login shell automatically. Run: chsh -s $zsh_path"
    fi
}

# Replace the current (non-zsh) process with zsh so the running terminal
# is "converted" immediately. Only does this with an interactive TTY.
switch_to_zsh_now() {
    # Already in zsh? Nothing to do.
    [[ -n "${ZSH_VERSION:-}" ]] && return 0

    local zsh_path
    zsh_path="$(command -v zsh || true)"
    [[ -n "$zsh_path" ]] || return 0

    if [[ -t 0 && -t 1 ]]; then
        log_info "Switching this session to zsh..."
        exec "$zsh_path" -l
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Install NVM (Node Version Manager)
# ─────────────────────────────────────────────────────────────────────────────
install_nvm() {
    log_step "Installing NVM (Node Version Manager)"
    export NVM_DIR="$HOME/.config/nvm"

    if [[ -d "$NVM_DIR" && -s "$NVM_DIR/nvm.sh" ]]; then
        log_success "NVM already installed"
        return 0
    fi

    log_info "Installing NVM..."
    mkdir -p "$NVM_DIR"

    local installer
    installer="$(mktemp)"
    trap 'rm -f "$installer"' RETURN

    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh -o "$installer"
    if [[ ! -s "$installer" ]]; then
        log_error "NVM installer download was empty"
        return 1
    fi
    bash "$installer"
    log_success "NVM installed"
}

# ─────────────────────────────────────────────────────────────────────────────
# Post-Install Message
# ─────────────────────────────────────────────────────────────────────────────
print_success_message() {
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}         Dotfiles Installation Complete!${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${CYAN}What was installed:${NC}"
    echo -e "    - Zsh + Oh-My-Zsh with plugins"
    echo -e "    - Neovim with lazy.nvim plugin manager"
    echo -e "    - Kitty terminal emulator"
    echo -e "    - Modern CLI tools (eza, bat, fd, fzf, ripgrep)"
    echo -e "    - FiraCode Nerd Font"
    echo -e "    - NVM (Node Version Manager)"
    echo ""
    echo -e "  ${CYAN}Configuration symlinks created:${NC}"
    echo -e "    - ~/.config/nvim    -> Neovim config"
    echo -e "    - ~/.config/kitty   -> Kitty config"
    echo -e "    - ~/.zshrc          -> Zsh config"
    echo ""
    echo -e "  ${CYAN}Hyprland transparency:${NC}"
    echo -e "    - ~/.config/hypr/transparency.lua installed (skipped if no hyprland.lua found)"
    echo -e "    - require(\"hypr.transparency\") added to ~/.config/hypr/hyprland.lua"
    echo ""
    echo -e "  ${YELLOW}Note:${NC} any pre-existing configs were backed up next to the"
    echo -e "        originals as *.backup.<timestamp> — remove them once happy."
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────
main() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              Dotfiles Setup Script                           ║${NC}"
    echo -e "${CYAN}║         Automated Environment Configuration                  ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Safety: never run the whole thing as root. It installs into $HOME and
    # escalates with sudo only for the specific commands that need it.
    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        log_error "Do not run this script as root. Run it as your normal user; it will use sudo where required."
        exit 1
    fi

    detect_os
    if [[ "$OS" == "unknown" ]]; then
        log_error "Could not detect OS. Please install dependencies manually."
        exit 1
    fi

    if ! confirm "This will install packages and symlink configs into your home directory. Continue?"; then
        log_warning "Aborted by user."
        exit 0
    fi

    # macOS needs Homebrew first.
    if [[ "$OS" == "macos" ]] && ! command_exists brew; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    update_system
    install_core_deps
    install_zsh
    install_oh_my_zsh
    install_zsh_plugins
    install_neovim
    install_kitty
    install_cli_tools
    install_nerd_fonts
    install_nvm
    create_symlinks
    install_hypr_transparency
    set_default_shell

    print_success_message

    # Convert the current session to zsh if we aren't already in it.
    switch_to_zsh_now
}

main "$@"
