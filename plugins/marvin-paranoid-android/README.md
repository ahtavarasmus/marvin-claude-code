# Marvin the Paranoid Android - Claude Code Plugin

Marvin provides depressing audio commentary on your Claude Code sessions. 400 voice clips triggered by 6 different hook events, so you never have to code alone (though Marvin wishes you would).

## What It Does

Marvin reacts to everything:

- **Session start** (50 clips) - Marvin reluctantly greets you when you start a session
- **Task completion** (100 clips) - Marvin comments on your finished tasks with existential dread
- **Questions** (50 clips) - Marvin reacts when Claude asks you a question
- **Plans** (50 clips) - Marvin shares his opinion on plans being presented
- **Errors** (50 clips) - Marvin reacts to tool failures (he saw it coming)
- **Permissions** (100 clips) - Marvin comments when Claude needs your permission

All clips use a shuffled playlist system - every clip plays once before any repeats.

## Requirements

- macOS (uses `afplay` for audio playback)
- `jq` installed (`brew install jq`)

## Installation

Add to your `~/.claude/settings.json`:

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

Then restart Claude Code. Marvin will greet you on session start.

## Commands

- `/marvin-status` - Show clip counts and playlist status

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
