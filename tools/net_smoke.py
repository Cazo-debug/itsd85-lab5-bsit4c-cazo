"""Real ENet peers in separate engine processes; no third-party dependencies."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import time


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--godot', default=os.environ.get('GODOT', ''))
    parser.add_argument('--players', type=int, choices=(2, 4))
    parser.add_argument('--rendered', action='store_true')
    args = parser.parse_args()
    repo = Path(__file__).resolve().parent.parent
    engine = args.godot or str(repo / '.bin' / ('Godot_v4.7.2-stable_win64.exe' if os.name == 'nt' else 'Godot_v4.7.2-stable_linux.x86_64'))
    folder = repo / '.bin' / 'phase4-validation' / time.strftime('%Y%m%d-%H%M%S')
    folder.mkdir(parents=True, exist_ok=False)
    reports = []
    cases = [(f'crew-{n}', n, 7777, 'coop') for n in ([args.players] if args.players else [2, 4])]
    if not args.players:
        # Star Scramble: the host decides the winner and every guest must show the same result.
        cases.append(('crew-2-versus', 2, 17790, 'versus'))
        cases.append(('crew-4-teams', 4, 17791, 'teams'))
    cases.append(('unreachable', 1, 17779, 'coop'))
    cases.append(('host_loss', 2, 17781, 'coop'))
    for scenario, players, port, mode in cases:
        target = folder / scenario
        target.mkdir()
        children = []
        handles = []
        try:
            for index in range(players):
                role = 'host' if index == 0 and scenario != 'unreachable' else 'guest'
                command = [engine, '--path', str(repo), '--max-fps', '60', '--time-scale', '3', '--script', 'tools/net_smoke_peer.gd', '--',
                           f'--role={role}', f'--index={index}', f'--players={players}', f'--output={target.as_posix()}',
                           f'--scenario={scenario if scenario in ("unreachable", "host_loss") else "crew"}', f'--port={port}', f'--mode={mode}']
                if not args.rendered:
                    command.insert(1, '--headless')
                log = (target / f'{role}-{index}.log').open('w', encoding='utf-8')
                handles.append(log)
                child = subprocess.Popen(command, cwd=repo, stdout=log, stderr=subprocess.STDOUT,
                                         creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' and not args.rendered else 0)
                children.append((child, role, index))
                if index == 0 and players > 1:
                    time.sleep(1)
            deadline = time.monotonic() + 175
            killed_host = False
            while any(child.poll() is None for child, _, _ in children):
                if time.monotonic() > deadline:
                    raise RuntimeError(f'{scenario} exceeded 175 seconds; see {target}')
                if scenario == 'host_loss' and not killed_host and (target / 'ready.flag').exists():
                    children[0][0].kill()
                    killed_host = True
                if any(child.poll() not in (None, 0) for child, role, _ in children if not (scenario == 'host_loss' and role == 'host' and killed_host)):
                    raise RuntimeError(f'{scenario} peer failed; see {target}')
                time.sleep(0.2)
            results = [json.loads((target / f'{role}-{index}.json').read_text(encoding='utf-8')) for _, role, index in children if not (scenario == 'host_loss' and role == 'host')]
            # Engine runtime errors can otherwise leave a script alive with exit code zero.
            for log in handles:
                log.flush()
            for path in target.glob('*.log'):
                # Godot prints 'resources still in use at exit' when a quitting process frees nodes in a
                # different order. It says nothing about the game, so only other engine errors fail the run.
                lines = path.read_text(encoding='utf-8', errors='replace').splitlines()
                if any('ERROR:' in line and 'still in use at exit' not in line for line in lines):
                    raise RuntimeError(f'Engine runtime error: {path}')
            if not all(result['passed'] for result in results):
                raise RuntimeError(f'{scenario} failed: {target}')
            if scenario.startswith('crew-'):
                shared = results[0]['result']
                if not all(result['result'] == shared for result in results):
                    raise RuntimeError(f'Cooperative result differs across peers: {target}')
            reports.extend(results)
            print(f'PASS {scenario}: {sum(result["checks"] for result in results)} checks', flush=True)
            (folder / 'results.json').write_text(json.dumps(reports, indent=2), encoding='utf-8')
        finally:
            for child, _, _ in children:
                if child.poll() is None:
                    child.terminate()
            for child, _, _ in children:
                try:
                    child.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    child.kill()
                    child.wait()
            for log in handles:
                log.close()
    print(f'All ENet smoke checks passed. Reports: {folder}', flush=True)


if __name__ == '__main__':
    main()
