# Roadmap

## Current State

Multi-language live transcription app with 20 languages, 4 STT providers, dual-timer architecture, VAD, hallucination filtering, buffer drain recovery, per-script font selection, and 8 test files.

## Phase 1 — Stabilize & Test

- [ ] Run full test suite across MATLAB versions, fix any failures
- [ ] Add CI pipeline (GitHub Actions or GitLab CI)
- [ ] End-to-end testing with non-English languages (Armenian, Hebrew, Spanish, Chinese)
- [ ] Register more fine-tuned HuggingFace models per language
- [ ] Document provider setup guides (Whisper model download, Python dependencies, Google API key)

## Phase 2 — Reduce Latency

- [ ] Whisper `turbo` model support (8x faster than large, similar accuracy)
- [ ] GPU acceleration for Python providers (`--device cuda`)
- [ ] Benchmark latency per provider × language × model size
- [ ] Investigate MATLAB `speechClient` with smaller models for faster sync path
- [ ] Tune chunk durations based on latency benchmarks

## Phase 3 — Export & Usability

- [ ] SRT subtitle file export (timestamped)
- [ ] JSON transcript export with per-chunk timing
- [ ] Transcript search/filter in UI
- [ ] Auto-scroll transcript area to latest caption
- [ ] Dark/light theme toggle
- [ ] Configurable caption font size via UI slider
- [ ] Remember last-used language/provider/device across sessions

## Phase 4 — Streaming STT

The path to true "live captions" — sub-second latency.

- [ ] Streaming API integration (Google Cloud Streaming, Azure Speech, Deepgram)
- [ ] Partial/interim results displayed as they arrive
- [ ] Replace chunk-based flow with continuous streaming for supported providers
- [ ] Fallback to chunk-based for providers without streaming support
- [ ] Sub-second latency target for streaming providers

## Phase 5 — Advanced Features

- [ ] Speaker diarization (identify who is talking)
- [ ] Translation mode (Whisper `task="translate"` for non-English → English)
- [ ] Batch transcription mode for pre-recorded audio files
- [ ] Standalone `.exe` compilation via `mcc` for distribution
- [ ] Multi-microphone / audio device hot-switching
