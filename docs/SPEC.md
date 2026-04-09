# Technical Specification

## Overview

Live Transcription is a MATLAB application that captures microphone audio in real time, processes it through speech-to-text engines, and displays Unicode captions in a uifigure GUI. It supports 20 languages and 4 STT providers.

## System Requirements

### MATLAB

- **Version**: R2024a or later (developed on R2026a)
- **Audio Toolbox**: Required — `audioDeviceReader`, `audiodevinfo`, `speechClient`, `speech2text`
- **Deep Learning Toolbox**: Required for Whisper (MATLAB) provider — model inference
- **Audio Toolbox Interface for SpeechBrain and Torchaudio Libraries**: Required support package for Whisper (MATLAB) provider
- **Signal Processing Toolbox**: Optional — `resample()` in offline demo only
- **Parallel Computing Toolbox**: Optional — GPU acceleration (`ExecutionEnvironment="gpu"`)

### Python (optional, for Python-based providers)

- Python 3.10+
- `faster-whisper` or `openai-whisper` for WhisperPythonProvider
- `transformers`, `torch`, `librosa` for HuggingFaceProvider

### External Services (optional)

- Google Cloud Speech-to-Text API key for GoogleSpeechProvider

## Audio Pipeline

### Capture

- **Device**: `audioDeviceReader` at 16 kHz, mono, 1600 samples/frame (100ms)
- **Timer**: CaptureTimer at 100ms (`fixedSpacing` mode)
- **Output**: Raw audio frames fed to Chunker

### Voice Activity Detection

- RMS energy-based detection
- Calibration phase: first 10 frames establish noise floor (assumes no speech at startup)
- Threshold: `NoiseFloor × VADThreshold` (default 3.0×)
- Hangover: 5 frames (~0.5s) — keeps speech state active during brief pauses
- Adaptive noise floor: slowly drifts toward ambient level during confirmed silence

### Chunking

| Parameter | Default | Description |
|-----------|---------|-------------|
| MinChunkDuration | 3.0s | Don't emit chunks shorter than this |
| MaxChunkDuration | 8.0s | Force-emit at this length |
| SilenceTimeout | 0.5s | Silence duration to end a chunk |
| ChunkOverlap | 0.5s | Overlap between consecutive chunks |

Emit conditions:
1. Speech ended (silence timeout exceeded) AND buffer ≥ MinChunkDuration
2. Buffer reached MaxChunkDuration (force-emit)

Overlap: last 0.5s of each chunk is retained as the start of the next chunk to prevent word splitting at boundaries.

### Buffer Drain

After a synchronous STT call blocks the main thread (8–19s for Whisper medium), `drainAudioBuffer()` recovers audio frames that accumulated in `audioDeviceReader`'s internal buffer:

- Buffered frames return instantly (< 1ms)
- Live frames take ~100ms (real-time)
- Detection: `readTime > frameDuration × 0.8` indicates buffer is exhausted
- Zero audio data loss

## STT Providers

### WhisperMatlabProvider (synchronous)

- Uses `speechClient("whisper")` + `speech2text()`
- **Not thread-safe**: cannot use `parfeval`, `backgroundPool`, or `parpool`
- Must run synchronously on main thread
- ~8s fixed overhead per chunk regardless of audio length
- Language mapped from ISO 639-1 code to Whisper name via `codeToWhisperLang()`
- English omits `Language` parameter to use multilingual model (avoids requiring `whisper-medium.en`)
- Hallucination filter catches: >50 word outputs, repeated 2–3 word patterns (≥3 repeats), <25% unique word ratio

### WhisperPythonProvider (asynchronous)

- Calls `python/whisper_transcribe.py` via `system()`
- Async via `parfeval(backgroundPool, @system, ...)`
- Supports `faster-whisper` with fallback to `openai-whisper`
- Language passed via `--language` flag

### HuggingFaceProvider (asynchronous)

- Calls `python/hf_transcribe.py` via `system()`
- Async via `parfeval(backgroundPool, @system, ...)`
- Model auto-selected from `LanguageRegistry` or explicit `Config.HuggingFaceModel`
- Fine-tuned models available: Armenian (`Chillarmo/whisper-small-hy-AM`), Hebrew (`ivrit-ai/whisper-v2-d3-e3`)
- Falls back to `openai/whisper-medium` for languages without fine-tuned models

### GoogleSpeechProvider (synchronous)

- REST API via `webwrite` to `speech.googleapis.com`
- Base64-encoded LINEAR16 audio
- Language code from `Config.GoogleLanguageCode` (BCP-47 format)
- Requires API key

