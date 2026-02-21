# .bash_profile -*- mode: sh -*-

# Load login settings and environment variables
if [[ -f ~/.profile ]]; then
  source ~/.profile
fi

# Load interactive settings
if [[ -f ~/.bashrc ]]; then
  source ~/.bashrc
fi
[[ -f ~/.bashrc ]] && . ~/.bashrc


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/mac/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/mac/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/mac/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/mac/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
conda activate py311

[ -f ~/.bashrc ] && source ~/.bashrc
