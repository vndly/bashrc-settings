#!/usr/bin/env bash

set -euo pipefail

INPUT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$INPUT/.bashrc-extra"
TARGET="$HOME/.bashrc-extra"

# `git diff --no-index` reports a missing operand on stderr and exits 1, which
# is indistinguishable below from "the files are identical". Without this guard
# a missing source would be reported as "already up to date" and exit 0.
if [ ! -f "$SOURCE" ]; then
    echo "Error: '$SOURCE' not found." >&2
    exit 1
fi

# check_sourced
# Warn when ~/.bashrc does not pull in the deployed file — without that line the
# copy is inert. Deliberately does not edit ~/.bashrc: this script owns exactly
# one file, so it prints the line to add instead of writing it.
check_sourced() {
    if [ -f "$HOME/.bashrc" ] && grep -q "bashrc-extra" "$HOME/.bashrc"; then
        return
    fi

    echo
    echo "Warning: ~/.bashrc does not source the deployed file. Add this line to it:"
    echo
    echo "    source ~/.bashrc-extra"
}

# --- Preview (read-only) ----------------------------------------------------

if [ ! -e "$TARGET" ]; then
    echo "Previewing changes against $TARGET"
    echo
    echo "NEW:       .bashrc-extra (target does not exist, will be created)"
else
    # --numstat prints nothing when the files are identical. It exits 1 when
    # they differ, so guard it against set -e.
    numstat="$(git diff --no-index --numstat -- "$TARGET" "$SOURCE" 2>/dev/null || true)"

    # Nothing to write, so skip the confirmation entirely: the prompt should
    # only ever appear when something is actually about to change.
    if [ -z "$numstat" ]; then
        echo "Already up to date."
        check_sourced
        exit 0
    fi

    echo "Previewing changes against $TARGET"
    echo
    echo "changed:   .bashrc-extra"
    git diff --no-index --color=auto -- "$TARGET" "$SOURCE" || true
fi

# --- Confirm ----------------------------------------------------------------

echo
printf 'Proceed with deploy? [y/n] '
read -r reply || reply=""
case "$reply" in
    [yY] | [yY][eE][sS]) ;;
    *)
        echo "Aborted. Nothing was written."
        exit 0
        ;;
esac

# --- Write ------------------------------------------------------------------

cp "$SOURCE" "$TARGET"

echo "Deployed bashrc to $TARGET"
check_sourced
