"""Regression checks for false acceptance and emulator cleanup; no device required."""
import argparse
from io import BytesIO
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock, patch

from PIL import Image
import run_android_checks as qa


class AndroidRunnerTests(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.TemporaryDirectory(prefix='toottubes-runner-test-')
        self.root = Path(self.folder.name)
        (self.root / '.bin').mkdir()
        self.repo = patch.object(qa, 'REPO', self.root)
        self.repo.start()
        self.args = argparse.Namespace(serial='emulator-5580', sdk=str(self.root / 'sdk'),
                                       start_avd=None, gpu='host', memory=1024, apk=str(self.root / 'game.apk'))

    def tearDown(self):
        self.repo.stop()
        self.folder.cleanup()

    def png(self, colorful):
        picture = Image.new('RGB', (128, 256), '#3bc3e6')
        if colorful:
            picture.putdata([(x % 256, y % 256, (x + y) % 256) for y in range(256) for x in range(128)])
        output = BytesIO()
        picture.save(output, format='PNG')
        return output.getvalue()

    def test_physical_serial_is_rejected_before_any_adb_command(self):
        self.args.serial = 'physical-phone-serial'
        runner = qa.AndroidChecks(self.args)
        runner.command = Mock()
        with self.assertRaisesRegex(RuntimeError, 'phones are refused'):
            runner.run()
        runner.command.assert_not_called()
        self.assertFalse(runner.safe_target)

    def test_flat_render_fails_even_when_capture_succeeds(self):
        runner = qa.AndroidChecks(self.args)
        runner.command = Mock(return_value=self.png(False))
        with patch.object(qa.time, 'monotonic', side_effect=[0, 0, 11]), patch.object(qa.time, 'sleep'):
            with self.assertRaisesRegex(AssertionError, 'not blank'):
                runner.capture('flat')
        self.assertFalse(runner.checks[-1]['passed'])

    def test_nonblank_render_is_accepted(self):
        runner = qa.AndroidChecks(self.args)
        runner.command = Mock(return_value=self.png(True))
        runner.capture('visible')
        self.assertTrue(runner.checks[-1]['passed'])

    def test_startup_failure_restores_original_configuration(self):
        self.args.start_avd = 'Fixture'
        registry = self.root / '.android/avd'
        base = registry / 'Fixture.avd'
        base.mkdir(parents=True)
        (registry / 'Fixture.ini').write_text('path=' + str(base) + '\n')
        config = base / 'config.ini'
        original = b'hw.lcd.width = 100\r\nhw.lcd.height = 200\r\nhw.gpu.enabled = no\r\nhw.gpu.mode = auto\r\n'
        config.write_bytes(original)
        socket = Mock()
        socket.__enter__ = Mock(return_value=socket)
        socket.__exit__ = Mock(return_value=False)
        socket.connect_ex.return_value = 1
        process = Mock()
        process.poll.return_value = 1
        with patch.object(Path, 'home', return_value=self.root), patch.object(qa.socket, 'socket', return_value=socket), patch.object(qa.subprocess, 'Popen', return_value=process):
            with self.assertRaisesRegex(RuntimeError, 'exited during startup'):
                with qa.emulator_session(self.args):
                    self.fail('An exited emulator must not enter the test body')
        self.assertEqual(config.read_bytes(), original)


if __name__ == '__main__':
    unittest.main()
