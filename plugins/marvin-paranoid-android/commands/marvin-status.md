---
description: "Show Marvin audio clip counts and playlist status"
allowed-tools: ["Bash(ls:*)", "Bash(wc:*)", "Bash(cat:*)"]
---

# Marvin Status

Check how many audio clips are available and playlist status.

Run this to check clip counts:

```!
echo "=== Marvin Audio Clip Inventory ===" && \
echo "Task completion: $(ls "${CLAUDE_PLUGIN_ROOT}/audio"/marvin_[0-9]*.mp3 2>/dev/null | wc -l | tr -d ' ') clips" && \
echo "Session start:   $(ls "${CLAUDE_PLUGIN_ROOT}/audio"/marvin_session_*.mp3 2>/dev/null | wc -l | tr -d ' ') clips" && \
echo "Questions:       $(ls "${CLAUDE_PLUGIN_ROOT}/audio"/marvin_question_*.mp3 2>/dev/null | wc -l | tr -d ' ') clips" && \
echo "Plans:           $(ls "${CLAUDE_PLUGIN_ROOT}/audio"/marvin_plan_*.mp3 2>/dev/null | wc -l | tr -d ' ') clips" && \
echo "Errors:          $(ls "${CLAUDE_PLUGIN_ROOT}/audio"/marvin_error_*.mp3 2>/dev/null | wc -l | tr -d ' ') clips" && \
echo "Permissions:     $(ls "${CLAUDE_PLUGIN_ROOT}/audio"/marvin_permission_*.mp3 2>/dev/null | wc -l | tr -d ' ') clips" && \
echo "---" && \
echo "Total:           $(ls "${CLAUDE_PLUGIN_ROOT}/audio"/marvin_*.mp3 2>/dev/null | wc -l | tr -d ' ') clips" && \
echo "" && \
echo "=== Playlist Status ===" && \
for pl in .playlist .session_playlist .question_playlist .plan_playlist .error_playlist .permission_playlist; do \
  if [ -f "${CLAUDE_PLUGIN_ROOT}/audio/$pl" ]; then \
    remaining=$(wc -l < "${CLAUDE_PLUGIN_ROOT}/audio/$pl" | tr -d ' '); \
    echo "$pl: $remaining clips remaining before reshuffle"; \
  else \
    echo "$pl: not yet initialized"; \
  fi; \
done
```

Report the results to the user. Marvin would be thoroughly depressed by the statistics.
