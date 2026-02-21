#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="remove-macos-zshell"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.${REPO_NAME}.backup.${TS}"

log() { printf '%s\n' "$*"; }
die() { printf '%s\n' "$*" >&2; exit 1; }

is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }
is_arm() { [[ "$(uname -m)" == "arm64" ]]; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

backup_if_exists() {
  local p="$1"
  if [[ -e "$p" ]]; then
    mkdir -p "$BACKUP_DIR"
    mv "$p" "$BACKUP_DIR/"
    log "Backed up: $p -> $BACKUP_DIR/"
  fi
}

append_if_missing() {
  local file="$1"
  local line="$2"
  touch "$file"
  if ! grep -Fqs "$line" "$file"; then
    printf '\n%s\n' "$line" >> "$file"
  fi
}

install_xcode_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    log "Xcode Command Line Tools: already installed"
    return
  fi

  log "Installing Xcode Command Line Tools (a GUI prompt may appear)..."
  xcode-select --install >/dev/null 2>&1 || true

  # Wait until installed
  until xcode-select -p >/dev/null 2>&1; do
    sleep 2
  done
  log "Xcode Command Line Tools: installed"
}

install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    log "Homebrew: already installed"
    return
  fi

  need_cmd /bin/bash
  need_cmd curl

  log "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if is_arm; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    append_if_missing "$HOME/.bash_profile" 'eval "$(/opt/homebrew/bin/brew shellenv)"'
  else
    eval "$(/usr/local/bin/brew shellenv)"
    append_if_missing "$HOME/.bash_profile" 'eval "$(/usr/local/bin/brew shellenv)"'
  fi

  log "Homebrew: installed"
}

brew_install_basics() {
  need_cmd brew
  log "Installing brew packages: coreutils bash bash-completion git..."
  brew update >/dev/null
  brew install coreutils bash bash-completion git >/dev/null
  log "Brew packages: installed"
}

set_default_shell_to_brew_bash() {
  need_cmd brew

  local brew_prefix
  brew_prefix="$(brew --prefix)"
  local new_bash="${brew_prefix}/bin/bash"

  [[ -x "$new_bash" ]] || die "Homebrew bash not found at: $new_bash"

  log "Ensuring $new_bash is listed in /etc/shells (sudo may prompt)..."
  if ! grep -Fqs "$new_bash" /etc/shells; then
    printf '%s\n' "$new_bash" | sudo tee -a /etc/shells >/dev/null
  fi

  local current_shell="${SHELL:-}"
  if [[ "$current_shell" == "$new_bash" ]]; then
    log "Default shell: already Homebrew bash ($new_bash)"
    return
  fi

  log "Changing default login shell to: $new_bash (sudo not required, may prompt for password)..."
  chsh -s "$new_bash" || die "chsh failed. Try running: chsh -s \"$new_bash\""
  log "Default shell: updated. (Open a NEW terminal tab/window to take effect.)"
}

neutralize_zsh() {
  log "Neutralizing zsh dotfiles (backing up if present)..."
  backup_if_exists "$HOME/.zshrc"
  backup_if_exists "$HOME/.zprofile"
  backup_if_exists "$HOME/.zlogin"
  backup_if_exists "$HOME/.zlogout"
  backup_if_exists "$HOME/.zshenv"
  backup_if_exists "$HOME/.oh-my-zsh"
}

write_bashrc() {
  log "Installing ~/.bashrc (backing up existing if present)..."
  backup_if_exists "$HOME/.bashrc"

  cat > "$HOME/.bashrc" <<'EOF'
#=============================================================================#
#  ~/.bashrc — Kevin's Luzbetak shell config
#  Last updated: 2025-02-21
#=============================================================================#

# Source aliases and git config early
if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi
if [ -f ~/.gitrc        ]; then . ~/.gitrc;        fi
if [ -f ~/.secrets      ]; then . ~/.secrets;      fi
# chmod 600 ~/.secrets

#--- Exit if non-interactive ------------------------------------------------#
case $- in
    *i*) ;;
      *) return;;
esac

#=============================================================================#
#  HISTORY
#=============================================================================#
HISTCONTROL=ignoreboth:erasedups   # no dupes, no leading-space entries
shopt -s histappend                # append, never overwrite
HISTSIZE=10000                     # generous in-memory history
HISTFILESIZE=100000                # generous on-disk history
HISTTIMEFORMAT="%F %T  "          # timestamp every command
PROMPT_COMMAND='history -a'        # flush every command immediately

