#!/bin/sh
# Removes safari-drag.js from Vivaldi's window.html: runs patch-vivaldi.command with
# --remove. Other arguments (such as --app PATH) are passed through.
exec sh "$(dirname "$0")/patch-vivaldi.command" --remove "$@"
