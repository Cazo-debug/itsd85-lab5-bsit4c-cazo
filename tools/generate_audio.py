"""Original deterministic synthesis. No recordings, samples or third-party music."""
from array import array
from pathlib import Path
import math
import random
import subprocess
import sys
import wave

RATE = 22050
TAU = math.tau
OUTPUT = Path(__file__).resolve().parent.parent / 'assets' / 'audio'


def write(name, seconds, function, loop=False):
    count = round(seconds * RATE)
    samples = array('h')
    for index in range(count):
        time = index / RATE
        envelope = 1 if loop else min(1, time / .008, (seconds - time) / .025)
        value = max(-.72, min(.72, function(time) * envelope))
        samples.append(round(value * 32767))
    if sys.byteorder != 'little':
        samples.byteswap()
    with wave.open(str(OUTPUT / (name + '.wav')), 'wb') as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        handle.writeframes(samples.tobytes())


def note(midi):
    return 440 * 2 ** ((midi - 69) / 12)


def generate():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    # Every oscillator completes an integer number of cycles in the .4s loop.
    def buzz(time):
        phase = TAU * 75 * time + .7 * math.sin(TAU * 10 * time)
        return .37 * (math.sin(phase) + .38 * math.sin(phase * 2) + .16 * math.sin(phase * 4)) * (1 + .12 * math.sin(TAU * 15 * time))
    write('thrust_loop', .4, buzz, True)
    write('thrust_attack', .08, lambda t: .4 * math.sin(TAU * (160 * t - 400 * t * t)) * math.exp(-20 * t))
    write('thrust_release', .14, lambda t: .34 * math.sin(TAU * (110 * t - 220 * t * t)) * math.exp(-22 * t))
    noise = random.Random(8505)
    write('impact', .16, lambda t: (.32 * math.sin(TAU * 95 * t) + noise.uniform(-.2, .2)) * math.exp(-24 * t))
    write('fall', .55, lambda t: .36 * math.sin(TAU * (420 * t - 270 * t * t)) * math.exp(-4 * t))
    write('pickup', .28, lambda t: .4 * math.sin(TAU * (660 if t < .12 else 990) * t) * math.exp(-6 * (t % .12)))
    write('ui', .065, lambda t: .28 * math.sin(TAU * 880 * t) * math.exp(-35 * t))
    write('checkpoint', .38, lambda t: .32 * math.sin(TAU * [523.25, 659.25, 783.99][min(2, int(t / .12))] * t) * math.exp(-8 * (t % .12)))
    write('win', .8, lambda t: .35 * math.sin(TAU * note([72, 76, 79, 84][min(3, int(t / .18))]) * t) * math.exp(-8 * (t % .18)))
    write('timeout', .5, lambda t: .3 * math.sin(TAU * note(60 if t < .22 else 55) * t) * math.exp(-7 * (t % .22)))
    # Original 16-beat repeating plucked theme, 120 BPM, with quiet bass.
    melody = [72, 76, 79, 74, 77, 76, 72, 69, 71, 74, 79, 76, 77, 74, 71, 67]
    bass = [48, 45, 53, 55]
    def music(time):
        beat = int(time / .5)
        local = time % .5
        frequency = note(melody[beat])
        pluck = (math.sin(TAU * frequency * local) + .2 * math.sin(TAU * frequency * 2 * local)) * math.exp(-8 * local) * min(1, local / .012)
        low_time = time % 2
        low = math.sin(TAU * note(bass[beat // 4]) * low_time) * math.exp(-2.5 * low_time) * min(1, low_time / .02)
        return .24 * pluck + .14 * low
    write('sky_theme', 8, music, True)
    encode_music('sky_theme')
    print('Generated 10 original WAV effects and 1 OGG Vorbis music loop at 22050 Hz.')


def encode_music(name):
    # The lab asks for .ogg music and .wav effects; ffmpeg must be on PATH.
    source = OUTPUT / (name + '.wav')
    target = OUTPUT / (name + '.ogg')
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', str(source), '-c:a', 'libvorbis', '-q:a', '5', str(target)], check=True)
    source.unlink()


if __name__ == '__main__':
    generate()
