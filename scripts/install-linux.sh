#!/usr/bin/env bash
# Instala OlVox para o usuário atual, sem administrador.
set -euo pipefail

if [[ "$(uname -s)" != Linux || "$(uname -m)" != x86_64 ]]; then
  echo 'Esta versão do OlVox precisa de Linux x86-64.' >&2
  exit 1
fi
expected='e20f79937c8c6da6bc85038a2d9264ad2fd8d484a5c2a9beba628ae241d28663'
url='https://github.com/fernandooliveiradev/OlVox/releases/download/v1.0.0/OlVox-x86_64.AppImage'
data_root="${XDG_DATA_HOME:-$HOME/.local/share}"
install_dir="$data_root/olvox"
app_dir="$data_root/applications"
mkdir -p "$install_dir" "$app_dir"
work=$(mktemp -d "$install_dir/.install.XXXXXXXX")
trap 'rm -rf "$work"' EXIT

if [[ $# -gt 1 ]]; then
  echo "Uso: bash $0 [arquivo-AppImage]" >&2
  exit 2
elif [[ $# -eq 1 ]]; then
  echo 'Verificando o arquivo baixado...'
  cp -- "$1" "$work/OlVox.AppImage"
else
  echo 'Baixando OlVox (aproximadamente 447 MB)...'
  curl -fL --retry 3 "$url" -o "$work/OlVox.AppImage"
fi
printf '%s  %s\n' "$expected" "$work/OlVox.AppImage" | sha256sum -c -
chmod 755 "$work/OlVox.AppImage"
cat > "$work/olvox.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="512" height="512">
<rect width="24" height="24" rx="5.2" fill="#12151c"/>
<g stroke="#a99aff" stroke-width="1.9" stroke-linecap="round"><path d="M4 10v4M8 6v12M12 3v18M16 7v10M20 10v4"/></g>
</svg>
EOF
# Desktop Entry Exec values require escaping field codes and shell-like metacharacters.
exe="$install_dir/OlVox.AppImage"
[[ "$exe" != *$'\n'* && "$exe" != *$'\r'* ]] || { echo 'Caminho de instalação inválido.' >&2; exit 1; }
exec_path=${exe//\\/\\\\}
exec_path=${exec_path//\"/\\\"}
exec_path=${exec_path//\$/\\\$}
exec_path=${exec_path//\`/\\\`}
exec_path=${exec_path//%/%%}
cat > "$work/olvox.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=OlVox
Comment=Transcrição local de áudio e vídeo
Exec="$exec_path"
Icon=$install_dir/olvox.svg
Categories=AudioVideo;Audio;
Terminal=false
EOF
mv -f "$work/OlVox.AppImage" "$exe"
mv -f "$work/olvox.svg" "$install_dir/olvox.svg"
mv -f "$work/olvox.desktop" "$app_dir/olvox.desktop"
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$app_dir" || true
fi
printf '\nOlVox instalado. Abra o menu de aplicativos e procure por OlVox.\n'
