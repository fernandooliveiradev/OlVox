@echo off
setlocal
cd /d "%~dp0"
set PY=.venv\Scripts\python.exe
%PY% -m pip install -r requirements-app.txt -r requirements-desktop.txt
if errorlevel 1 exit /b 1
%PY% -m pip install --no-deps argostranslate sentencepiece
if errorlevel 1 exit /b 1
if exist build rmdir /s /q build
if exist dist rmdir /s /q dist
%PY% -m PyInstaller --noconfirm --clean --onedir --windowed --name OlVox ^
 --icon assets\vox.ico --add-data "templates;templates" --add-data "assets;assets" ^
 --collect-all faster_whisper --collect-all ctranslate2 --collect-all av --collect-all onnxruntime ^
 --collect-all tokenizers --collect-all argostranslate --collect-all sentencepiece ^
 --collect-all webview --collect-all bottle --collect-all proxy_tools ^
 --hidden-import pythonnet --hidden-import clr --hidden-import webview.platforms.edgechromium ^
 --hidden-import uvicorn.logging --hidden-import uvicorn.loops.auto --hidden-import uvicorn.protocols.http.auto ^
 --hidden-import uvicorn.protocols.websockets.auto --hidden-import uvicorn.lifespan.on ^
 --hidden-import uvicorn.protocols.http.h11_impl desktop.py
if errorlevel 1 exit /b 1
mkdir dist\OlVox\bin
%PY% -c "import shutil,imageio_ffmpeg; shutil.copy2(imageio_ffmpeg.get_ffmpeg_exe(), 'dist/OlVox/bin/ffmpeg.exe')"
if errorlevel 1 exit /b 1
curl -fsSL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe -o dist\OlVox\bin\yt-dlp.exe
if errorlevel 1 exit /b 1
curl -fsSL "https://go.microsoft.com/fwlink/p/?LinkId=2124703" -o dist\WebView2Bootstrapper.exe
if errorlevel 1 exit /b 1
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss
if errorlevel 1 exit /b 1
if not exist dist\OlVox_Setup.exe exit /b 1
