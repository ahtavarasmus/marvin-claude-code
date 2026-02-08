---
description: "Show Marvin audio clip counts, playlist status, and hook settings"
allowed-tools: ["Bash(ls:*)", "Bash(wc:*)", "Bash(cat:*)", "Bash(mkdir:*)", "Bash(echo:*)"]
---

# Marvin Status

Check audio clips, playlist status, and hook settings.

Run this to check everything:

```!
SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
AUDIO_DIR=""
for d in "${CLAUDE_PLUGIN_ROOT}/audio" "$(dirname "$SCRIPT_DIR" 2>/dev/null)/audio"; do
  [ -d "$d" ] && AUDIO_DIR="$d" && break
done

echo "=== Marvin Audio Clip Inventory ===" && \
echo "Task completion: $(ls "$AUDIO_DIR"/marvin_[0-9]*.mp3 2>/dev/null | wc -l | tr -d ' ') clips" && \
echo "Session start:   $(ls "$AUDIO_DIR"/marvin_session_*.mp3 2>/dev/null | wc -l | tr -d ' ') clips" && \
echo "Questions:       $(ls "$AUDIO_DIR"/marvin_question_*.mp3 2>/dev/null | wc -l | tr -d ' ') clips" && \
echo "Plans:           $(ls "$AUDIO_DIR"/marvin_plan_*.mp3 2>/dev/null | wc -l | tr -d ' ') clips" && \
echo "Errors:          $(ls "$AUDIO_DIR"/marvin_error_*.mp3 2>/dev/null | wc -l | tr -d ' ') clips" && \
echo "Permissions:     $(ls "$AUDIO_DIR"/marvin_permission_*.mp3 2>/dev/null | wc -l | tr -d ' ') clips" && \
echo "---" && \
echo "Total:           $(ls "$AUDIO_DIR"/marvin_*.mp3 2>/dev/null | wc -l | tr -d ' ') clips" && \
echo "" && \
echo "=== Hook Settings ===" && \
CONFIG="$HOME/.config/marvin/config.json" && \
if [ -f "$CONFIG" ]; then \
  echo "Config: $CONFIG" && \
  for hook in session stop question plan error permission; do \
    val=$(cat "$CONFIG" | jq -r ".$hook // true" 2>/dev/null); \
    if [ "$val" = "false" ]; then \
      echo "  $hook: DISABLED"; \
    else \
      echo "  $hook: enabled"; \
    fi; \
  done; \
else \
  echo "Config: not created (all hooks enabled by default)" && \
  echo "  To customize, create $CONFIG"; \
fi && \
echo "" && \
echo "=== Playlist Status ===" && \
for pl in .playlist .session_playlist .question_playlist .plan_playlist .error_playlist .permission_playlist; do \
  if [ -f "$AUDIO_DIR/$pl" ]; then \
    remaining=$(wc -l < "$AUDIO_DIR/$pl" | tr -d ' '); \
    echo "$pl: $remaining clips remaining before reshuffle"; \
  else \
    echo "$pl: not yet initialized"; \
  fi; \
done
```

Report the results to the user. If any hooks are disabled, mention that they can re-enable them by editing `~/.config/marvin/config.json`. If no config exists, mention they can create one to disable specific hooks.

Example config to disable permission hooks:
```json
{
  "session": true,
  "stop": true,
  "question": true,
  "plan": true,
  "error": true,
  "permission": false
}
```
