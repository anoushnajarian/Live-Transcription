# Live Transcription

Real-time speech transcription in MATLAB with multi-language support. Captures microphone audio, runs it through speech-to-text engines, and displays Unicode captions in a uifigure GUI.

## Features

- **Multi-language support** — 20 languages via dropdown, sorted alphabetically
- **Multiple STT providers** — Whisper (native MATLAB), Whisper (Python/faster-whisper), HuggingFace Transformers, Google Cloud Speech
- **Real-time capture** — Dual-timer architecture with voice activity detection and intelligent chunking
- **Unicode captions** — Per-script font selection for non-Latin scripts (Armenian, Arabic, CJK, Cyrillic, Devanagari, Greek, Hebrew)
- **Audio buffer recovery** — Recovers audio buffered during blocking STT calls via drain pattern
- **Hallucination filtering** — Catches repetitive Whisper outputs on silence/noise

## Requirements

### MATLAB Toolboxes

| Toolbox | Required? | Used By |
|---------|-----------|---------|
| **Audio Toolbox** | Required | `audioDeviceReader`, `audiodevinfo`, `speechClient`, `speech2text` |
| **Deep Learning Toolbox** | Required for Whisper (MATLAB) | Model inference via `speechClient("whisper")` |
| **Signal Processing Toolbox** | Optional | `resample()` in offline demo only |
| **Parallel Computing Toolbox** | Optional | GPU acceleration (`ExecutionEnvironment="gpu"`) |

### Support Package

| Package | Required? |
|---------|-----------|
| **Audio Toolbox Interface for SpeechBrain and Torchaudio Libraries** | Required for Whisper (MATLAB) provider |

Install from Add-On Explorer or via `speechClient("whisper")` which provides a download link.

### External Dependencies (Python-based providers only)

- Python 3.10+
- `faster-whisper` or `openai-whisper` (for WhisperPythonProvider)
- `transformers`, `torch`, `librosa` (for HuggingFaceProvider)
- Google Cloud API key (for GoogleSpeechProvider)

> **Note:** Python-based providers have no MATLAB toolbox dependencies beyond Audio Toolbox for `audioread`/`audiowrite`. `backgroundPool` and `parfeval` are base MATLAB (R2021b+).

## Quick Start

```matlab
setup_paths
run_demo
```

Or launch directly:

```matlab
setup_paths
cfg = Config();
cfg.Language = "Armenian";
cfg.LanguageCode = "hy";
app = LiveTranscriptionApp(cfg);
```

## Project Structure

```
Live-Transcription/
├── src/
│   ├── app/           LiveTranscriptionApp.m
│   ├── audio/         MicrophoneCapture, VoiceActivityDetector, Chunker
│   ├── captions/      CaptionBuffer, CaptionMerger
│   ├── providers/     STTProvider, WhisperMatlab, WhisperPython, HuggingFace, Google
│   ├── ui/            FontHelper
│   └── utils/         Config, LanguageRegistry, TempAudioWriter, Utf8File
├── tests/             8 test files
├── python/            Python STT scripts
├── demo/              Demo launchers (live + offline)
├── config/            Default configuration
├── docs/              Architecture, ROADMAP, SPEC
├── setup_paths.m      Path setup
└── README.md
```

## Supported Languages

| Language | Code | Script | Fine-tuned Model |
|----------|------|--------|------------------|
| Arabic | ar | Arabic | — |
| Armenian | hy | Armenian | Chillarmo/whisper-small-hy-AM |
| Chinese | zh | CJK | — |
| Dutch | nl | Latin | — |
| English | en | Latin | — |
| French | fr | Latin | — |
| German | de | Latin | — |
| Greek | el | Greek | — |
| Hebrew | he | Hebrew | ivrit-ai/whisper-v2-d3-e3 |
| Hindi | hi | Devanagari | — |
| Italian | it | Latin | — |
| Japanese | ja | CJK | — |
| Korean | ko | CJK | — |
| Persian | fa | Arabic | — |
| Polish | pl | Latin | — |
| Portuguese | pt | Latin | — |
| Russian | ru | Cyrillic | — |
| Spanish | es | Latin | — |
| Turkish | tr | Latin | — |
| Ukrainian | uk | Cyrillic | — |

All 20 languages are supported by Whisper. Languages with fine-tuned HuggingFace models have better accuracy for that language. Adding a new language requires only a new entry in `LanguageRegistry.m`.

## Running Tests

```matlab
setup_paths
runtests('tests')
```

## Documentation

- [Architecture](docs/architecture.md) — Module diagram, runtime flow, threading model
- [SPEC](docs/SPEC.md) — Technical specification
- [ROADMAP](docs/ROADMAP.md) — Development roadmap
