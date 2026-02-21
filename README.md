Remove MacOS Zshell
===================

Bootstrap a fresh macOS machine into a Bash-based environment with:

- Homebrew
- GNU coreutils (real `ls`)
- Homebrew Bash (modern Bash)
- Bash completion
- Git
- Miniconda
- Your custom `.bashrc`
- Azure directories + vibrant red executables (no bold)

macOS includes Apple zsh and it cannot be physically removed.
This repo instead:

- switches your default login shell to Homebrew Bash
- backs up all zsh dotfiles
- installs your exact `.bashrc`
- makes Bash the primary interactive shell

---

## What the installer does (in order)

1. Installs Xcode Command Line Tools
2. Installs Homebrew (if missing)
3. Installs brew packages:
   - coreutils
   - bash
   - bash-completion
   - git
4. Installs Miniconda to `~/miniconda3`
5. Backs up zsh files:
   - `.zshrc`
   - `.zprofile`
   - `.zlogin`
   - `.zlogout`
   - `.zshenv`
   - `.oh-my-zsh`
6. Writes your `.bashrc`
7. Creates `.bash_profile` that sources `.bashrc`
8. Changes default login shell to Homebrew Bash

All backups go into:

~/.remove-macos-zshell.backup.TIMESTAMP/

---

## Requirements

- macOS
- Admin password (needed for Xcode CLT, /etc/shells, chsh)

---

## Install

git clone https://github.com/YOURNAME/remove-macos-zshell.git
cd remove-macos-zshell
chmod +x install.sh
./install.sh

When finished:

- Close ALL terminal windows
- Open a new terminal

---

## Verify

echo "$SHELL"
bash --version

ls --version
ls --color=always

Expected:

- directories = azure
- executables = vibrant red
- no bold

---

## Miniconda

Miniconda installs automatically.

Conda is NOT initialized by default.

If you want it:

~/miniconda3/bin/conda init bash

Restart terminal afterward.

---

## Rollback

ls -d ~/.remove-macos-zshell.backup.*

cp ~/.remove-macos-zshell.backup.TIMESTAMP/.bashrc ~/
cp ~/.remove-macos-zshell.backup.TIMESTAMP/.bash_profile ~/

Switch back to zsh if desired:

chsh -s /bin/zsh

Open new terminal.

---

## Repo contents

- install.sh   — main installer
- README.md   — this file

---

## Notes

- Script is idempotent (safe to rerun)
- Existing files are backed up before replacement
- No destructive deletes
- Review install.sh before running on important machines

---

Built for people who want Bash back on macOS.
