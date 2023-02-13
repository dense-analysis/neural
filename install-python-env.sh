#!/usr/bin/env bash
#
# This script is not necessary for running the Neural plugin.
#
# This is merely for making it easy for Neural developers to develop the Python
# parts.
#
# ALE is recommended for linting and fixing Python files.

set -eu

if ! [ -d env ]; then
    python3.10 -m venv env
fi

env/bin/pip install -r test-requirements.txt
