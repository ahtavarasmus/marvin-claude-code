# Contributing Clips

Want to add more of Marvin's misery? Here's how.

## Voice Settings

All clips use ElevenLabs TTS:

- **Voice ID:** `DVRu6guJ4N9Ox6AXBtoL`
- **Model:** `eleven_multilingual_v2`
- **Settings:** stability 0.5, similarity_boost 0.8, style 0.3

You'll need your own [ElevenLabs API key](https://elevenlabs.io).

## Generating Clips

```bash
curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/DVRu6guJ4N9Ox6AXBtoL" \
    -H "xi-api-key: YOUR_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "text": "Your depressing Marvin quote here.",
        "model_id": "eleven_multilingual_v2",
        "voice_settings": {
            "stability": 0.5,
            "similarity_boost": 0.8,
            "style": 0.3
        }
    }' \
    --output marvin_category_XX.mp3
```

## File Naming

Clips go in `plugins/marvin-paranoid-android/audio/` with this naming:

| Category | Pattern | Hook event |
|----------|---------|------------|
| Task completion | `marvin_01.mp3` ... `marvin_100.mp3` | Stop |
| Session start | `marvin_session_XX.mp3` | SessionStart (startup) |
| Session resume | `marvin_resume_XX.mp3` | SessionStart (resume) |
| Compaction | `marvin_compact_XX.mp3` | PreCompact |
| Memory wipe | `marvin_wiped_XX.mp3` | SessionStart (compact/clear) |
| Questions | `marvin_question_XX.mp3` | PreToolUse (AskUserQuestion) |
| Plans | `marvin_plan_XX.mp3` | PreToolUse (ExitPlanMode) |
| Errors | `marvin_error_XX.mp3` | PostToolUseFailure |
| Permissions | `marvin_permission_XX.mp3` | PermissionRequest |

Number new clips starting after the last existing one (e.g. if `marvin_session_50.mp3` exists, start at `marvin_session_51.mp3`).

## Submitting

1. Fork the repo
2. Add your clips to the audio directory
3. Open a PR with a list of the quotes you added

Keep the tone consistent - dry, depressed, existentially exhausted. Marvin doesn't do enthusiasm.