#=============================================================================#
#  SHELL OPTIONS
#=============================================================================#
shopt -s checkwinsize   # update LINES/COLUMNS after each command
shopt -s globstar       # ** matches recursively
shopt -s cdspell        # auto-correct minor typos in cd
shopt -s dirspell       # auto-correct minor typos in tab-completion
shopt -s nocaseglob     # case-insensitive globbing
shopt -s autocd         # type a dir name to cd into it
shopt -s cmdhist        # save multi-line cmds as one history entry

# make less more friendly for non-text input files
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# chroot identifier (Debian/Ubuntu)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

#=============================================================================#
#  COLORS — directory & file listing (the good stuff)
#=============================================================================#

# Force color prompt on modern terminals
case "$TERM" in
    xterm-color|*-256color|xterm-kitty|alacritty) color_prompt=yes;;
esac

# macOS (BSD ls) colors
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# GNU ls colors — rich, readable palette
if [ -x /usr/bin/dircolors ] || command -v gdircolors &>/dev/null; then
    # Use gdircolors on macOS with coreutils, dircolors on Linux
    _dircolors=$(command -v gdircolors || command -v dircolors)

    if [ -r ~/.dircolors ]; then
        eval "$("$_dircolors" -b ~/.dircolors)"
    else
        # Custom LS_COLORS for a clean, modern look (no bold)
        export LS_COLORS="\
di=38;5;39:\
ln=36:\
so=35:\
pi=33:\
ex=38;5;196:\
bd=33;40:\
cd=33;40:\
su=37;41:\
sg=30;43:\
tw=30;42:\
ow=34;42:\
*.tar=31:*.tgz=31:*.gz=31:*.bz2=31:*.xz=31:*.zip=31:*.7z=31:*.rar=31:\
*.jpg=35:*.jpeg=35:*.png=35:*.gif=35:*.bmp=35:*.svg=35:*.webp=35:*.ico=35:\
*.mp3=36:*.flac=36:*.wav=36:*.aac=36:*.ogg=36:\
*.mp4=36:*.mkv=36:*.avi=36:*.mov=36:*.webm=36:\
*.pdf=33:*.doc=33:*.docx=33:*.xls=33:*.xlsx=33:*.ppt=33:*.pptx=33:\
*.py=32:*.js=32:*.ts=32:*.go=32:*.rs=32:*.rb=32:*.sh=32:*.bash=32:\
*.json=33:*.yaml=33:*.yml=33:*.toml=33:*.xml=33:*.csv=33:\
*.md=37:*.txt=37:*.log=90:\
*.sql=33:\
*.dockerfile=33:*.dockerignore=90:\
*.env=90:*.env.*=90:\
*.lock=90:\
*.bak=90:*.swp=90:*.tmp=90:\
"
    fi
    unset _dircolors

    # Use GNU ls flags
    alias ls='ls --color=auto --group-directories-first'
else
    # Fallback for plain BSD ls on macOS
    alias ls='ls -G'
fi

# Colored output for grep and friends
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Colored man pages
export LESS_TERMCAP_mb=$'\e[1;31m'     # begin bold
export LESS_TERMCAP_md=$'\e[1;36m'     # begin blink (bold cyan)
export LESS_TERMCAP_me=$'\e[0m'        # end mode
export LESS_TERMCAP_so=$'\e[1;33;44m'  # begin standout (yellow on blue)
export LESS_TERMCAP_se=$'\e[0m'        # end standout
export LESS_TERMCAP_us=$'\e[1;32m'     # begin underline (bold green)
export LESS_TERMCAP_ue=$'\e[0m'        # end underline

# Colored GCC output
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

#=============================================================================#
#  PROMPT
#=============================================================================#

__git_prompt() {
    local branch
    branch=$(git branch 2>/dev/null | sed -n 's/^\* //p')
    if [ -n "$branch" ]; then
        # Show dirty indicator
        local dirty=""
        git diff --quiet --ignore-submodules 2>/dev/null || dirty="*"
        git diff --cached --quiet --ignore-submodules 2>/dev/null || dirty="${dirty}+"
        echo " ($branch$dirty)"
    fi
}

__conda_prompt() {
    [ -n "$CONDA_DEFAULT_ENV" ] && echo "($CONDA_DEFAULT_ENV) "
}

