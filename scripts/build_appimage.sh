#!/usr/bin/env bash
# Cria um AppImage a partir do pacote Debian produzido pelo build oficial.
set -euo pipefail
if [ "$#" -ne 3 ]; then
  echo "Uso: $0 pacote.deb appimagetool.AppImage destino.AppImage" >&2
  exit 2
fi
DEB=$(realpath "$1")
TOOL=$(realpath "$2")
OUTPUT=$(realpath -m "$3")
ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/root" "$WORK/OlVox.AppDir/usr"
DATA=$(bsdtar -tf "$DEB" | grep '^data\.tar\.' | head -1)
bsdtar -xOf "$DEB" "$DATA" | bsdtar -x -C "$WORK/root"
mv "$WORK/root/opt/olvox" "$WORK/OlVox.AppDir/usr/OlVox"
cp "$ROOT/assets/vox-256.png" "$WORK/OlVox.AppDir/olvox.png"
printf '[Desktop Entry]\nType=Application\nName=OlVox\nExec=OlVox\nIcon=olvox\nCategories=AudioVideo;Audio;\nTerminal=false\n' > "$WORK/OlVox.AppDir/olvox.desktop"
cat > "$WORK/OlVox.AppDir/AppRun" <<'EOF'
#!/bin/sh
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec "$HERE/usr/OlVox/OlVox" "$@"
EOF
chmod +x "$WORK/OlVox.AppDir/AppRun"
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$TOOL" --comp zstd "$WORK/OlVox.AppDir" "$OUTPUT"
