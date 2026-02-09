#!/bin/bash
# Marvin the Paranoid Android - stop hook
# Marvin comments on your completed tasks with existential despair.
# Uses a shuffled playlist so every clip plays before any repeats.

# Read stdin (stop hook input) and check for loop prevention
input=$(cat)
stop_hook_active=$(echo "$input" | jq -r '.stop_hook_active // false')
if [ "$stop_hook_active" = "true" ]; then
    exit 0
fi

# Check config - skip if disabled
CONFIG="$HOME/.config/marvin/config.json"
if [ -f "$CONFIG" ] && [ "$(jq -r '.stop // true' "$CONFIG" 2>/dev/null)" = "false" ]; then
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AUDIO_DIR="$(dirname "$SCRIPT_DIR")/audio"
PLAYLIST="$AUDIO_DIR/.playlist"

# Dynamic mode: generate context-aware quip via LLM + TTS
dynamic=$(jq -r '.dynamic // false' "$CONFIG" 2>/dev/null)
anthropic_key=$(jq -r '.anthropic_api_key // ""' "$CONFIG" 2>/dev/null)
elevenlabs_key=$(jq -r '.elevenlabs_api_key // ""' "$CONFIG" 2>/dev/null)
transcript_path=$(echo "$input" | jq -r '.transcript_path // ""')

if [ "$dynamic" = "true" ] && [ -n "$anthropic_key" ] && [ -n "$elevenlabs_key" ] && [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    # Skip if a dynamic generation is already running for this session
    LOCK="/tmp/marvin-dynamic-$PPID.lock"
    if [ -f "$LOCK" ] && kill -0 "$(cat "$LOCK" 2>/dev/null)" 2>/dev/null; then
        exit 0
    fi
    # Use python to start a fully detached process in a new session
    # (bash disown/nohup aren't enough - process gets killed when Claude exits)
    python3 -c "
import subprocess, os
p = subprocess.Popen(
    ['python3', '$SCRIPT_DIR/marvin-dynamic.py', '$transcript_path', '$SCRIPT_DIR', '$AUDIO_DIR'],
    stdin=subprocess.DEVNULL,
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
    start_new_session=True
)
with open('$LOCK', 'w') as f:
    f.write(str(p.pid))
"
    exit 0
fi

# Fallback: pre-generated clips with shuffled playlist
if [ ! -s "$PLAYLIST" ]; then
    ls "$AUDIO_DIR"/marvin_[0-9]*.mp3 2>/dev/null | sort -R > "$PLAYLIST"
fi

clip=$(head -1 "$PLAYLIST")
tail -n +2 "$PLAYLIST" > "$PLAYLIST.tmp" && mv "$PLAYLIST.tmp" "$PLAYLIST"

if [ -n "$clip" ] && [ -f "$clip" ]; then
    "$SCRIPT_DIR/marvin-play.sh" "$clip" "$AUDIO_DIR/.marvin_pid"
fi

exit 0
