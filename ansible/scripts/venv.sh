#!/bin/bash

[[ -d .venv ]] || {
    python3 -m venv .venv
}

source .venv/bin/activate

if [[ $# -gt 1 && $1 == "install" ]]; then
    python -m pip install --upgrade pip
    pip install -r requirements.txt
    ansible-galaxy collection install -r requirements.yml
fi