## Multi-Language Architecture

### LanguageRegistry

Static class mapping 20 languages to:
- `name` — Display name (e.g., "Armenian")
- `code` — ISO 639-1 code (e.g., "hy")
- `googleCode` — BCP-47 code (e.g., "hy-AM")
- `script` — Font script category (latin, armenian, cyrillic, arabic, cjk, devanagari, greek, hebrew)
- `hfModel` — Optional HuggingFace model ID

Adding a new language requires only a new entry in `LanguageRegistry.all()`.

### FontHelper

Per-script font candidate lists with system probing:
- **Latin**: Segoe UI, Noto Sans, DejaVu Sans, Helvetica, Arial
- **Armenian**: Noto Sans Armenian, Noto Sans, DejaVu Sans, Sylfaen, Arial Unicode MS
- **Cyrillic**: Noto Sans, DejaVu Sans, Segoe UI, Arial Unicode MS
- **Arabic**: Noto Sans Arabic, Noto Sans, Segoe UI, Traditional Arabic
- **CJK**: Noto Sans CJK, Microsoft YaHei, MS Gothic, Malgun Gothic, SimHei
- **Devanagari**: Noto Sans Devanagari, Noto Sans, Mangal
- **Greek**: Noto Sans, DejaVu Sans, Segoe UI
- **Hebrew**: Noto Sans Hebrew, Noto Sans, David

### Language Change Flow

1. User selects language from dropdown
2. `Config.Language`, `Config.LanguageCode`, `Config.GoogleLanguageCode` updated from LanguageRegistry
3. `FontHelper.selectFont(script)` updates caption and transcript fonts
4. Active provider reloaded with new language settings

## GUI

- `uifigure` with `uigridlayout` (5 rows × 8 columns)
- Row 1: Language dropdown, Mic dropdown, Provider dropdown, Status lamp + label
- Row 2: Start, Stop, Clear, Save buttons, Audio level gauge
- Row 3: Large caption display (32pt, per-script font, white on dark)
- Row 4: Scrolling transcript history (14pt, timestamped)
- Row 5: Status bar

### Status Feedback

| State | Display |
|-------|---------|
| Initializing | "Loading model..." (Start button disabled, yellow lamp) |
| Ready | "Ready" (grey lamp) |
| Listening | "Listening..." (green lamp) |
| Speech detected | "Hearing speech..." (green lamp) |
| Transcribing | "Transcribing... Xs" with animated dots (yellow lamp) |
| Queue | "Queued: N chunks" |
| Stopped | "Stopped" (grey lamp) |

## Threading Model

- Both timers run on the main MATLAB thread
- `fixedSpacing` mode: missed callbacks are dropped, not queued
- WhisperMatlabProvider blocks main thread for 8–19s per chunk
- Python providers run in background via `parfeval(backgroundPool, @system, ...)`
- `backgroundPool` is base MATLAB (R2021b+), no Parallel Computing Toolbox required
- `drawnow` called after blocking operations to process queued UI events

## Timer Safety

- MATLAB timer callbacks that throw exceptions **stop firing silently** — always set `ErrorFcn`
- Timer cleanup in both `onClose()` and `delete()` — check `isvalid()` before `stop()`/`delete()`
- `parfeval` futures cancelled on stop

## File I/O

- Transcripts saved as UTF-8 via `Utf8File.write()` using `fopen(..., 'w', 'n', 'UTF-8')`
- Temporary WAV chunks written to `tempdir` with timestamp-based filenames
- Temp files cleaned up after transcription via `TempAudioWriter.cleanup()`
- Config persisted as JSON via `Config.saveToFile()` / `Config.loadFromFile()`
- `loadFromFile` coerces `char` to `string` for string properties (MATLAB `jsondecode` returns `char`)

## Test Suite

8 test files:
- **TestConfig** — creation, save/load round-trip, char-to-string coercion
- **TestLanguageRegistry** — lookup by name/code, field validation, fallback behavior
- **TestChunker** — silence, speech, max duration enforcement, reset
- **TestVAD** — calibration, speech detection, hangover, reset
- **TestCaptionMerger** — overlap merging, edge cases, case-insensitive
- **TestProviders** — creation, makeResult, missing WAV handling, language from config, HuggingFace model selection
- **TestUnicode** — Armenian/Cyrillic string creation, UTF-8 round-trip, FontHelper per-script
- **TestEndToEnd** — CaptionBuffer add/retrieve/clear/dedup, TempAudioWriter
