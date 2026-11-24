"""Native Android input/lifecycle checks. Explicit emulator target only; no phones."""
import argparse
from contextlib import contextmanager
import hashlib
from io import BytesIO
import json
import os
from pathlib import Path
import re
import socket
import subprocess
import time
from PIL import Image

REPO = Path(__file__).resolve().parent.parent
PACKAGE = 'com.itsd85.cazo.toottubes.debug'
HELPER = 'com.itsd85.toottubes.qa'
STATE = 'files/phase5_android_state.json'


def evidence_directory(args):
    """Keep each diagnostic attempt's captures, logs and result together."""
    output = Path(getattr(args, 'output', None) or REPO / '.bin' / 'phase5-android')
    output.mkdir(parents=True, exist_ok=True)
    return output


@contextmanager
def emulator_session(args):
    """Boot a read-only session and restore its configuration even on failure."""
    if not args.start_avd:
        yield
        return
    if not re.fullmatch(r'[A-Za-z0-9_-]+', args.start_avd) or not re.fullmatch(r'emulator-\d+', args.serial):
        raise RuntimeError('--start-avd requires a simple AVD name and emulator-NNNN serial')
    port = int(args.serial.split('-')[1])
    with socket.socket() as connection:
        if connection.connect_ex(('127.0.0.1', port)) == 0:
            raise RuntimeError('Emulator port is already in use; no existing instance will be stopped')
    registry = Path.home() / '.android' / 'avd' / (args.start_avd + '.ini')
    base = Path(next(line.split('=', 1)[1].strip() for line in registry.read_text().splitlines() if line.startswith('path=')))
    config = base / 'config.ini'
    original = config.read_bytes()
    output = evidence_directory(args)
    (output / 'emulator-original-config.ini').write_bytes(original)
    text = original.decode('utf8')
    for key, value in {'hw.lcd.width': '720', 'hw.lcd.height': '1280', 'hw.lcd.density': '240',
                       'hw.gpu.enabled': 'yes', 'hw.gpu.mode': args.gpu, 'hw.audioInput': 'no'}.items():
        text = re.sub(r'(?m)^' + re.escape(key) + r'\s*=.*$', key + '=' + value, text)
    process = None
    adb = str(Path(args.sdk) / 'platform-tools' / 'adb.exe')
    try:
        config.write_text(text, encoding='utf8')
        with (output / 'emulator.log').open('w', encoding='utf8') as log:
            process = subprocess.Popen([str(Path(args.sdk) / 'emulator' / 'emulator.exe'), '-avd', args.start_avd,
                                        '-port', str(port), '-read-only', '-no-window', '-no-audio', '-no-snapshot',
                                        '-gpu', args.gpu, '-feature', 'GLESDynamicVersion,-Vulkan', '-memory', str(args.memory), '-cores', '2',
                                        '-camera-back', 'none', '-camera-front', 'none'], stdout=log, stderr=subprocess.STDOUT,
                                       creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
            target = '127.0.0.1:' + str(port + 1)
            deadline = time.monotonic() + 300
            while time.monotonic() < deadline:
                if process.poll() is not None:
                    raise RuntimeError('Emulator exited during startup; see emulator.log')
                try:
                    subprocess.run([adb, 'connect', target], capture_output=True, timeout=10)
                    boot = subprocess.run([adb, '-s', target, 'shell', 'getprop', 'sys.boot_completed'], capture_output=True, timeout=10)
                    if boot.stdout.strip() == b'1':
                        break
                except subprocess.TimeoutExpired:
                    pass
                time.sleep(2)
            else:
                raise RuntimeError('Emulator boot exceeded 300 seconds')
            print('Read-only Android emulator booted with GPU ' + args.gpu, flush=True)
            yield
    finally:
        if process and process.poll() is None:
            try:
                subprocess.run([adb, '-s', '127.0.0.1:' + str(port + 1), 'emu', 'kill'], capture_output=True, timeout=8)
                process.wait(timeout=25)
            except (subprocess.TimeoutExpired, OSError):
                if process.poll() is None:
                    subprocess.run(['taskkill', '/PID', str(process.pid), '/T', '/F'], capture_output=True, timeout=10)
                    process.wait(timeout=10)
        config.write_bytes(original)
        (output / 'emulator-restored.json').write_text(json.dumps({'configuration_restored': config.read_bytes() == original, 'read_only': True}), encoding='utf8')


class AndroidChecks:
    def __init__(self, args):
        self.args = args
        self.adb = str(Path(args.sdk) / 'platform-tools' / 'adb.exe')
        self.output = evidence_directory(args)
        self.checks = []
        self.samples = []
        self.component = ''
        self.safe_target = False

    def command(self, *args, timeout=45, check=True, binary=False, data=None):
        result = subprocess.run([self.adb, '-s', self.args.serial, *map(str, args)],
                                input=data, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=timeout,
                                creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
        output = result.stdout if binary else result.stdout.decode('utf-8', errors='replace')
        if check and result.returncode != 0:
            raise RuntimeError(f'ADB failed: {args!r}: {output!r}')
        return output

    def check(self, condition, message):
        self.checks.append({'passed': bool(condition), 'message': message})
        print(('PASS ' if condition else 'FAIL ') + message, flush=True)
        if not condition:
            raise AssertionError(message)

    def state(self):
        try:
            return json.loads(self.command('exec-out', 'run-as', PACKAGE, 'cat', STATE, check=False, timeout=10))
        except (ValueError, subprocess.TimeoutExpired):
            return {}

    def wait(self, predicate, message, timeout=45):
        deadline = time.monotonic() + timeout
        state = {}
        while time.monotonic() < deadline:
            state = self.state()
            if state and predicate(state):
                self.samples.append({'message': message, 'state': state})
                self.check(True, message)
                return state
            time.sleep(.2)
        (self.output / 'last-state.json').write_text(json.dumps(state, indent=2), encoding='utf8')
        self.check(False, message + ' (timed out; see last-state.json)')

    def scene(self, name):
        return self.wait(lambda s: s['scene'] == name, 'Android screen: ' + name)

    def capture(self, label):
        deadline = time.monotonic() + 10
        visible = False
        while time.monotonic() < deadline:
            pixels = self.command('exec-out', 'screencap', '-p', binary=True)
            (self.output / f'{label}.png').write_bytes(pixels)
            with Image.open(BytesIO(pixels)) as picture:
                content = picture.convert('RGB').crop((16, 90, picture.width - 16, picture.height - 120))
                visible = content.getcolors(64) is None
            if visible:
                break
            time.sleep(.3)
        self.check(visible, 'Rendered Android content is not blank: ' + label)

    def tap(self, label):
        state = self.state()
        candidates = [b for b in state.get('buttons', []) if b['text'].lower().startswith(label.lower()) and b['visible'] and not b['disabled']]
        if not candidates:
            # The settings list scrolls within the fixed Back button.
            self.command('shell', 'input', 'swipe', '360', '980', '360', '450', '450')
            time.sleep(.4)
            state = self.state()
            candidates = [b for b in state.get('buttons', []) if b['text'].lower().startswith(label.lower()) and b['visible'] and not b['disabled']]
        self.check(bool(candidates), 'Visible native tap target: ' + label)
        x, y, width, height = candidates[0]['rect']
        scale_x, scale_y = 720 / state['viewport'][0], 1280 / state['viewport'][1]
        self.command('shell', 'input', 'tap', round((x + width / 2) * scale_x), round((y + height / 2) * scale_y))
        time.sleep(.4)

    def start(self, solve=False, reset=False):
        self.command('shell', 'am', 'force-stop', PACKAGE)
        self.command('shell', 'run-as', PACKAGE, 'rm', '-f', STATE, check=False)
        # The public launcher discards command-line extras. An explicit private
        # marker is accepted only by Android debug builds and removed on exit.
        self.command('exec-in', 'run-as', PACKAGE, 'tee', 'files/phase5_android_check.flag',
                     data=json.dumps({'solve': solve, 'reset': reset}).encode('utf8'))
        self.command('shell', 'am', 'start', '-W', '-n', self.component, timeout=90)
        return self.wait(lambda s: s['scene'] == 'Title', 'Android screen: Title', timeout=120)

    def game(self):
        self.tap('Tap to start')
        self.scene('MainMenu')
        self.tap('Play')
        self.scene('ModeSelect')
        self.tap('Play offline')
        self.scene('CrewSetup')
        self.tap('Start Sky Garden')
        return self.wait(lambda s: s.get('level', {}).get('state') == 'RACING', 'Normal Android countdown starts race', timeout=60)

    def pointers(self, state, **values):
        level = state['level']
        ax, ay, aw, ah = level['stick_rect']
        gx, gy, gw, gh = level['gas_rect']
        sx, sy = 720 / state['viewport'][0], 1280 / state['viewport'][1]
        parameters = {'aim_x': (ax + aw / 2) * sx, 'aim_y': (ay + ah / 2 - 65) * sy,
                      'gas_x': (gx + gw / 2) * sx, 'gas_y': (gy + gh / 2) * sy,
                      'duration_ms': 5000, 'rest_ms': 600}
        parameters.update(values)
        command = [self.adb, '-s', self.args.serial, 'shell', 'am', 'instrument', '-w']
        for key, value in parameters.items():
            command.extend(['-e', key, str(value)])
        command.append(HELPER + '/.Gate2Touch')
        return subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)

    def finish_pointers(self, process, label, cancelled=False):
        try:
            result = process.communicate(timeout=20)[0].decode('utf8', errors='replace')
        except BaseException:
            process.kill()
            process.communicate()
            raise
        (self.output / f'{label}.log').write_text(result, encoding='utf8')
        expected = 'passed=false' in result and 'not foreground' in result if cancelled else 'passed=true' in result
        self.check(process.returncode == 0 and expected, 'Native instrumentation: ' + label)

    def run(self):
        if not re.fullmatch(r'emulator-\d+|127\.0\.0\.1:\d+', self.args.serial):
            raise RuntimeError('Only an explicit emulator or local emulator TCP serial is supported; phones are refused.')
        # Some Windows shells restart the ADB server between invocations. A
        # targeted local connection restores this emulator without resetting ADB.
        if self.args.serial.startswith('emulator-'):
            local = '127.0.0.1:' + str(int(self.args.serial.split('-')[1]) + 1)
            subprocess.run([self.adb, 'connect', local], capture_output=True, timeout=15)
            self.args.serial = local
        self.check(self.command('shell', 'getprop', 'ro.kernel.qemu').strip() == '1', 'Target is an Android emulator')
        self.safe_target = True
        environment = {key: self.command('shell', 'getprop', key).strip() for key in
                       ('ro.build.version.sdk', 'ro.product.cpu.abilist', 'ro.dalvik.vm.native.bridge', 'ro.opengles.version')}
        (self.output / 'environment.json').write_text(json.dumps(environment, indent=2), encoding='utf8')
        self.command('shell', 'wm', 'size', '720x1280')
        self.command('shell', 'wm', 'density', '240')
        self.command('shell', 'settings', 'put', 'system', 'accelerometer_rotation', '0')
        self.command('shell', 'settings', 'put', 'system', 'user_rotation', '0')
        self.command('shell', 'input', 'keyevent', '82')
        self.command('install', '-r', self.args.apk, timeout=90)
        resolved = self.command('shell', 'cmd', 'package', 'resolve-activity', '--brief', PACKAGE)
        self.component = next(line.strip() for line in resolved.splitlines() if line.strip().startswith(PACKAGE + '/'))
        self.command('logcat', '-c')
        state = self.start(reset=True)
        self.check(state['normal_save_unchanged'] and state['net_phase'] == 'idle', 'Offline QA startup preserves normal save and opens no connection')
        self.capture('title')
        if getattr(self.args, 'startup_only', False):
            return
        helper = REPO / '.bin/gate2-touch/gate2-touch.apk'
        result = self.command('install', '-r', helper, check=False, timeout=60)
        if 'INSTALL_FAILED_UPDATE_INCOMPATIBLE' in result:
            self.command('uninstall', HELPER)  # Test helper only. Never uninstall the game.
            result = self.command('install', helper, timeout=60)
        self.check('Success' in result, 'Test-only native two-pointer helper installed')
        self.tap('Tap to start')
        self.scene('MainMenu')
        self.tap('Settings')
        state = self.scene('Settings')
        if state['settings']['quality'] != 'low':
            self.tap('Quality')
        if not state['settings']['show_fps']:
            self.tap('Show fps')
        self.tap('Vibration')
        self.tap('Reduced motion')
        desired = self.state()['settings']
        self.capture('settings')
        self.command('shell', 'input', 'keyevent', '4')
        self.scene('MainMenu')
        # Package-manager replacement, not a claim about upgrading between versions.
        self.command('shell', 'am', 'force-stop', PACKAGE)
        self.command('install', '-r', self.args.apk, timeout=90)
        state = self.start()
        self.check(state['settings'] == desired, 'Saved preferences survive APK reinstall and fresh process')
        state = self.game()
        self.check(state['level']['riders'] == 4, 'Four riders remain on Android low quality')
        before = state['level']['force_seconds'][0]
        process = self.pointers(state)
        try:
            firing = self.wait(lambda s: s.get('level', {}).get('firing', [False])[0]
                               and s['level']['force_seconds'][0] > before + .05
                               and s['level']['gas'][0] < .99
                               and s['level']['stick_id'] >= 0 and s['level']['gas_id'] >= 0
                               and s['level']['stick_id'] != s['level']['gas_id'],
                               'Two native fingers produce held force, independent IDs and gas drain', timeout=12)
            self.capture('native_hold')
        finally:
            self.finish_pointers(process, 'hold_release')
        state = self.wait(lambda s: not any(s.get('level', {}).get('held', [True])) and not any(s['audio_targets'])
                          and s['level']['stick_id'] == -1 and s['level']['gas_id'] == -1,
                          'Native release clears controls and thrust audio')
        force = state['level']['force_seconds'][0]
        time.sleep(.4)
        self.check(self.state()['level']['force_seconds'][0] - force < .08, 'Released rider adds no stale force')
        gx, gy, gw, gh = state['level']['gas_rect']
        process = self.pointers(state, duration_ms=7000, gas_end_y=(gy - 100) * 1280 / state['viewport'][1])
        try:
            self.wait(lambda s: s.get('level', {}).get('firing', [False])[0], 'Native drag starts with real thrust', timeout=10)
            self.wait(lambda s: s.get('level', {}).get('gas_id') == -1 and s['level']['stick_id'] >= 0
                      and not s['level']['held'][0], 'Dragging HOLD outside stops thrust while AIM remains owned', timeout=10)
        finally:
            self.finish_pointers(process, 'drag_outside')
        state = self.state()
        process = self.pointers(state, duration_ms=8000)
        self.wait(lambda s: s.get('level', {}).get('firing', [False])[0], 'Native hold active before Android Home', timeout=10)
        self.command('shell', 'input', 'keyevent', '3')
        self.finish_pointers(process, 'home_foreground_guard', cancelled=True)
        self.command('shell', 'am', 'start', '-W', '-n', self.component)
        state = self.wait(lambda s: s.get('level', {}).get('state') == 'PAUSED' and not any(s['level']['held'])
                          and not any(s['audio_targets']), 'Android Home/resume pauses and clears all held/audio state')
        self.capture('home_resume_paused')
        self.tap('Resume')
        self.wait(lambda s: s.get('level', {}).get('state') == 'RACING' and not s['level']['held'][0], 'Resume does not restart old touch input')
        self.command('shell', 'input', 'keyevent', '4')
        self.scene('CrewSetup')
        self.command('shell', 'cmd', 'connectivity', 'airplane-mode', 'enable')
        self.check(self.command('shell', 'settings', 'get', 'global', 'airplane_mode_on').strip() == '1', 'Emulator airplane mode is enabled')
        self.start(solve=True)
        self.game()
        state = self.wait(lambda s: s.get('level', {}).get('state') == 'FINISHED', 'Scripted offline Android course reaches a result', timeout=180)
        level = state['level']
        self.check(level['result'].get('won') and level['result'].get('saved') and level['checkpoint'] == 2
                   and all(value > 1 for value in level['force_seconds']), 'Airplane-mode course uses all four legal seat forces, ordered checkpoints and saved cooperative win')
        self.check(state['net_phase'] == 'idle' and state['normal_save_unchanged'], 'Offline completion preserves normal save and idle network')
        self.capture('airplane_scripted_result')
        self.tap('Menu')
        self.scene('MainMenu')
        state = self.start()
        self.check(state['unlocked'] >= 2 and '1' in state['best_stars'] and '1' in state['best_times'], 'Offline stars/time/unlock survive Android process relaunch')
        self.check(state['settings'] == desired and state['normal_save_unchanged'], 'Settings and normal-save isolation survive complete emulator run')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--serial', required=True)
    parser.add_argument('--start-avd', help='Optional existing AVD; boot read-only with host GPU, GLES 3 and automatic cleanup')
    parser.add_argument('--gpu', choices=('host', 'angle_indirect'), default='host')
    parser.add_argument('--memory', type=int, choices=(1024, 1536, 2048), default=1024)
    parser.add_argument('--sdk', default=str(Path(os.environ['LOCALAPPDATA']) / 'Android/Sdk'))
    parser.add_argument('--apk', default=str(REPO / '.bin/phase5-emulator-x86_64.apk'))
    parser.add_argument('--output', type=Path, help='Evidence directory for this attempt; default: .bin/phase5-android')
    parser.add_argument('--startup-only', action='store_true', help='Check startup/rendering only; skip native helper and gameplay')
    args = parser.parse_args()
    run = AndroidChecks(args)
    passed = False
    failure = None
    (run.output / 'results.json').write_text(json.dumps({'passed': False, 'checks': [], 'stage': 'startup'}), encoding='utf8')
    try:
        with emulator_session(args):
            try:
                run.run()
                passed = True
            finally:
                if run.safe_target:
                    if not passed:
                        try:
                            screen = run.command('exec-out', 'screencap', '-p', binary=True, timeout=10)
                            if screen.startswith(b'\x89PNG'):
                                (run.output / 'failure.png').write_bytes(screen)
                        except (RuntimeError, subprocess.TimeoutExpired):
                            pass
                    log = run.command('logcat', '-d', '-v', 'threadtime', check=False)
                    (run.output / 'logcat.txt').write_text(log, encoding='utf8')
                    errors = [line for line in log.splitlines() if (' E godot ' in line and ('ERROR:' in line or 'SCRIPT ERROR:' in line)) or 'FATAL EXCEPTION' in line]
                    if errors:
                        run.checks.append({'passed': False, 'message': 'Android runtime log contains errors', 'errors': errors})
                        passed = False
                    run.command('shell', 'am', 'force-stop', PACKAGE, check=False)
                    if not args.startup_only:
                        run.command('shell', 'am', 'force-stop', HELPER, check=False)
                    run.command('shell', 'run-as', PACKAGE, 'rm', '-f', 'files/phase5_android_check.flag', check=False)
    except BaseException as error:
        passed = False
        failure = {'type': type(error).__name__, 'message': str(error)}
        raise
    finally:
        apk = Path(args.apk)
        scope = 'Android emulator startup/rendering only; no gameplay, physical-phone or performance acceptance' if args.startup_only else 'Android emulator; native synthetic pointers; separate accelerated scripted solvability mode; no physical-phone or performance acceptance'
        report = {'passed': passed, 'serial': args.serial, 'apk_sha256': hashlib.sha256(apk.read_bytes()).hexdigest() if apk.is_file() else None,
                  'checks': run.checks, 'samples': run.samples, 'scope': scope, 'failure': failure}
        (run.output / 'results.json').write_text(json.dumps(report, indent=2), encoding='utf8')
    if not passed:
        raise RuntimeError('Android runtime/rendering acceptance failed; see results.json and logcat.txt')
    label = 'startup/rendering' if args.startup_only else 'acceptance'
    print(f'Android emulator {label} passed: {len(run.checks)} checks. {run.output}', flush=True)


if __name__ == '__main__':
    main()