if [ "$color_prompt" = yes ]; then
    # Conda(dim) User(green) : Path(blue) GitBranch(red/yellow) $
    PS1='${debian_chroot:+($debian_chroot)}'
    PS1+='\[\033[2m\]$(__conda_prompt)\[\033[0m\]'    # conda env (dim)
    PS1+='\[\033[1;32m\]\u\[\033[0m\]'                # username (bold green)
    PS1+=':\[\033[0;36m\]\w\[\033[0m\]'               # working dir (cyan/azure)
    PS1+='\[\033[0;31m\]$(__git_prompt)\[\033[0m\]'   # git branch (red)
    PS1+='\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}$(__conda_prompt)\u:\w$(__git_prompt)\$ '
fi
unset color_prompt force_color_prompt

# Set terminal title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
esac

#=============================================================================#
#  ALIASES
#=============================================================================#

# ls family
alias ll='ls -alFh'        # long listing, human-readable sizes
alias la='ls -A'            # almost all (no . ..)
alias l='ls -lFh'           # long, human-readable
alias lt='ls -ltrh'         # sort by time, newest last
alias lS='ls -lSrh'        # sort by size, largest last
alias l.='ls -d .*'         # dotfiles only
alias tree='tree -C --dirsfirst'  # colored tree

# navigation
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'           # dash to go back

# safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -pv'

# disk usage (human readable)
alias df='df -h'
alias du='du -h'
alias dud='du -d 1 -h | sort -hr'   # top-level dir sizes, sorted

# quick utils
alias h='history | tail -40'
alias j='jobs -l'
alias ports='lsof -i -P -n | grep LISTEN'
alias myip='curl -s ifconfig.me && echo'
alias path='echo $PATH | tr ":" "\n" | nl'
alias reload='source ~/.bashrc && echo "✓ bashrc reloaded"'

# Docker shortcuts
alias dk='docker'
alias dkc='docker compose'
alias dkps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dklog='docker logs -f --tail 100'

# Alert for long-running commands: sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

#=============================================================================#
#  FUNCTIONS
#=============================================================================#

#--- Go builder -------------------------------------------------------------#
b() {
    local src="$1"
    local out="$2"

    if [ -z "$src" ]; then
        local go_files=(*.go)
        if [ ${#go_files[@]} -eq 0 ] || [ ! -f "${go_files[0]}" ]; then
            echo "✗ No .go files found"
            return 1
        elif [ ${#go_files[@]} -gt 1 ]; then
            echo "Multiple .go files found: ${go_files[*]}"
            echo "Please specify: b <filename>"
            return 1
        fi
        src="${go_files[0]}"
    fi

    [[ "$src" != *.go ]] && src="${src}.go"

    if [ ! -f "$src" ]; then
        echo "✗ Source file not found: $src"
        return 1
    fi

    [ -z "$out" ] && out="${src%.go}"

    echo "=== Building $src → $out ==="

    if [ ! -f go.mod ]; then
        echo "Initializing Go module..."
        go mod init "$(basename "$PWD")"
        go mod tidy 2>/dev/null
    fi

    if go build -o "$out" "$src"; then
        echo "✓ Build successful: ./$out"
    else
        echo "✗ Build failed"
        return 1
    fi
}

#--- Archive a file with timestamp ------------------------------------------#
a() {
    local filename=$(basename "$1")
    local date=$(date +"%Y%m%d-%H%M")
    local archive_dir="$HOME/.archive"
    local target_file="$archive_dir/$date.$filename"

    if [[ -e $1 ]]; then
        mkdir -p "$archive_dir"
        cp "$1" "$target_file"
        echo "✓ Archived $1 → $target_file"
    else
        echo "✗ $1 does not exist"
        return 1
    fi
    ls -lh "$archive_dir"
}

#--- Search (ripgrep multi-keyword) -----------------------------------------#
search() {
    if [ $# -eq 0 ]; then
        echo "Usage: search [-tTYPE] keyword [keyword2 ...]"
        return 1
    fi

    local cmd
    if [[ $1 == -* ]]; then
        cmd="rg ${1} -l '${2}'"
        shift
    else
        cmd="rg -l '${1}'"
    fi
    shift

    for keyword in "$@"; do
        cmd+=" | xargs -I{} rg -l '${keyword}' {}"
    done

    eval "$cmd"
}

#--- Search + preview (ripgrep with context) --------------------------------#
spy() {
    if [ $# -eq 0 ]; then
        echo "Usage: spy <keyword> [filetype]"
        echo "  e.g. spy open py"
        return 1
    fi

    clear
    local cmd
    if [ $# -eq 1 ]; then
        cmd="rg -C3 ${1}"
    else
        cmd="rg -t${2} -C3 ${1}"
    fi
    eval "$cmd"

    printf '\n\033[2m%.0s─\033[0m' {1..60}; echo
    echo -e "  \033[2m$cmd\033[0m"
    printf '\033[2m%.0s─\033[0m' {1..60}; echo
}

#--- Quick extract any archive ----------------------------------------------#
extract() {
    if [ -z "$1" ]; then
        echo "Usage: extract <file>"
        return 1
    fi
    if [ ! -f "$1" ]; then
        echo "✗ '$1' is not a file"
        return 1
    fi
    case "$1" in
        *.tar.bz2) tar xjf "$1"   ;;
        *.tar.gz)  tar xzf "$1"   ;;
        *.tar.xz)  tar xJf "$1"   ;;
        *.bz2)     bunzip2 "$1"   ;;
        *.gz)      gunzip "$1"    ;;
        *.tar)     tar xf "$1"    ;;
        *.tbz2)    tar xjf "$1"   ;;
        *.tgz)     tar xzf "$1"   ;;
        *.zip)     unzip "$1"     ;;
        *.7z)      7z x "$1"     ;;
        *.rar)     unrar x "$1"  ;;
        *)         echo "✗ Unknown archive format: $1" ;;
    esac
}

