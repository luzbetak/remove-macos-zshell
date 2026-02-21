#!/usr/bin/env bash

set -e

echo "Checking Homebrew..."

if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "Ensuring Homebrew in PATH..."
if [[ -d /opt/homebrew/bin ]]; then
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "Installing GNU bash..."
brew install bash

BREW_BASH="/opt/homebrew/bin/bash"

echo "Adding Brew bash to /etc/shells if missing..."
if ! grep -q "$BREW_BASH" /etc/shells; then
  sudo sh -c "echo $BREW_BASH >> /etc/shells"
fi

echo "Switching login shell..."
CURRENT_SHELL=$(dscl . -read /Users/$USER UserShell | awk '{print $2}')
if [[ "$CURRENT_SHELL" != "$BREW_BASH" ]]; then
  chsh -s "$BREW_BASH"
fi

echo "Appending to ~/.bashrc (without overwriting)..."

touch ~/.bashrc

if ! grep -q "### BREW BASH CONFIG ###" ~/.bashrc; then
cat >> ~/.bashrc <<'EOF'

### BREW BASH CONFIG ###
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'

export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# Load bash completion if available
[ -f /opt/homebrew/etc/profile.d/bash_completion.sh ] && \
source /opt/homebrew/etc/profile.d/bash_completion.sh
### END BREW BASH CONFIG ###

EOF
fi

echo "Ensuring ~/.bash_profile loads ~/.bashrc..."
touch ~/.bash_profile
if ! grep -q "source ~/.bashrc" ~/.bash_profile; then
  echo '[ -f ~/.bashrc ] && source ~/.bashrc' >> ~/.bash_profile
fi

echo
echo "Done."
echo "IMPORTANT: Completely quit Terminal and reopen it."
echo "Then verify with:"
echo "  bash --version"
echo "  echo \$SHELL"
