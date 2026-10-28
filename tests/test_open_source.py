"""Verificações rápidas da interface e do uso sem licença."""
import os
import tempfile
import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
_data = tempfile.TemporaryDirectory()
os.environ['VOX_DATA_DIR'] = _data.name
from fastapi.testclient import TestClient
from app import app, db


class OpenSourceTests(unittest.TestCase):
    def test_interface_e_uso_sem_licenca(self):
        with TestClient(app) as client:
            with db() as conn:
                conn.execute("INSERT OR REPLACE INTO settings (key, value) VALUES ('trial_used', '999')")
            page = client.get('/')
            self.assertEqual(page.status_code, 200)
            self.assertIn('OlVox', page.text)
            self.assertNotIn('Ativar licença', page.text)
            self.assertEqual(client.get('/health').status_code, 200)
            for _ in range(4):
                response = client.get('/api/transcribe/stream', params={
                    'file_id': 'a' * 32 + '.mp3', 'model': 'tiny',
                })
                self.assertEqual(response.status_code, 200)
                self.assertIn('Arquivo não encontrado', response.text)
                self.assertNotIn('licença', response.text)


if __name__ == '__main__':
    unittest.main()
