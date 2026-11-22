"""Finds where a song's voice starts and ends (run with the Python of the Demucs environment, not the server's).

Reads one JSON request per line on stdin – {"path": "...", "duration": 215.3} – and answers each with one JSON line on
stdout: {"vocals_in": 12.5, "vocals_out": 201.0} or {"error": "..."}; "threads" in a request sets how many threads
the separation uses for it. A request with "stem" and "length" instead writes
the song's first `length` seconds without the voice (drums, bass and the rest) as Opus to "stem": {"stem": "..."}. The first line is {"ready": true} once the model
is loaded. Only the intro and the outro are separated (the parts AutoMix blends); a part without a voice reports the
edge of its window, a song without any voice its length and zero.
"""

import json
import os
import subprocess
import sys

import numpy as np
import torch
from demucs.apply import apply_model
from demucs.pretrained import get_model

# Seconds separated at the start and at the end; shorter songs are separated as a whole.
WINDOW = 75.0
_FRAME = 0.25
# The voice counts from this level relative to the loudest accompaniment of the window, for at least a second.
_THRESHOLD_DB = -35.0
_MIN_SECONDS = 1.0


def _decode(path: str, start: float, length: float, rate: int) -> np.ndarray:
    out = subprocess.run(
        ["ffmpeg", "-v", "error", "-nostdin", "-ss", f"{start:.3f}", "-t", f"{length:.3f}", "-i", path,
         "-ac", "2", "-ar", str(rate), "-f", "f32le", "-"],
        capture_output=True, check=True, timeout=300,
    ).stdout
    return np.frombuffer(out, dtype=np.float32).reshape(-1, 2).T.copy()


def _voiced(model, path: str, start: float, length: float) -> np.ndarray:
    """Per frame of the window: whether the voice is there."""
    rate = model.samplerate
    wav = torch.from_numpy(_decode(path, start, length, rate))
    if wav.shape[1] < rate:
        return np.zeros(0, dtype=bool)
    ref = wav.mean(0)
    wav = (wav - ref.mean()) / (ref.std() + 1e-8)
    with torch.no_grad():
        sources = apply_model(model, wav[None], shifts=0, split=True, overlap=0.1, progress=False, device="cpu")[0]
    index = model.sources.index("vocals")
    voice = sources[index].mean(0).numpy()
    rest = (sources.sum(0) - sources[index]).mean(0).numpy()
    hop = int(rate * _FRAME)
    count = len(voice) // hop
    if count == 0:
        return np.zeros(0, dtype=bool)
    voice_rms = np.sqrt((voice[: count * hop].reshape(count, hop) ** 2).mean(1))
    rest_rms = np.sqrt((rest[: count * hop].reshape(count, hop) ** 2).mean(1))
    level = 20 * np.log10(voice_rms / (max(float(rest_rms.max()), float(voice_rms.max())) + 1e-9) + 1e-9)
    active = level > _THRESHOLD_DB
    # A voice lasts: drop single breaths and bleed shorter than a second.
    width = int(_MIN_SECONDS / _FRAME)
    sustained = np.convolve(active.astype(float), np.ones(width), mode="same") >= width * 0.75
    return sustained


def instrumental(model, path: str, length: float, out: str) -> dict:
    """The start of the song without its voice, for transitions where the next song's beat runs under the current
    song's singing (the desktop app plays it until the bass swaps)."""
    rate = model.samplerate
    wav = torch.from_numpy(_decode(path, 0.0, length, rate))
    ref = wav.mean(0)
    mean, std = ref.mean(), ref.std() + 1e-8
    with torch.no_grad():
        sources = apply_model(
            model, ((wav - mean) / std)[None], shifts=0, split=True, overlap=0.1, progress=False, device="cpu"
        )[0]
    rest = (sources.sum(0) - sources[model.sources.index("vocals")]) * std + mean
    data = rest.clamp(-1, 1).T.contiguous().numpy().astype(np.float32).tobytes()
    subprocess.run(
        ["ffmpeg", "-v", "error", "-nostdin", "-y", "-f", "f32le", "-ar", str(rate), "-ac", "2", "-i", "-",
         "-c:a", "libopus", "-b:a", "160k", out],
        input=data, check=True, timeout=300,
    )
    return {"stem": out}


def analyze(model, path: str, duration: float) -> dict:
    if duration <= 2 * WINDOW + 10:
        voiced = _voiced(model, path, 0.0, duration)
        frames = np.nonzero(voiced)[0]
        if not len(frames):
            return {"vocals_in": round(duration, 2), "vocals_out": 0.0}
        return {
            "vocals_in": round(float(frames[0] * _FRAME), 2),
            "vocals_out": round(min(duration, float((frames[-1] + 1) * _FRAME)), 2),
        }
    intro = np.nonzero(_voiced(model, path, 0.0, WINDOW))[0]
    outro_start = duration - WINDOW
    outro = np.nonzero(_voiced(model, path, outro_start, WINDOW))[0]
    vocals_out = min(duration, outro_start + float((outro[-1] + 1) * _FRAME)) if len(outro) else outro_start
    return {
        "vocals_in": round(float(intro[0] * _FRAME) if len(intro) else WINDOW, 2),
        "vocals_out": round(vocals_out, 2),
    }


def main() -> None:
    # The answers get stdout to themselves: whatever libraries or ffmpeg print goes to stderr instead.
    answers = os.fdopen(os.dup(1), "w")
    os.dup2(2, 1)
    sys.stdout = sys.stderr
    os.nice(15)
    default_threads = max(1, (os.cpu_count() or 2) // 2)
    torch.set_num_threads(default_threads)
    model = get_model("htdemucs")
    model.eval()
    print(json.dumps({"ready": True}), file=answers, flush=True)
    for line in sys.stdin:
        try:
            request = json.loads(line)
            torch.set_num_threads(max(1, int(request.get("threads") or default_threads)))
            if "stem" in request:
                result = instrumental(model, request["path"], float(request["length"]), request["stem"])
            else:
                result = analyze(model, request["path"], float(request["duration"]))
        except Exception as e:  # noqa: BLE001 - every failure is reported and the next song goes on
            result = {"error": f"{type(e).__name__}: {e}"[:500]}
        print(json.dumps(result), file=answers, flush=True)


if __name__ == "__main__":
    main()
