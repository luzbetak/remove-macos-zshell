#!/usr/bin/env bash

set -e

# Make sure conda is available
if ! command -v conda >/dev/null 2>&1; then
    echo "conda not found in PATH"
    exit 1
fi

echo "Updating conda..."
conda update -n base -c defaults conda -y

echo "Creating py311 environment..."
conda create -n py311 python=3.11 -y

# Initialize conda for bash if not already done
conda init bash || true

# Load conda into current shell
source ~/miniconda3/etc/profile.d/conda.sh 2>/dev/null || \
source ~/anaconda3/etc/profile.d/conda.sh 2>/dev/null

echo "Activating py311..."
conda activate py311

echo "Python version:"
python --version

# Optional: auto-activate on every terminal
if ! grep -q "conda activate py311" ~/.bashrc; then
    echo 'conda activate py311' >> ~/.bashrc
fi

echo "Done."
