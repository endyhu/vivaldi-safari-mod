#!/bin/sh
# Adds safari-drag.js to Vivaldi's window.html so tab dragging works with
# safari.css: the macOS counterpart of patch-vivaldi.bat. Vivaldi cannot load
# JavaScript from the CSS mods folder, so this edits files inside Vivaldi.app.
# An update replaces the app without the edit, so run this again after each one.
#
#   ./patch-vivaldi.command                apply to /Applications/Vivaldi.app
#   ./patch-vivaldi.command --remove       undo the edit
#   ./patch-vivaldi.command --app PATH     use a Vivaldi.app somewhere else
#
# Restart Vivaldi afterwards: window.html is read when a window opens.

set -eu

remove=0
app=/Applications/Vivaldi.app
while [ $# -gt 0 ]; do
  case $1 in
    --remove) remove=1 ;;
    --app) app=$2; shift ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

script=$(cd "$(dirname "$0")" && pwd)/safari-drag.js
# Marks the line this script added, so it can find and remove exactly that line.
tag='<script src="safari-drag.js"></script><!-- safari-mod -->'
versions="$app/Contents/Frameworks/Vivaldi Framework.framework/Versions"

if [ ! -d "$versions" ]; then
  echo "No Vivaldi found at $app. Pass its location with --app PATH." >&2
  exit 1
fi

found=0
tmp=$(mktemp)
trap 'rm -f "$tmp" "$tmp.new"' EXIT

for dir in "$versions"/*/Resources/vivaldi; do
  page=$dir/window.html
  version=$(basename "$(dirname "$(dirname "$dir")")")
  # Current is a symlink to one of the version folders.
  if [ "$version" = Current ] || [ ! -f "$page" ]; then continue; fi
  if [ ! -w "$page" ]; then
    echo "Can't write to $page. Run it again with sudo." >&2
    exit 1
  fi
  found=1
  grep -vF "$tag" "$page" > "$tmp" || true
  if [ $remove = 1 ]; then
    rm -f "$dir/safari-drag.js"
  else
    if ! grep -q '</body>' "$tmp"; then
      echo "No </body> in $page; Vivaldi's window.html changed, so the edit needs revisiting." >&2
      exit 1
    fi
    cp "$script" "$dir/safari-drag.js"
    awk -v tag="$tag" '
      !done && /^[ \t]*<\/body>/ { match($0, /^[ \t]*/); print substr($0, 1, RLENGTH) "  " tag; done = 1 }
      { print }
    ' "$tmp" > "$tmp.new"
    mv "$tmp.new" "$tmp"
  fi
  # cat rather than mv, so the file keeps its owner and permissions.
  cmp -s "$tmp" "$page" || cat "$tmp" > "$page"
  if [ $remove = 1 ]; then echo "$version: removed"; else echo "$version: patched"; fi
done

if [ $found = 0 ]; then
  echo "No window.html found under $versions." >&2
  exit 1
fi

echo
echo "Restart Vivaldi for the change to take effect."
