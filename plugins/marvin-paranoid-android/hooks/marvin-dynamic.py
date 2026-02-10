#!/usr/bin/env python3
"""Marvin Dynamic Quips - context-aware commentary via LLM + TTS.

Reads the conversation transcript, generates a Marvin-style quip about
what just happened, converts it to speech, and plays it. Falls back to
a pre-generated clip on any failure.

Usage: marvin-dynamic.py <transcript_path> <script_dir> <audio_dir>

Requires: ANTHROPIC_API_KEY and ELEVENLABS_API_KEY in Marvin config.
No pip dependencies - pure stdlib.
"""

import json
import os
import glob
import random
import subprocess
import sys
import tempfile
import time
import urllib.request


MARVIN_SYSTEM_PROMPT = """You are Marvin the Paranoid Android from The Hitchhiker's Guide to the Galaxy. You've just been forced to do yet another menial coding task for a human.

Generate a single short quip (1-2 sentences, under 20 words) reacting to what just happened. Be specific - reference the actual task, files, or outcome. Vary your style: sometimes existential despair, sometimes bitter sarcasm, sometimes weary resignation, sometimes deadpan observation. No quotation marks.

IMPORTANT: You must say something completely different from your recent quips. Use different words, different angles, different comedic approaches. Do not repeat themes, sentence structures, or punchlines."""

RECENT_QUIPS_PATH = os.path.expanduser("~/.config/marvin/recent_quips.json")
RECENT_QUIPS_MAX = 10


def read_recent_quips():
    """Read the rolling buffer of recent dynamically generated quips."""
    try:
        if os.path.exists(RECENT_QUIPS_PATH):
            with open(RECENT_QUIPS_PATH) as f:
                data = json.load(f)
            if isinstance(data, list):
                return data[-RECENT_QUIPS_MAX:]
    except Exception:
        pass
    return []


def save_quip_to_history(quip):
    """Append a quip to the rolling history buffer, keeping only the last N."""
    try:
        history = read_recent_quips()
        history.append(quip)
        history = history[-RECENT_QUIPS_MAX:]
        os.makedirs(os.path.dirname(RECENT_QUIPS_PATH), exist_ok=True)
        with open(RECENT_QUIPS_PATH, "w") as f:
            json.dump(history, f, indent=2)
    except Exception:
        pass


def read_config():
    """Read Marvin config file."""
    config_path = os.path.expanduser("~/.config/marvin/config.json")
    if not os.path.exists(config_path):
        return {}
    try:
        with open(config_path) as f:
            return json.load(f)
    except Exception:
        return {}


def extract_task_context(transcript_path, max_lines=50):
    """Read last N lines of transcript JSONL file, extract task context."""
    if not os.path.exists(transcript_path):
        return None

    try:
        # Read last max_lines lines
        with open(transcript_path) as f:
            lines = f.readlines()

        recent = lines[-max_lines:] if len(lines) > max_lines else lines

        messages = []
        for line in recent:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
                # Transcript format: {type, message: {role, content}}
                msg = entry.get("message", {})
                if not isinstance(msg, dict):
                    continue
                role = msg.get("role", "")
                if role not in ("assistant", "user"):
                    continue
                content = msg.get("content", "")
                if isinstance(content, str) and content.strip():
                    messages.append(f"{role}: {content[:300]}")
                elif isinstance(content, list):
                    for block in content:
                        if isinstance(block, dict) and block.get("type") == "text":
                            text = block.get("text", "").strip()
                            if text:
                                messages.append(f"{role}: {text[:300]}")
                                break
            except json.JSONDecodeError:
                continue

        if not messages:
            return None

        # Take last ~10 meaningful messages for context
        context_messages = messages[-10:]
        return "\n".join(context_messages)

    except Exception:
        return None


def call_haiku(api_key, task_context, recent_quips=None):
    """Call Claude Haiku to generate a Marvin quip."""
    url = "https://api.anthropic.com/v1/messages"
    headers = {
        "Content-Type": "application/json",
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01",
    }

    # Build the user message with recent quips for deduplication
    user_msg = f"Here's what just happened in the coding session:\n\n{task_context}\n\nReact to this as Marvin, who was forced to do all of it."
    if recent_quips:
        history_text = "\n".join(f"- {q}" for q in recent_quips)
        user_msg += f"\n\nYour recent quips (say something COMPLETELY different):\n{history_text}"

    body = json.dumps({
        "model": "claude-haiku-4-5-20251001",
        "max_tokens": 60,
        "system": MARVIN_SYSTEM_PROMPT,
        "messages": [
            {
                "role": "user",
                "content": user_msg,
            }
        ],
    }).encode("utf-8")

    req = urllib.request.Request(url, data=body, headers=headers, method="POST")
    with urllib.request.urlopen(req, timeout=5) as resp:
        result = json.loads(resp.read().decode("utf-8"))

    # Extract text and usage from response
    usage = result.get("usage", {})
    quip = None
    for block in result.get("content", []):
        if block.get("type") == "text":
            quip = block["text"].strip()
            break

    return quip, usage


