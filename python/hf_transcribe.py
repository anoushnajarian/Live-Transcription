#!/usr/bin/env python3
"""
Speech transcription using HuggingFace Transformers.
Called by MATLAB HuggingFaceProvider.

Usage:
    python hf_transcribe.py <wav_path> --model openai/whisper-medium --language en
    
Output: JSON to stdout
    {"text": "transcribed text", "start_time": 0.0, "end_time": 2.5, "segments": [...]}
"""

import argparse
import json
import sys
import os


def transcribe(wav_path, model_name="openai/whisper-medium", language="en", device="cpu"):
    """Transcribe a WAV file using HuggingFace Transformers."""
    try:
        import torch
        from transformers import AutoProcessor, AutoModelForSpeechSeq2Seq
        import librosa
    except ImportError as e:
        error = {
            "error": f"Missing dependency: {e}. "
                     "Install with: pip install transformers torch librosa"
        }
        print(json.dumps(error), file=sys.stderr)
        sys.exit(1)

    # Load audio at 16kHz
    audio, sr = librosa.load(wav_path, sr=16000)
    duration = len(audio) / sr

    # Select dtype based on device
    torch_dtype = torch.float16 if device == "cuda" else torch.float32

    # Load model and processor
    processor = AutoProcessor.from_pretrained(model_name)
    model = AutoModelForSpeechSeq2Seq.from_pretrained(
        model_name,
        torch_dtype=torch_dtype,
    ).to(device)

    # Prepare inputs
    inputs = processor(
        audio,
        sampling_rate=16000,
        return_tensors="pt",
    ).to(device)

    if torch_dtype == torch.float16:
        inputs.input_features = inputs.input_features.half()

    # Generate transcription with language forcing
    forced_decoder_ids = processor.get_decoder_prompt_ids(
        language=language, task="transcribe")
    generated_ids = model.generate(
        inputs.input_features,
        forced_decoder_ids=forced_decoder_ids,
        max_new_tokens=448,
    )

    text = processor.batch_decode(generated_ids, skip_special_tokens=True)[0].strip()

    output = {
        "text": text,
        "start_time": 0.0,
        "end_time": duration,
        "segments": [
            {
                "start": 0.0,
                "end": duration,
                "text": text
            }
        ]
    }

    print(json.dumps(output, ensure_ascii=False))


def main():
    parser = argparse.ArgumentParser(
        description="Transcribe speech using HuggingFace Transformers")
    parser.add_argument("wav_path", help="Path to the WAV file")
    parser.add_argument("--model", default="openai/whisper-medium",
                        help="HuggingFace model name (default: openai/whisper-medium)")
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
