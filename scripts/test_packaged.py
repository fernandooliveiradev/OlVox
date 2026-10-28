"""Teste real do executável: inicia o app, envia áudio e transcreve com tiny."""
import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.request
from pathlib import Path

exe = Path(sys.argv[1]).resolve()
sample = Path(sys.argv[2]).resolve()
with tempfile.TemporaryDirectory() as data:
    env = dict(os.environ, VOX_DATA_DIR=data, HF_HUB_DISABLE_XET='1')
    proc = subprocess.Popen([str(exe), '--no-window'], env=env)
    try:
        url = 'http://127.0.0.1:8000'
        for _ in range(90):
            if proc.poll() is not None:
                raise RuntimeError(f'Aplicativo encerrou: {proc.returncode}')
            try:
                with urllib.request.urlopen(url + '/health', timeout=1) as res:
                    if json.load(res)['status'] == 'ok':
                        break
            except Exception:
                time.sleep(1)
        else:
            raise RuntimeError('Aplicativo não iniciou na porta 8000')
        with urllib.request.urlopen(url + '/') as res:
            assert b'OlVox' in res.read()
        boundary = 'olvox-boundary'
        body = (f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="jfk.flac"\r\nContent-Type: audio/flac\r\n\r\n'.encode() + sample.read_bytes() + f'\r\n--{boundary}--\r\n'.encode())
        req = urllib.request.Request(url + '/api/upload', data=body, headers={'Content-Type': 'multipart/form-data; boundary=' + boundary})
        with urllib.request.urlopen(req, timeout=60) as res:
            file_id = json.load(res)['file_id']
        with urllib.request.urlopen(url + '/api/transcribe/stream?model=tiny&file_id=' + file_id, timeout=600) as res:
            events = res.read().decode()
        if 'event: done' not in events or 'event: error' in events:
            raise RuntimeError('Transcrição falhou: ' + events[-3000:])
        print('OK: aplicativo empacotado transcreveu o áudio de teste')
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=15)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()
        logfile = Path(data) / 'vox.log'
        if logfile.exists():
            print(logfile.read_text(encoding='utf-8', errors='replace')[-4000:])
