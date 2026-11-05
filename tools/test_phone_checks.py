"""Device-free safeguards for physical-phone coordinates, foreground and save cleanup."""
import argparse
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock, patch

import run_android_checks as android
import run_phone_checks as phone_cli
from run_phone_checks import PhoneChecks


class PhoneRunnerTests(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.TemporaryDirectory(prefix='toottubes-phone-test-')
        self.args = argparse.Namespace(serial='authorized-phone', sdk=self.folder.name,
                                       output=Path(self.folder.name) / 'evidence')
        self.phone = PhoneChecks(self.args)
        self.phone.width, self.phone.height = 1080, 2436

    def tearDown(self):
        self.folder.cleanup()

    def test_emulator_is_refused_before_adb(self):
        self.args.serial = 'emulator-5580'
        self.phone.command = Mock()
        with self.assertRaisesRegex(RuntimeError, 'physical-phone serial'):
            self.phone.preflight()
        self.phone.command.assert_not_called()

    def test_background_app_receives_no_taps(self):
        self.phone.command = Mock(return_value='mCurrentFocus=Window{ unrelated.app/.Screen }')
        self.phone.state = Mock()
        with self.assertRaisesRegex(AssertionError, 'foreground'):
            self.phone.tap('Play')
        self.phone.state.assert_not_called()
        self.assertFalse(any('input' in str(call) for call in self.phone.command.call_args_list))

    def test_tap_scales_expanded_portrait_viewport_without_changing_display(self):
        self.phone.foreground = Mock()
        self.phone.command = Mock()
        self.phone.state = Mock(return_value={'viewport': [720, 1624], 'buttons': [
            {'text': 'Play', 'visible': True, 'disabled': False, 'rect': [100, 1300, 200, 120]}]})
        with patch('run_phone_checks.time.sleep'):
            self.phone.tap('Play')
        self.phone.command.assert_called_once_with('shell', 'input', 'tap', 300, 2040)

    def test_both_native_pointers_scale_to_real_phone_coordinates(self):
        self.phone.foreground = Mock()
        state = {'viewport': [720, 1624], 'level': {'stick_rect': [50, 1200, 200, 200], 'gas_rect': [500, 1300, 160, 160]}}
        with patch.object(android.AndroidChecks, 'pointers') as injected:
            self.phone.pointers(state, duration_ms=8000)
        values = injected.call_args.kwargs
        self.assertEqual((values['aim_x'], values['aim_y']), (225, 1852.5))
        self.assertEqual((values['gas_x'], values['gas_y']), (870, 2070))
        self.assertEqual(values['duration_ms'], 8000)

    def test_native_crash_evidence_survives_process_exit_and_log_rotation(self):
        self.phone.pids.add('12345')
        self.phone.logs['12345'] = 'Earlier app startup'
        self.phone.command = Mock(side_effect=['', 'Fatal signal 11 (SIGSEGV)', '', ''])
        self.phone.collect_log()
        self.phone.collect_log()
        self.assertIn('Earlier app startup', self.phone.logs['12345'])
        self.assertIn('Fatal signal 11 (SIGSEGV)', self.phone.logs['12345'])

    def test_partial_success_cannot_claim_native_pointer_acceptance(self):
        apk = Path(self.folder.name) / 'fixture.apk'
        apk.write_bytes(b'isolated report fixture')
        arguments = ['run_phone_checks.py', '--serial', 'authorized-phone', '--apk', str(apk),
                     '--output', str(self.args.output), '--without-pointer-helper']
        with patch('sys.argv', arguments), patch.object(PhoneChecks, 'run'), patch.object(PhoneChecks, 'cleanup'):
            phone_cli.main()
        report = json.loads((self.args.output / 'results.json').read_text())
        self.assertTrue(report['passed'])
        self.assertFalse(report['native_pointer_tests_passed'])
        self.assertIn('native pointer tests skipped', report['scope'])

    def test_installed_apk_mismatch_is_rejected_without_device_mutations(self):
        apk = Path(self.folder.name) / 'expected.apk'
        apk.write_bytes(b'current candidate')
        self.args.apk = str(apk)
        self.phone.command = Mock(side_effect=['package:/data/app/game/base.apk', '0' * 64 + '  /data/app/game/base.apk'])
        with self.assertRaisesRegex(AssertionError, 'byte-identical'):
            self.phone.verify_installed_apk()
        self.assertFalse(any('install' in str(call) or 'force-stop' in str(call) for call in self.phone.command.call_args_list))


if __name__ == '__main__':
    unittest.main()
