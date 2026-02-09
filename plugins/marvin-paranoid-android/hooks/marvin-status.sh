#!/bin/bash
# Marvin status - show clip counts, playlist status, and hook settings

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AUDIO_DIR="$(dirname "$SCRIPT_DIR")/audio"

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
    pdelay=$(jq -r '.permission_delay // 5' "$CONFIG" 2>/dev/null)
    echo "  permission_delay: ${pdelay}s"
else
    echo "Config: not created (all hooks enabled by default)"
    echo "  To customize, create $CONFIG"
fi
echo ""

echo "=== Dynamic Mode (stop hook only, other hooks use free pre-generated clips) ==="
if [ -f "$CONFIG" ]; then
    dyn=$(jq -r '.dynamic // false' "$CONFIG" 2>/dev/null)
    if [ "$dyn" = "true" ]; then
        echo "  dynamic: ENABLED"
    else
        echo "  dynamic: disabled"
    fi
    akey=$(jq -r '.anthropic_api_key // ""' "$CONFIG" 2>/dev/null)
    if [ -n "$akey" ]; then
        echo "  anthropic_api_key: set"
    else
        echo "  anthropic_api_key: not set"
    fi
    ekey=$(jq -r '.elevenlabs_api_key // ""' "$CONFIG" 2>/dev/null)
    if [ -n "$ekey" ]; then
        echo "  elevenlabs_api_key: set"
    else
        echo "  elevenlabs_api_key: not set"
    fi
    vid=$(jq -r '.voice_id // ""' "$CONFIG" 2>/dev/null)
    if [ -n "$vid" ]; then
        echo "  voice_id: $vid"
    else
        echo "  voice_id: default (DVRu6guJ4N9Ox6AXBtoL)"
    fi
else
    echo "  dynamic: disabled (no config)"
fi
echo ""

USAGE="$HOME/.config/marvin/usage.json"
if [ -f "$USAGE" ]; then
    echo "=== Dynamic Mode Usage ==="
    quips=$(jq -r '.quip_count // 0' "$USAGE" 2>/dev/null)
    h_in=$(jq -r '.haiku_input_tokens // 0' "$USAGE" 2>/dev/null)
    h_out=$(jq -r '.haiku_output_tokens // 0' "$USAGE" 2>/dev/null)
    el_chars=$(jq -r '.elevenlabs_characters // 0' "$USAGE" 2>/dev/null)
    echo "  quips generated: $quips"
    echo "  haiku input tokens: $h_in"
    echo "  haiku output tokens: $h_out"
    echo "  elevenlabs characters: $el_chars"
    first_used=$(jq -r '.first_used // ""' "$USAGE" 2>/dev/null)
    # Approximate cost: Haiku $1/MTok in, $5/MTok out; ElevenLabs ~$0.30/1k chars
    cost=$(python3 -c "
from datetime import date
h_in=$h_in; h_out=$h_out; el=$el_chars
haiku_cost = (h_in / 1_000_000) * 1.0 + (h_out / 1_000_000) * 5.0
el_cost = (el / 1000) * 0.30
total = haiku_cost + el_cost
print(f'  approx cost: \${total:.4f} (haiku \${haiku_cost:.4f} + elevenlabs \${el_cost:.4f})')
first = '$first_used'
if first:
    try:
        d = date.fromisoformat(first)
        days = max((date.today() - d).days, 1)
        per_day = total / days
        print(f'  avg cost/day: \${per_day:.4f} (over {days} day{\"s\" if days != 1 else \"\"})')
    except: pass
" 2>/dev/null)
    echo "$cost"
    echo ""
fi

echo "=== Playlist Status ==="
for pl in .playlist .session_playlist .resume_playlist .compact_playlist .wiped_playlist .question_playlist .plan_playlist .error_playlist .permission_playlist; do
    if [ -f "$AUDIO_DIR/$pl" ]; then
        remaining=$(wc -l < "$AUDIO_DIR/$pl" | tr -d ' ')
        echo "$pl: $remaining clips remaining before reshuffle"
    else
        echo "$pl: not yet initialized"
    fi
done
