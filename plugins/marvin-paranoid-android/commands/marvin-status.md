---
description: "Show Marvin audio clip counts, playlist status, and hook settings"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/hooks/marvin-status.sh:*)"]
---

# Marvin Status

Run the status script:

```!
${CLAUDE_PLUGIN_ROOT}/hooks/marvin-status.sh
```

Report the results to the user. If any hooks are disabled, mention they can re-enable them by editing `~/.config/marvin/config.json`. If no config exists, mention they can create one to disable specific hooks.

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
