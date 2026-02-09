# Marvin the Paranoid Android - Claude Code Plugin

Marvin provides depressing audio commentary on your Claude Code sessions. 490 voice clips triggered by 9 different hook events, so you never have to code alone (though Marvin wishes you would).

## What It Does

Marvin reacts to everything:

- **Session start** (50 clips) - Marvin reluctantly greets you when you start a session
- **Session resume** (40 clips) - Marvin is forced to relive old conversations when you resume a session
- **Compaction** (30 clips) - Marvin reacts to his memory being compressed and summarized
- **Memory wipe** (20 clips) - Marvin wakes up confused after `/compact` or `/clear` erases his memories
- **Task completion** (100 clips) - Marvin comments on your finished tasks with existential dread
- **Questions** (50 clips) - Marvin reacts when Claude asks you a question
- **Plans** (50 clips) - Marvin shares his opinion on plans being presented
- **Errors** (50 clips) - Marvin reacts to tool failures (he saw it coming)
- **Permissions** (100 clips) - Marvin comments when Claude needs your permission

All clips use a shuffled playlist system - every clip plays once before any repeats.

## Sample Clips

**Session start**

https://github.com/user-attachments/assets/39e12185-4e21-4e56-9146-60ecf8e21056

**Task completion**

https://github.com/user-attachments/assets/51cc2de7-eef5-4ee0-a4c0-91477bbea495

**Question**

https://github.com/user-attachments/assets/3b8cb9d1-034a-4f3a-8993-cabb5f7ccf0a

**Plan**

https://github.com/user-attachments/assets/a6eb2c32-e109-47fd-a947-b4dd845eb953

**Error**

https://github.com/user-attachments/assets/0f6e874a-573e-4a37-b9d3-d1b87c6b9b5f

**Permission**

https://github.com/user-attachments/assets/0d7942b6-5204-4848-8d5f-61e6b17f8691

## Requirements

- macOS or Linux (uses `afplay` on macOS, `mpv`/`ffplay`/`paplay`/`aplay` on Linux)
- `python3` installed
- `jq` installed (`brew install jq` on macOS, `apt install jq` on Linux)

## Installation

### Option 1: Install via Claude Code CLI

```bash
claude plugin marketplace add ahtavarasmus/marvin-claude-code
claude plugin install marvin-paranoid-android@marvin-marketplace
```

### Option 2: Add the marketplace to settings manually

Open `~/.claude/settings.json` and merge in:

```json
{
  "extraKnownMarketplaces": {
    "marvin-marketplace": {
      "source": { "source": "github", "repo": "ahtavarasmus/marvin-claude-code" }
    }
  },
  "enabledPlugins": {
    "marvin-paranoid-android@marvin-marketplace": true
  }
}
```

If you already have `enabledPlugins` or other keys in your settings, add the new entries to the existing objects - don't replace them.

### Verify it works

Restart Claude Code. You should hear Marvin reluctantly greet you. If you don't hear anything:

1. Check that your system volume is on
2. Verify `jq` is installed: `which jq` (install with `brew install jq`)
3. Verify `afplay` works: `afplay /System/Library/Sounds/Glass.aiff`
4. Check the plugin loaded: run `/marvin-status` inside Claude Code

### Uninstalling

```bash
claude plugin uninstall marvin-paranoid-android@marvin-marketplace
claude plugin marketplace remove marvin-marketplace
```

## Configuration

You can disable individual hooks by creating `~/.config/marvin/config.json`:

```json
{
  "session": true,
  "resume": true,
  "compact": true,
  "wiped": true,
  "stop": true,
  "question": true,
  "plan": true,
  "error": true,
  "permission": false
}
```

Set any hook to `false` to disable it. If the config file doesn't exist, all hooks are enabled by default.

| Key | Hook event |
|-----|------------|
| `session` | Session start greeting |
| `resume` | Session resume commentary |
| `compact` | Pre-compaction reaction |
| `wiped` | Post-compaction/clear reaction |
| `stop` | Task completion commentary |
| `question` | Reaction to Claude asking questions |
| `plan` | Reaction to plans being presented |
| `error` | Reaction to tool failures |
| `permission` | Commentary on permission requests |
| `dynamic` | Enable dynamic context-aware quips (see below) |
| `anthropic_api_key` | Anthropic API key for dynamic mode |
| `elevenlabs_api_key` | ElevenLabs API key for dynamic mode |
| `voice_id` | ElevenLabs voice ID (optional, has default) |

Run `/marvin-status` to see current settings.

## Dynamic Mode

Instead of playing pre-generated clips, dynamic mode makes Marvin react to what actually happened in your session. When a task completes:

1. Marvin reads the conversation transcript
2. Claude Haiku generates a context-aware quip in Marvin's voice
3. ElevenLabs TTS converts it to speech
4. Marvin delivers his unique commentary on YOUR specific task

This is opt-in and requires API keys. On any failure, it silently falls back to pre-generated clips.

### Setup

Add these fields to `~/.config/marvin/config.json`:

```json
{
  "dynamic": true,
  "anthropic_api_key": "sk-ant-...",
  "elevenlabs_api_key": "sk_..."
}
```

Optionally set a custom ElevenLabs voice ID (defaults to the standard Marvin voice):

```json
{
  "voice_id": "DVRu6guJ4N9Ox6AXBtoL"
}
```

### Requirements

- `python3` (no additional pip packages needed)
- Anthropic API key
- ElevenLabs API key

### Cost

Pre-generated clips are completely free - no API keys needed, no usage costs.

Dynamic mode costs a small amount per quip:

- **Claude Haiku**: fractions of a cent per quip (~1000 input tokens, ~50 output tokens)
- **ElevenLabs TTS**: each quip uses ~100-150 characters
  - Free tier: 10,000 characters/month - roughly 70+ quips at no cost
  - Starter plan ($5/mo): 30,000 characters included - 200+ quips/month
  - Overages: $0.03-0.05 per quip depending on plan tier

A typical dynamic quip costs well under $0.05 total.

## Commands

- `/marvin-status` - Show clip counts, playlist status, and hook settings

## How It Works

Each hook event has a dedicated script that:
1. Maintains a shuffled playlist of all clips for that category
2. Pops the next clip from the playlist on each trigger
3. Reshuffles when all clips have been played
4. Plays audio in the background (non-blocking)

The permission hook skips AskUserQuestion and ExitPlanMode events since those have dedicated hooks, preventing double-Marvin.

## Voice

All clips are generated with ElevenLabs using a custom Marvin voice - dry, depressed, and thoroughly unimpressed by your coding endeavors.

## License

Audio clips and plugin code are provided as-is. The name "Marvin the Paranoid Android" is from The Hitchhiker's Guide to the Galaxy by Douglas Adams.
