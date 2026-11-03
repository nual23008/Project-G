"""Exercise the actual launcher against isolated desktop/engine stand-ins."""
from pathlib import Path
import os
import subprocess
import tempfile
import time
import unittest

LAUNCHER = Path(__file__).resolve().parents[2] / 'run_game.sh'


class PointerLauncher(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.path = Path(self.temp.name)
        (self.path/'state').write_text('true\n')
        settings = self.path/'gsettings'
        settings.write_text('#!/bin/sh\nif [ "$1" = get ]; then cat "$POINTER_FIXTURE/state"; else printf "%s\\n" "$4" > "$POINTER_FIXTURE/state"; fi\n')
        engine = self.path/'engine'
        engine.write_text('#!/bin/sh\ncat "$POINTER_FIXTURE/state" > "$POINTER_FIXTURE/during"\nif [ "$POINTER_WAIT" = yes ]; then exec sleep 20; fi\nexit "$POINTER_EXIT"\n')
        settings.chmod(0o755)
        engine.chmod(0o755)
        self.env = dict(os.environ,PATH=str(self.path)+os.pathsep+os.environ['PATH'],GODOT_BIN=str(engine),POINTER_FIXTURE=str(self.path),POINTER_EXIT='0',POINTER_WAIT='no')

    def tearDown(self):
        self.temp.cleanup()

    def run_game(self, *args):
        return subprocess.run(['bash',str(LAUNCHER),*args],env=self.env,capture_output=True,timeout=10)

    def test_scoped_override(self):
        self.assertEqual(self.run_game().returncode,0)
        self.assertEqual((self.path/'during').read_text().strip(),'false')
        self.assertEqual((self.path/'state').read_text().strip(),'true')

    def test_engine_failure_restores(self):
        self.env['POINTER_EXIT']='17'
        self.assertEqual(self.run_game().returncode,17)
        self.assertEqual((self.path/'state').read_text().strip(),'true')

    def test_existing_disabled_preference_preserved(self):
        (self.path/'state').write_text('false\n')
        self.run_game()
        self.assertEqual((self.path/'state').read_text().strip(),'false')

    def test_headless_does_not_touch_desktop(self):
        self.run_game('--headless')
        self.assertEqual((self.path/'during').read_text().strip(),'true')

    def test_termination_restores(self):
        self.env['POINTER_WAIT']='yes'
        process=subprocess.Popen(['bash',str(LAUNCHER)],env=self.env,start_new_session=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
        try:
            for _ in range(100):
                if (self.path/'during').exists(): break
                time.sleep(.01)
            self.assertEqual((self.path/'state').read_text().strip(),'false')
            process.terminate()
            process.wait(timeout=5)
            self.assertEqual((self.path/'state').read_text().strip(),'true')
        finally:
            if process.poll() is None: process.kill()


if __name__ == '__main__':
    unittest.main()
