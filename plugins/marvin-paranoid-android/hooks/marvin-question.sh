#!/bin/bash
# Marvin reacts when Claude asks the user a question
# Uses shuffled playlist (same approach as other hooks)

input=$(cat)

AUDIO_DIR="${CLAUDE_PLUGIN_ROOT}/audio"
PLAYLIST="$AUDIO_DIR/.question_playlist"

if [ ! -s "$PLAYLIST" ]; then
    ls "$AUDIO_DIR"/marvin_question_*.mp3 2>/dev/null | sort -R > "$PLAYLIST"
fi

clip=$(head -1 "$PLAYLIST")
tail -n +2 "$PLAYLIST" > "$PLAYLIST.tmp" && mv "$PLAYLIST.tmp" "$PLAYLIST"

if [ -n "$clip" ] && [ -f "$clip" ]; then
    afplay "$clip" &
fi

exit 0