#--- Make dir and cd into it ------------------------------------------------#
mkcd() {
    mkdir -p "$1" && cd "$1"
}

#=============================================================================#
# Force directories/executables to desired colors (no bold), regardless of earlier LS_COLORS/dircolors
if [ -n "${LS_COLORS-}" ]; then
  LS_COLORS="$(printf '%s' "$LS_COLORS" | sed -E 's/(^|:)di=[^:]*(:|$)/\1di=38;5;39\2/')"
  LS_COLORS="$(printf '%s' "$LS_COLORS" | sed -E 's/(^|:)ex=[^:]*(:|$)/\1ex=38;5;196\2/')"
else
  LS_COLORS="di=38;5;39:ex=38;5;196:"
fi
export LS_COLORS

#=============================================================================#
#  COMPLETION
#=============================================================================#
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

#=============================================================================#
#  PATH
#=============================================================================#
PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
source /opt/homebrew/etc/profile.d/bash_completion.sh 2>/dev/null

#=============================================================================#
#  PATH
#=============================================================================#
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
#=============================================================================#
EOF

  log "Wrote: ~/.bashrc"
}

ensure_bash_profile_sources_bashrc() {
  log "Ensuring ~/.bash_profile sources ~/.bashrc..."
  backup_if_exists "$HOME/.bash_profile"
  cat > "$HOME/.bash_profile" <<'EOF'
# ~/.bash_profile
# Load brew shellenv first (if present), then ~/.bashrc

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
EOF
  log "Wrote: ~/.bash_profile"
}

install_miniconda() {
  need_cmd curl
  local target_dir="$HOME/miniconda3"
  if [[ -d "$target_dir" ]]; then
    log "Miniconda: already installed at $target_dir"
    return
  fi

  local arch
  if is_arm; then
    arch="arm64"
  else
    arch="x86_64"
  fi

  local url="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-${arch}.sh"
  local installer="/tmp/Miniconda3-latest-MacOSX-${arch}.sh"

  log "Downloading Miniconda installer: $url"
  curl -fsSL "$url" -o "$installer"
  chmod +x "$installer"

  log "Installing Miniconda to: $target_dir"
  bash "$installer" -b -p "$target_dir"
  rm -f "$installer"

  log "Miniconda: installed"
  log "Note: conda init is NOT forced here; you can do it later if you want."
}

main() {
  is_macos || die "This installer is for macOS only."

  log "Backup directory (if needed): $BACKUP_DIR"
  install_xcode_clt
  install_homebrew
  brew_install_basics
  install_miniconda
  neutralize_zsh
  ensure_bash_profile_sources_bashrc
  write_bashrc
  set_default_shell_to_brew_bash

  log ""
  log "Done."
  log "Open a NEW terminal window/tab for the new login shell to take effect."
  log "If you want to test immediately, run: exec \"$(brew --prefix)/bin/bash\" -l"
  log "Backups (if any): $BACKUP_DIR"
}

main "$@"
