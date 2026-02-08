#!/bin/bash
# Marvin reacts when permission is requested
# Skips AskUserQuestion and ExitPlanMode (they have dedicated hooks)
# Uses shuffled playlist (same approach as other hooks)

input=$(cat)

# Skip if this is an AskUserQuestion or ExitPlanMode - they have their own hooks
tool_name=$(echo "$input" | jq -r '.tool_name // .tool // ""' 2>/dev/null)
if [ "$tool_name" = "AskUserQuestion" ] || [ "$tool_name" = "ExitPlanMode" ]; then
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AUDIO_DIR="$(dirname "$SCRIPT_DIR")/audio"
PLAYLIST="$AUDIO_DIR/.permission_playlist"

if [ ! -s "$PLAYLIST" ]; then
    ls "$AUDIO_DIR"/marvin_permission_*.mp3 2>/dev/null | sort -R > "$PLAYLIST"
fi

clip=$(head -1 "$PLAYLIST")
tail -n +2 "$PLAYLIST" > "$PLAYLIST.tmp" && mv "$PLAYLIST.tmp" "$PLAYLIST"

if [ -n "$clip" ] && [ -f "$clip" ]; then
    afplay "$clip" &
fi

exit 0
