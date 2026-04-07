#!/usr/bin/env python3
"""
Speech transcription using faster-whisper.
Called by MATLAB WhisperPythonProvider.

Usage:
    python whisper_transcribe.py <wav_path> --model small --language en
    
Output: JSON to stdout
    {"text": "transcribed text", "start_time": 0.0, "end_time": 2.5, "segments": [...]}
"""

import argparse
import json
import sys
import os


def transcribe(wav_path, model_size="small", language="en", device="cpu"):
    """Transcribe a WAV file using faster-whisper."""
    try:
        from faster_whisper import WhisperModel
    except ImportError:
        # Fallback to openai-whisper
        try:
            import whisper
            model = whisper.load_model(model_size)
            result = model.transcribe(wav_path, language=language)
            output = {
                "text": result["text"].strip(),
                "start_time": 0.0,
                "end_time": result.get("duration", 0.0) if isinstance(result, dict) else 0.0,
                "segments": []
            }
            print(json.dumps(output, ensure_ascii=False))
            return
        except ImportError:
            error = {
                "error": "Neither faster-whisper nor openai-whisper is installed. "
                         "Install with: pip install faster-whisper"
            }
            print(json.dumps(error), file=sys.stderr)
            sys.exit(1)
    
    # Use faster-whisper
    compute_type = "int8" if device == "cpu" else "float16"
    model = WhisperModel(model_size, device=device, compute_type=compute_type)
    
    segments_list = []
    full_text = []
    start_time = None
    end_time = 0.0
    
    segments, info = model.transcribe(
        wav_path, 
        language=language,
        beam_size=5,
        vad_filter=True
    )
    
    for segment in segments:
        if start_time is None:
            start_time = segment.start
        end_time = segment.end
        full_text.append(segment.text.strip())
        segments_list.append({
            "start": segment.start,
            "end": segment.end,
            "text": segment.text.strip()
        })
    
    output = {
        "text": " ".join(full_text),
        "start_time": start_time if start_time is not None else 0.0,
        "end_time": end_time,
        "language": info.language,
        "language_probability": info.language_probability,
        "segments": segments_list
    }
    
    print(json.dumps(output, ensure_ascii=False))


def main():
    parser = argparse.ArgumentParser(description="Transcribe speech using Whisper")
    parser.add_argument("wav_path", help="Path to the WAV file")
    parser.add_argument("--model", default="small",
                        choices=["tiny", "base", "small", "medium", "large-v2", "large-v3"],
                        help="Whisper model size (default: small)")
    parser.add_argument("--language", default="en",
                        help="Language code, e.g. en, hy, es, fr (default: en)")
    parser.add_argument("--device", default="cpu", choices=["cpu", "cuda"], 
                        help="Compute device (default: cpu)")
    
    args = parser.parse_args()
    
    if not os.path.isfile(args.wav_path):
        print(json.dumps({"error": f"File not found: {args.wav_path}"}), file=sys.stderr)
        sys.exit(1)
    
    transcribe(args.wav_path, args.model, args.language, args.device)


if __name__ == "__main__":
    main()
