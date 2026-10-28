#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
VENV="${VENV:-.venv}"
"$VENV/bin/pip" install -r requirements-app.txt pyinstaller imageio-ffmpeg PySide6 qtpy pywebview
"$VENV/bin/pip" install --no-deps argostranslate sentencepiece
rm -rf build dist
"$VENV/bin/pyinstaller" --noconfirm --clean --onedir --name OlVox \
  --add-data 'templates:templates' --add-data 'assets:assets' \
  --collect-all faster_whisper --collect-all ctranslate2 --collect-all av \
  --collect-all onnxruntime --collect-all tokenizers --collect-all argostranslate \
  --collect-all sentencepiece --collect-all PySide6 --collect-all qtpy --collect-all webview \
  --hidden-import uvicorn.logging --hidden-import uvicorn.loops.auto \
  --hidden-import uvicorn.protocols.http.auto --hidden-import uvicorn.protocols.websockets.auto \
  --hidden-import uvicorn.lifespan.on --hidden-import uvicorn.protocols.http.h11_impl desktop.py
mkdir -p dist/OlVox/bin
"$VENV/bin/python" - <<'PY2'
import shutil, imageio_ffmpeg
shutil.copy2(imageio_ffmpeg.get_ffmpeg_exe(), 'dist/OlVox/bin/ffmpeg')
PY2
curl -fsSL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux -o dist/OlVox/bin/yt-dlp
chmod +x dist/OlVox/bin/ffmpeg dist/OlVox/bin/yt-dlp
