#!/usr/bin/env bash

set -eu

if ! [ -d env ]; then
    python3.10 -m venv env
fi

env/bin/pip install pyright ruff==0.0.237
