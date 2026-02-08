#!/bin/bash
# Marvin status - show clip counts, playlist status, and hook settings

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AUDIO_DIR="$(dirname "$SCRIPT_DIR")/audio"

echo "=== Marvin Audio Clip Inventory ==="
echo "Task completion: $(ls "$AUDIO_DIR"/marvin_[0-9]*.mp3 2>/dev/null | wc -l | tr -d ' ') clips"
echo "Session start:   $(ls "$AUDIO_DIR"/marvin_session_*.mp3 2>/dev/null | wc -l | tr -d ' ') clips"
echo "Session resume:  $(ls "$AUDIO_DIR"/marvin_resume_*.mp3 2>/dev/null | wc -l | tr -d ' ') clips"
echo "Questions:       $(ls "$AUDIO_DIR"/marvin_question_*.mp3 2>/dev/null | wc -l | tr -d ' ') clips"
echo "Plans:           $(ls "$AUDIO_DIR"/marvin_plan_*.mp3 2>/dev/null | wc -l | tr -d ' ') clips"
echo "Errors:          $(ls "$AUDIO_DIR"/marvin_error_*.mp3 2>/dev/null | wc -l | tr -d ' ') clips"
echo "Permissions:     $(ls "$AUDIO_DIR"/marvin_permission_*.mp3 2>/dev/null | wc -l | tr -d ' ') clips"
echo "Compaction:      $(ls "$AUDIO_DIR"/marvin_compact_*.mp3 2>/dev/null | wc -l | tr -d ' ') clips"
echo "Memory wipe:     $(ls "$AUDIO_DIR"/marvin_wiped_*.mp3 2>/dev/null | wc -l | tr -d ' ') clips"
echo "---"
echo "Total:           $(ls "$AUDIO_DIR"/marvin_*.mp3 2>/dev/null | wc -l | tr -d ' ') clips"
echo ""

echo "=== Hook Settings ==="
CONFIG="$HOME/.config/marvin/config.json"
if [ -f "$CONFIG" ]; then
    echo "Config: $CONFIG"
    for hook in session resume compact wiped stop question plan error permission; do
        val=$(jq -r ".$hook // true" "$CONFIG" 2>/dev/null)
        if [ "$val" = "false" ]; then
            echo "  $hook: DISABLED"
        else
            echo "  $hook: enabled"
        fi
    done
else
    echo "Config: not created (all hooks enabled by default)"
    echo "  To customize, create $CONFIG"
fi
echo ""

echo "=== Playlist Status ==="
for pl in .playlist .session_playlist .resume_playlist .compact_playlist .wiped_playlist .question_playlist .plan_playlist .error_playlist .permission_playlist; do
    if [ -f "$AUDIO_DIR/$pl" ]; then
        remaining=$(wc -l < "$AUDIO_DIR/$pl" | tr -d ' ')
        echo "$pl: $remaining clips remaining before reshuffle"
    else
        echo "$pl: not yet initialized"
    fi
done
