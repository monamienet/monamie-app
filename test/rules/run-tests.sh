#!/bin/sh
# The standalone firebase CLI puts its own `node` shim first in PATH inside
# `emulators:exec`, and that shim does not run `node --test`. Drop it so the
# system Node runs the tests.
PATH=$(printf %s "$PATH" | tr ':' '\n' | grep -v '/firebase/runtime' | paste -sd: -)
export PATH
exec node --test "$@"
