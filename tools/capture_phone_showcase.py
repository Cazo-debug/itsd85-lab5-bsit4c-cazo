"""Phone evidence for the graphics pass on the explicitly authorized USB phone.

Runs VisualShowcase through the debug-only AndroidCheck session (isolated QA save),
saves idle/farting/turn/fall/finish screenshots, and reports the frame times measured
while all four riders fart. The normal save must be byte-identical afterwards.

    python tools/capture_phone_showcase.py --serial <id> --tag after --install
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import time

from run_phone_checks import PhoneChecks, PACKAGE, REPO

STEPS = ['idle', 'farting', 'turn', 'fall', 'finish']


class ShowcaseRun(PhoneChecks):
    def start(self, solve=False, reset=False):
        self.collect_log()
        self.command('shell', 'am', 'force-stop', PACKAGE)
        self.command('shell', 'run-as', PACKAGE, 'rm', '-f', 'files/phase5_android_state.json')
        flag = {'reset': True, 'realtime': True, 'quality': self.args.quality}
        if self.args.profile:
            flag['solve'] = True  # AndroidCheck's legal four-seat driver over the whole course
        else:
            flag.update({'showcase': True, 'probe': self.args.probe})
        self.command('exec-in', 'run-as', PACKAGE, 'tee', 'files/phase5_android_check.flag', data=json.dumps(flag).encode())
        self.command('shell', 'am', 'start', '-W', '-n', self.component, timeout=90)
        self.collect_log()
        return self.scene('Title')

    def run(self):
        self.preflight()
        self.command('shell', 'input', 'keyevent', 'KEYCODE_WAKEUP')  # am start -W blocks while the screen sleeps
        self.command('shell', 'am', 'force-stop', PACKAGE)
        if self.args.install:
            self.check('Success' in self.command('install', '-r', self.args.apk, timeout=240), 'Debug APK installs while keeping app data')
            self.game_installation_tested = True
        self.component = next(line.strip() for line in self.command('shell', 'cmd', 'package', 'resolve-activity', '--brief', PACKAGE).splitlines()
                              if line.strip().startswith(PACKAGE + '/'))
        self.start()
        self.game()
        battery_before = self.battery()
        if self.args.profile:
            for index in range(200):
                state = self.state()
                if state.get('level', {}).get('state') == 'FINISHED' and state.get('performance', {}).get('summary'):
                    break
                if index == 40:
                    self.capture(f'{self.args.tag}_{self.args.quality}_profile')
                time.sleep(1)
            else:
                self.check(False, 'Full-course profile finishes before its deadline')
            self.check(state['level']['result'].get('won', False), 'Four-seat driver finishes the course')
            self.result = {'profile': state['performance'], 'battery_before': battery_before, 'battery_after': self.battery()}
            return
        if self.args.probe:
            state = self.wait(lambda s: s.get('showcase', {}).get('finished'), 'Probe finished', timeout=240)
            self.result = {'probe': state['showcase']['probe'], 'battery_before': battery_before, 'battery_after': self.battery()}
            return
        for step in STEPS:
            self.wait(lambda s, step=step: s.get('showcase', {}).get('step') == step and s['showcase'].get('frozen'),
                      'Showcase reached: ' + step, timeout=90)
            self.capture(f'{self.args.tag}_{self.args.quality}_{step}')
        state = self.wait(lambda s: s.get('showcase', {}).get('finished'), 'Showcase finished', timeout=40)
        self.result = {'firing': state['showcase']['firing'], 'performance': state['performance'],
                       'won': state.get('level', {}).get('result', {}).get('won'),
                       'battery_before': battery_before, 'battery_after': self.battery()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--serial', required=True, help='The physical phone explicitly authorized for this session')
    parser.add_argument('--sdk', default=str(Path(os.environ['LOCALAPPDATA']) / 'Android/Sdk'))
    parser.add_argument('--apk', default=str(REPO / 'export/TootTubes-v1.0-debug.apk'))
    parser.add_argument('--tag', default='after')
    parser.add_argument('--quality', choices=['high', 'low'], default='high')
    parser.add_argument('--install', action='store_true', help='Install --apk first (keeps app data)')
    parser.add_argument('--output', type=Path, default=None)
    parser.add_argument('--probe', nargs='*', default=[], help='Timing probe instead of screenshots: variants to switch off one at a time')
    parser.add_argument('--profile', action='store_true', help='Whole course in real time with all four seats driven (frame-time summary)')
    args = parser.parse_args()
    args.output = args.output or REPO / '.bin' / 'visual-pass-phone' / args.tag
    args.without_pointer_helper = True  # no injected pointers: VisualShowcase drives the seats
    run = ShowcaseRun(args)
    run.result = {}
    passed = False
    try:
        run.run()
        passed = True
    finally:
        run.cleanup()
        logs = '\n'.join(run.logs.values())
        (run.output / 'game-logcat.txt').write_text(logs, encoding='utf8')
        errors = [line for line in logs.splitlines() if 'SCRIPT ERROR:' in line or 'FATAL EXCEPTION' in line or 'Fatal signal' in line]
        passed = passed and not errors and all(c['passed'] for c in run.checks)
        report = {'passed': passed, 'tag': args.tag, 'quality': args.quality, 'device': run.before,
                  'apk_sha256': hashlib.sha256(Path(args.apk).read_bytes()).hexdigest(),
                  'result': run.result, 'checks': run.checks, 'runtime_errors': errors}
        (run.output / f'{"profile" if args.profile else ("probe" if args.probe else "showcase")}-{args.quality}.json').write_text(json.dumps(report, indent=2), encoding='utf8')
    print(json.dumps({'passed': passed, 'firing': run.result.get('firing'), 'profile': run.result.get('profile'), 'output': str(run.output)}, indent=2))
    if not passed:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
