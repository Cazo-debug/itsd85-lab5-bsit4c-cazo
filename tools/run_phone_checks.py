"""Explicitly authorized physical-phone checks; preserves saves and Wi-Fi/display settings."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import time

from run_android_checks import AndroidChecks, HELPER, PACKAGE, REPO


class PhoneChecks(AndroidChecks):
    def __init__(self, args):
        super().__init__(args)
        self.width = 0
        self.height = 0
        self.normal_save = None
        self.helper_added = False
        self.logs = {}
        self.pids = set()
        self.profiles = []
        self.before = {}
        self.game_installation_tested = False

    def foreground(self):
        text = self.command('shell', 'dumpsys', 'window')
        self.check(any('mCurrentFocus=' in line and PACKAGE + '/' in line for line in text.splitlines()),
                   'Game owns the foreground before input/capture')

    def capture(self, label):
        self.foreground()
        super().capture(label)

    def scale(self, state):
        return self.width / state['viewport'][0], self.height / state['viewport'][1]

    def tap(self, label):
        self.foreground()
        for attempt in range(2):
            state = self.state()
            choices = [b for b in state.get('buttons', []) if b['text'].lower().startswith(label.lower()) and b['visible'] and not b['disabled']]
            if choices:
                x, y, width, height = choices[0]['rect']
                sx, sy = self.scale(state)
                self.command('shell', 'input', 'tap', round((x + width / 2) * sx), round((y + height / 2) * sy))
                self.check(True, 'Native phone tap: ' + label)
                time.sleep(.35)
                return
            if attempt == 0:
                self.command('shell', 'input', 'swipe', self.width // 2, round(self.height * .77), self.width // 2, round(self.height * .35), 450)
                time.sleep(.35)
        self.check(False, 'Visible phone tap target: ' + label)

    def pointers(self, state, **values):
        self.foreground()
        ax, ay, aw, ah = state['level']['stick_rect']
        gx, gy, gw, gh = state['level']['gas_rect']
        sx, sy = self.scale(state)
        parameters = {'aim_x': (ax + aw / 2) * sx, 'aim_y': (ay + ah / 2 - 65) * sy,
                      'gas_x': (gx + gw / 2) * sx, 'gas_y': (gy + gh / 2) * sy}
        parameters.update(values)
        return super().pointers(state, **parameters)

    def collect_log(self):
        pid = self.command('shell', 'pidof', PACKAGE, check=False).strip().split()
        if pid:
            self.pids.add(pid[0])
        for owned in self.pids:
            fresh = self.command('logcat', '-d', '--pid=' + owned, '-v', 'threadtime', check=False)
            self.logs[owned] = '\n'.join(dict.fromkeys((self.logs.get(owned, '') + '\n' + fresh).splitlines()))

    def start(self, solve=False, reset=False):
        self.collect_log()
        self.command('shell', 'am', 'force-stop', PACKAGE)
        self.command('shell', 'run-as', PACKAGE, 'rm', '-f', 'files/phase5_android_state.json')
        self.command('exec-in', 'run-as', PACKAGE, 'tee', 'files/phase5_android_check.flag',
                     data=json.dumps({'solve': solve, 'reset': reset, 'realtime': True}).encode())
        self.command('shell', 'am', 'start', '-W', '-n', self.component, timeout=90)
        self.collect_log()
        return self.scene('Title')

    def back(self):
        self.foreground()
        self.command('shell', 'input', 'keyevent', '4')

    def battery(self):
        text = self.command('shell', 'dumpsys', 'battery')
        return {key: int(match.group(1)) for key in ('level', 'temperature', 'status')
                if (match := re.search(r'^\s*' + key + r':\s*(\d+)', text, re.M))}

    def preflight(self):
        if not self.args.serial or self.args.serial.startswith('emulator-'):
            raise RuntimeError('Choose the explicitly authorized physical-phone serial.')
        if re.fullmatch(r'(?:\d{1,3}\.){3}\d{1,3}:\d+', self.args.serial):
            connection = subprocess.run([self.adb, 'connect', self.args.serial], capture_output=True, timeout=20)
            self.check(connection.returncode == 0 and b'connected to' in connection.stdout,
                       'Connected to the explicitly selected paired wireless endpoint')
        self.check(self.command('shell', 'getprop', 'ro.kernel.qemu').strip() != '1', 'Target is a physical Android device')
        model = self.command('shell', 'getprop', 'ro.product.model').strip()
        self.check(bool(model), 'Physical device identity is available')
        self.safe_target = True
        self.before = {'model': model, 'android': self.command('shell', 'getprop', 'ro.build.version.release').strip(),
                       'abi': self.command('shell', 'getprop', 'ro.product.cpu.abilist').strip(),
                       'size': self.command('shell', 'wm', 'size'), 'density': self.command('shell', 'wm', 'density'),
                       'battery': self.battery()}
        dimensions = re.findall(r'(\d+)x(\d+)', self.before['size'])
        self.width, self.height = map(int, dimensions[-1])
        self.check(self.height > self.width, 'Phone is configured for the portrait test')
        self.normal_save = self.command('exec-out', 'run-as', PACKAGE, 'cat', 'files/save.cfg', binary=True)
        (self.output / 'normal-save-before.cfg').write_bytes(self.normal_save)
        self.helper_added = not getattr(self.args, 'without_pointer_helper', False) and not self.command('shell', 'pm', 'path', HELPER, check=False).strip().startswith('package:')

    def settings(self, quality):
        self.tap('Tap to start')
        self.scene('MainMenu')
        self.tap('Settings')
        state = self.scene('Settings')
        if state['settings']['quality'] != quality:
            self.tap('Quality')
        if not self.state()['settings']['show_fps']:
            self.tap('Show fps')
        self.capture('settings-' + quality)
        desired = self.state()['settings']
        self.back()
        self.scene('MainMenu')
        return desired

    def native_controls(self):
        state = self.game()
        self.check(state['level']['riders'] == 4, 'Physical ARM phone renders four occupied rider seats')
        before = state['level']['force_seconds'][0]
        angle = state['level']['angles'][0]
        process = self.pointers(state, duration_ms=6500)
        try:
            fired = self.wait(lambda s: s.get('level', {}).get('firing', [False])[0]
                              and s['level']['force_seconds'][0] > before + .05
                              and s['level']['gas'][0] < .99
                              and s['level']['stick_id'] >= 0 and s['level']['gas_id'] >= 0
                              and s['level']['stick_id'] != s['level']['gas_id'],
                              'Two Android pointers produce sustained physical force and gas drain', timeout=15)
            self.capture('native-held')
        finally:
            self.finish_pointers(process, 'native-release')
        state = self.wait(lambda s: not any(s.get('level', {}).get('held', [True])) and not any(s['audio_targets'])
                          and s['level']['stick_id'] == -1 and s['level']['gas_id'] == -1,
                          'Phone release clears pointer ownership, thrust and audio')
        force = state['level']['force_seconds'][0]
        time.sleep(.6)
        self.check(self.state()['level']['force_seconds'][0] - force < .08, 'Released rider adds no stale physical force')
        self.check(abs((fired['level']['angles'][0] - angle + 3.141593) % 6.283185 - 3.141593) > .05,
                   'Aiming moves the rider around the ring rim')
        _, gy, _, _ = state['level']['gas_rect']
        _, sy = self.scale(state)
        process = self.pointers(state, duration_ms=7000, gas_end_y=(gy - 100) * sy)
        try:
            self.wait(lambda s: s.get('level', {}).get('firing', [False])[0], 'Phone HOLD drag starts with real thrust', timeout=12)
            self.wait(lambda s: s.get('level', {}).get('gas_id') == -1 and s['level']['stick_id'] >= 0 and not s['level']['held'][0],
                      'Dragging HOLD outside stops thrust while AIM stays owned', timeout=12)
        finally:
            self.finish_pointers(process, 'native-drag-outside')
        state = self.state()
        process = self.pointers(state, duration_ms=8000)
        try:
            self.wait(lambda s: s.get('level', {}).get('firing', [False])[0], 'Phone thrust is active before Home', timeout=12)
            self.command('shell', 'input', 'keyevent', '3')
        finally:
            self.finish_pointers(process, 'native-home-guard', cancelled=True)
        self.command('shell', 'am', 'start', '-W', '-n', self.component)
        self.wait(lambda s: s.get('level', {}).get('state') == 'PAUSED' and not any(s['level']['held']) and not any(s['audio_targets']),
                  'Physical Android Home/resume pauses and clears input/audio')
        self.capture('home-resumed-paused')
        self.tap('Resume')
        self.wait(lambda s: s.get('level', {}).get('state') == 'RACING' and not s['level']['held'][0], 'Resume does not restart old input')
        self.back()
        self.scene('CrewSetup')

    def profile(self, quality):
        self.start()
        desired = self.settings(quality)
        self.start(solve=True)
        state = self.game()
        self.check(state['time_scale'] == 1 and state['solve'], 'Profile uses real time and a separately labeled legal-input driver')
        battery_before = self.battery()
        for index in range(190):
            state = self.state()
            if state.get('level', {}).get('state') == 'FINISHED' and state.get('performance', {}).get('summary'):
                break
            if index in (15, 45):
                self.capture('profile-' + quality + '-' + str(index))
            time.sleep(1)
        else:
            self.check(False, 'Real-time phone profile completes before its wall deadline')
        level = state['level']
        self.check(level['result'].get('won') and level['result'].get('saved') and level['checkpoint'] == 2
                   and all(v > 1 for v in level['force_seconds']), 'Four legal seat forces reach ordered checkpoints and save a shared win')
        self.check(state['performance']['four_firing_frames'] > 60, 'Profile includes sustained simultaneous firing by all four riders')
        self.check(state['normal_save_unchanged'] and state['net_phase'] == 'idle', 'Local course leaves the normal save and network idle')
        self.capture('result-' + quality)
        self.profiles.append({'quality': quality, 'driver': 'CrewBrain, four seats, real time, no teleports/refills',
                              'state': state, 'battery_before': battery_before, 'battery_after': self.battery()})
        self.tap('Menu')
        self.scene('MainMenu')
        reloaded = self.start()
        self.check(reloaded['settings'] == desired and reloaded['unlocked'] >= 2 and '1' in reloaded['best_stars'] and '1' in reloaded['best_times'],
                   'Phone preferences, QA stars, best time and unlock survive a fresh process')

    def lifecycle_without_held_input(self):
        self.game()
        self.command('shell', 'input', 'keyevent', '3')
        self.command('shell', 'am', 'start', '-W', '-n', self.component)
        self.wait(lambda s: s.get('level', {}).get('state') == 'PAUSED' and not any(s['level']['held']) and not any(s['audio_targets']),
                  'Phone Home/resume pauses a run with no active hold')
        self.capture('home-paused-no-hold')
        self.tap('Resume')
        self.wait(lambda s: s.get('level', {}).get('state') == 'RACING', 'Phone resumes the paused run')
        self.back()
        self.scene('CrewSetup')

    def verify_installed_apk(self):
        path = self.command('shell', 'pm', 'path', PACKAGE).strip()
        self.check(path.startswith('package:'), 'Authorized game package is installed')
        digest = self.command('shell', 'sha256sum', path.split('package:', 1)[1].splitlines()[0]).split()[0]
        self.check(digest.lower() == hashlib.sha256(Path(self.args.apk).read_bytes()).hexdigest(),
                   'Installed APK is byte-identical to the patched local ARM debug build')

    def run(self):
        self.preflight()
        if self.args.use_installed:
            self.verify_installed_apk()
        self.command('shell', 'am', 'force-stop', PACKAGE)
        if not self.args.use_installed:
            self.check('Success' in self.command('install', '-r', self.args.apk, timeout=120), 'Signed ARM debug APK installs while keeping app data')
            self.game_installation_tested = True
        self.component = next(line.strip() for line in self.command('shell', 'cmd', 'package', 'resolve-activity', '--brief', PACKAGE).splitlines()
                              if line.strip().startswith(PACKAGE + '/'))
        if not self.args.without_pointer_helper:
            self.check('Success' in self.command('install', '-r', REPO / '.bin/gate2-touch/gate2-touch.apk', timeout=90), 'Native pointer test helper installed')
        self.start(reset=True)
        self.capture('title')
        desired = self.settings('low')
        self.collect_log()
        self.command('shell', 'am', 'force-stop', PACKAGE)
        if not self.args.use_installed:
            self.check('Success' in self.command('install', '-r', self.args.apk, timeout=120), 'Same-version reinstall retains app data')
        state = self.start()
        self.check(state['settings'] == desired and state['normal_save_unchanged'],
                   'QA preferences persist after a fresh process; normal save stays unchanged')
        if self.args.without_pointer_helper:
            self.lifecycle_without_held_input()
        else:
            self.native_controls()
        for quality in ('high', 'low'):
            self.profile(quality)

    def cleanup(self):
        if not self.safe_target:
            return
        self.collect_log()
        self.command('shell', 'am', 'force-stop', PACKAGE, check=False)
        self.command('shell', 'run-as', PACKAGE, 'rm', '-f', 'files/phase5_android_check.flag', check=False)
        after = self.command('exec-out', 'run-as', PACKAGE, 'cat', 'files/save.cfg', binary=True)
        self.check(self.normal_save is not None and after == self.normal_save, 'Original normal save is byte-identical after the complete phone session')
        self.check(self.command('shell', 'wm', 'size') == self.before['size'] and self.command('shell', 'wm', 'density') == self.before['density'],
                   'Original physical display size and density remain unchanged')
        if self.helper_added:
            self.command('uninstall', HELPER, check=False)
        if self.component:
            self.command('shell', 'am', 'start', '-W', '-n', self.component, check=False)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--serial', required=True, help='The physical phone explicitly authorized for this session')
    parser.add_argument('--sdk', default=str(Path(os.environ['LOCALAPPDATA']) / 'Android/Sdk'))
    parser.add_argument('--apk', default=str(REPO / 'export/TootTubes-phase5-debug.apk'))
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--without-pointer-helper', action='store_true', help='Explicit partial run: skip native pointer tests; retain menus, unheld Home/Back and real-time course profiles')
    parser.add_argument('--use-installed', action='store_true', help='Require an exact installed APK hash match, then skip game installation/reinstallation')
    args = parser.parse_args()
    phone = PhoneChecks(args)
    passed = False
    failure = None
    (phone.output / 'results.json').write_text('{"passed": false, "stage": "startup"}')
    try:
        phone.run()
        passed = True
    except BaseException as error:
        failure = {'type': type(error).__name__, 'message': str(error)}
        raise
    finally:
        try:
            phone.cleanup()
        except BaseException as error:
            passed = False
            failure = {'type': type(error).__name__, 'message': str(error)}
            raise
        finally:
            logs = '\n'.join(phone.logs.values())
            (phone.output / 'game-logcat.txt').write_text(logs, encoding='utf8')
            errors = [line for line in logs.splitlines() if 'ERROR:' in line or 'SCRIPT ERROR:' in line or 'FATAL EXCEPTION' in line or 'Fatal signal' in line]
            passed = passed and not errors and all(c['passed'] for c in phone.checks)
            report = {'passed': passed, 'native_pointer_tests_passed': passed and not args.without_pointer_helper,
                      'game_installation_tested_this_run': phone.game_installation_tested,
                      'scope': ('Partial phone run: native pointer tests skipped; Home/Back has no active hold. ' if args.without_pointer_helper else 'Android-injected pointers. ') + 'One physical ARM phone; separate real-time four-seat scripted profiles; Wi-Fi remains enabled; no human-feel, haptic-feel, airplane-mode or multi-phone claim',
                      'device': phone.before, 'apk_sha256': hashlib.sha256(Path(args.apk).read_bytes()).hexdigest(),
                      'checks': phone.checks, 'samples': phone.samples, 'profiles': phone.profiles, 'runtime_errors': errors, 'failure': failure}
            (phone.output / 'results.json').write_text(json.dumps(report, indent=2), encoding='utf8')
    if not passed:
        raise RuntimeError('Phone acceptance failed; inspect results.json and game-logcat.txt')
    label = 'subset' if args.without_pointer_helper else 'native'
    print(f'Physical-phone {label} checks passed: {len(phone.checks)}. {phone.output}', flush=True)


if __name__ == '__main__':
    main()
