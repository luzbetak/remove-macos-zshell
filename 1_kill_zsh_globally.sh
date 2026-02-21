#!/bin/bash

set -e

# kill Apple login messages (local + ssh)
touch "$HOME/.hushlogin"

# force bash as login shell at account level
if ! grep -qx "/bin/bash" /etc/shells; then
  echo "/bin/bash" | sudo tee -a /etc/shells >/dev/null
fi
chsh -s /bin/bash "$USER"

# kill zsh globally for this user
rm -f "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.zlogin" "$HOME/.zshenv"

# ensure bash startup files exist
touch "$HOME/.bash_profile" "$HOME/.bashrc"

# force bashrc load for login + ssh
grep -q 'source ~/.bashrc' "$HOME/.bash_profile" || \
  echo 'source ~/.bashrc' >> "$HOME/.bash_profile"

# ensure ssh uses bash non-interactively
echo 'export BASH_SILENCE_DEPRECATION_WARNING=1' >> "$HOME/.bashrc"

echo "DONE. Bash only. Apple shut the fuck up."

