#!/bin/bash
# Installs the Overview plasmoid from this gist into ~/.local/share/plasma/plasmoids/
# A gist is flat, so this rebuilds the package layout Plasma expects.
set -euo pipefail

ID=org.taghouti.overview
DEST="$HOME/.local/share/plasma/plasmoids/$ID"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$DEST/contents/ui" "$DEST/contents/config"
cp "$SRC/metadata.json"       "$DEST/metadata.json"
cp "$SRC/main.qml"            "$DEST/contents/ui/main.qml"
cp "$SRC/configGeneral.qml"   "$DEST/contents/ui/configGeneral.qml"
cp "$SRC/config.qml"          "$DEST/contents/config/config.qml"
cp "$SRC/config-main.xml"     "$DEST/contents/config/main.xml"

echo "Installed to $DEST"

# Make Plasma notice the new package
kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
systemctl --user restart plasma-plasmashell.service

echo
echo "Done. Right-click the panel -> Add Widgets -> search 'Overview'."
echo "If you enable the Meta-key option, log out and back in:"
echo "KWin only reads modifier-only shortcuts when it starts."
