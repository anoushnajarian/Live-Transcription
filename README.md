# Live Transcription

Real-time speech transcription in MATLAB with multi-language support. Captures microphone audio, runs it through speech-to-text engines, and displays Unicode captions in a uifigure GUI.

## Features

- **Multi-language support** — 15 languages via dropdown: English, Armenian, Spanish, French, German, Russian, Arabic, Chinese, Japanese, Korean, Portuguese, Italian, Turkish, Persian, Hindi
- **Multiple STT providers** — Whisper (native MATLAB), Whisper (Python/faster-whisper), HuggingFace Transformers, Google Cloud Speech
- **Real-time capture** — Dual-timer architecture with voice activity detection and intelligent chunking
- **Unicode captions** — Per-script font selection for non-Latin scripts (Armenian, Arabic, CJK, Cyrillic, Devanagari)
- **Audio buffer recovery** — Recovers audio buffered during blocking STT calls via drain pattern
- **Hallucination filtering** — Catches repetitive Whisper outputs on silence/noise

## Requirements

- MATLAB R2024a or later
- Audio Toolbox
- Python 3.10+ (for Python-based providers)
- `faster-whisper` or `openai-whisper` (for WhisperPythonProvider)
- `transformers`, `torch`, `librosa` (for HuggingFaceProvider)

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
├── tests/             Test suite
├── python/            Python STT scripts
├── demo/              Demo launchers
├── config/            Default configuration
├── docs/              Architecture and documentation
├── setup_paths.m      Path setup
└── README.md
```

## Supported Languages

| Language | Code | Script | Fine-tuned Model |
|----------|------|--------|------------------|
| English | en | Latin | — |
| Armenian | hy | Armenian | Chillarmo/whisper-small-hy-AM |
| Spanish | es | Latin | — |
| French | fr | Latin | — |
| German | de | Latin | — |
| Russian | ru | Cyrillic | — |
| Arabic | ar | Arabic | — |
| Chinese | zh | CJK | — |
| Japanese | ja | CJK | — |
| Korean | ko | CJK | — |
| Portuguese | pt | Latin | — |
| Italian | it | Latin | — |
| Turkish | tr | Latin | — |
| Persian | fa | Arabic | — |
| Hindi | hi | Devanagari | — |

## Running Tests

```matlab
setup_paths
runtests('tests')
```
