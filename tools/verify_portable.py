"""Run the single-file Windows build from a fresh directory without the project."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def main():
    repo = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser()
    parser.add_argument('--exe', default=str(repo / 'export' / 'TootTubes-0.7.0-rc1.exe'))
    parser.add_argument('--rendered', action='store_true')
    args = parser.parse_args()
    suffix = 'rendered' if args.rendered else 'headless'
    report = repo / '.bin' / f'phase5-portable-{suffix}.json'
    log = report.with_suffix('.log')
    report.unlink(missing_ok=True)
    with tempfile.TemporaryDirectory(prefix='toottubes-standalone-') as folder:
        binary = Path(folder) / 'TootTubes.exe'
        shutil.copy2(args.exe, binary)
        if list(Path(folder).iterdir()) != [binary]:
            raise RuntimeError('Standalone fixture must initially contain only the EXE')
        command = [str(binary), '--max-fps', '60', '--', '--build-check', f'--report={report.as_posix()}']
        if not args.rendered:
            command.insert(1, '--headless')
        else:
            command.append('--capture')
        with log.open('w', encoding='utf-8') as output:
            result = subprocess.run(command, cwd=folder, stdout=output, stderr=subprocess.STDOUT, timeout=60,
                                    creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
        if result.returncode != 0 or 'ERROR:' in log.read_text(encoding='utf-8', errors='replace'):
            raise RuntimeError(f'Portable runtime check failed: {log}')
        data = json.loads(report.read_text(encoding='utf-8'))
        if not data['passed'] or not data['standalone']:
            raise RuntimeError(f'Portable acceptance failed: {report}')
        print(f'PASS single-file EXE, {suffix}: {data["checks"]} checks, mixed PCM peak {data["mixed_peak"]:.4f}')
        print(f'Report: {report}')


if __name__ == '__main__':
    main()
