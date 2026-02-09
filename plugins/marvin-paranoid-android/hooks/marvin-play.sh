#!/bin/bash
# Play audio clip in a fully detached process (new session/process group)
# Cross-platform: uses afplay on macOS, mpv/ffplay/paplay/aplay on Linux
# Usage: marvin-play.sh <clip> <pid_file>
CLIP="$1"
PID_FILE="$2"

if [ -z "$CLIP" ] || [ ! -f "$CLIP" ]; then
    exit 0
fi

python3 -c "
import subprocess, sys, os, signal, shutil

clip = sys.argv[1]
pid_file = sys.argv[2] if len(sys.argv) > 2 else None

# Kill previous clip
if pid_file:
    try:
        with open(pid_file) as f:
            os.kill(int(f.read().strip()), signal.SIGTERM)
    except:
        pass

# Find audio player
if sys.platform == 'darwin':
    player = ['/usr/bin/afplay', clip]
else:
    for cmd in ['mpv --no-video', 'ffplay -nodisp -autoexit', 'paplay', 'aplay']:
        parts = cmd.split()
        if shutil.which(parts[0]):
            player = parts + [clip]
            break
    else:
        sys.exit(0)

# Play fully detached in new session
p = subprocess.Popen(
    player,
    stdin=subprocess.DEVNULL,
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
    start_new_session=True
)

# Save PID
if pid_file:
    with open(pid_file, 'w') as f:
        f.write(str(p.pid))
" "$CLIP" "$PID_FILE"