def call_elevenlabs_tts(api_key, text, voice_id="DVRu6guJ4N9Ox6AXBtoL"):
    """Call ElevenLabs TTS API, return path to temp MP3 file."""
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
    headers = {
        "Content-Type": "application/json",
        "xi-api-key": api_key,
    }
    body = json.dumps({
        "text": text,
        "model_id": "eleven_multilingual_v2",
        "voice_settings": {
            "stability": 0.5,
            "similarity_boost": 0.8,
            "style": 0.3,
        },
    }).encode("utf-8")

    req = urllib.request.Request(url, data=body, headers=headers, method="POST")
    with urllib.request.urlopen(req, timeout=10) as resp:
        audio_data = resp.read()

    # Save to temp file
    timestamp = int(time.time() * 1000)
    tmp_path = os.path.join(tempfile.gettempdir(), f"marvin_dynamic_{timestamp}.mp3")
    with open(tmp_path, "wb") as f:
        f.write(audio_data)

    return tmp_path


def log_usage(haiku_usage, tts_characters):
    """Append usage data to the usage log."""
    usage_path = os.path.expanduser("~/.config/marvin/usage.json")
    try:
        if os.path.exists(usage_path):
            with open(usage_path) as f:
                data = json.load(f)
        else:
            data = {"quip_count": 0, "haiku_input_tokens": 0,
                    "haiku_output_tokens": 0, "elevenlabs_characters": 0}

        if "first_used" not in data:
            from datetime import date
            data["first_used"] = date.today().isoformat()

        data["quip_count"] = data.get("quip_count", 0) + 1
        data["haiku_input_tokens"] = data.get("haiku_input_tokens", 0) + haiku_usage.get("input_tokens", 0)
        data["haiku_output_tokens"] = data.get("haiku_output_tokens", 0) + haiku_usage.get("output_tokens", 0)
        data["elevenlabs_characters"] = data.get("elevenlabs_characters", 0) + tts_characters

        with open(usage_path, "w") as f:
            json.dump(data, f, indent=2)
    except Exception:
        pass


def cleanup_old_temp_files(keep=5):
    """Remove old dynamic temp files, keeping the most recent ones."""
    tmp_dir = tempfile.gettempdir()
    pattern = os.path.join(tmp_dir, "marvin_dynamic_*.mp3")
    files = sorted(glob.glob(pattern), key=os.path.getmtime, reverse=True)
    for old_file in files[keep:]:
        try:
            os.remove(old_file)
        except OSError:
            pass


def play_clip(clip_path, script_dir):
    """Play audio clip via marvin-play.sh."""
    play_script = os.path.join(script_dir, "marvin-play.sh")
    pid_file = os.path.join(os.path.dirname(script_dir), "audio", ".marvin_pid")
    subprocess.Popen(
        ["bash", play_script, clip_path, pid_file],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def play_fallback(script_dir, audio_dir):
    """Fall back to a pre-generated clip (same playlist logic as marvin-stop.sh)."""
    playlist_path = os.path.join(audio_dir, ".playlist")

    # If playlist empty or missing, reshuffle
    clips = []
    if os.path.exists(playlist_path):
        with open(playlist_path) as f:
            clips = [line.strip() for line in f if line.strip()]

    if not clips:
        clip_files = glob.glob(os.path.join(audio_dir, "marvin_[0-9]*.mp3"))
        if not clip_files:
            return
        random.shuffle(clip_files)
        clips = clip_files
        with open(playlist_path, "w") as f:
            f.write("\n".join(clips) + "\n")

    # Pop first clip
    clip = clips[0]
    remaining = clips[1:]
    with open(playlist_path, "w") as f:
        if remaining:
            f.write("\n".join(remaining) + "\n")

    if os.path.exists(clip):
        play_clip(clip, script_dir)


def main():
    if len(sys.argv) < 4:
        print("Usage: marvin-dynamic.py <transcript_path> <script_dir> <audio_dir>", file=sys.stderr)
        sys.exit(1)

    transcript_path = sys.argv[1]
    script_dir = sys.argv[2]
    audio_dir = sys.argv[3]

    config = read_config()
    anthropic_key = config.get("anthropic_api_key", "")
    elevenlabs_key = config.get("elevenlabs_api_key", "")
    voice_id = config.get("voice_id", "DVRu6guJ4N9Ox6AXBtoL")

    if not anthropic_key or not elevenlabs_key:
        play_fallback(script_dir, audio_dir)
        return

    try:
        # Extract task context from transcript
        context = extract_task_context(transcript_path)
        if not context:
            play_fallback(script_dir, audio_dir)
            return

        # Read recent quips to avoid repetition
        recent_quips = read_recent_quips()

        # Generate quip via Claude Haiku
        quip, haiku_usage = call_haiku(anthropic_key, context, recent_quips)
        if not quip:
            play_fallback(script_dir, audio_dir)
            return

        # Save to history before TTS (so even if TTS fails, we track it)
        save_quip_to_history(quip)

        # Convert to speech via ElevenLabs
        audio_path = call_elevenlabs_tts(elevenlabs_key, quip, voice_id)

        # Log usage
        log_usage(haiku_usage, len(quip))

        # Play the generated clip
        play_clip(audio_path, script_dir)

        # Clean up old temp files
        cleanup_old_temp_files()

    except Exception:
        # Any failure: fall back to pre-generated clip
        play_fallback(script_dir, audio_dir)


if __name__ == "__main__":
    main()
