#!/bin/bash
# Play audio clip with global queue (only one clip plays at a time across all instances)
# Cross-platform: uses afplay on macOS, mpv/ffplay/paplay/aplay on Linux
# Usage: marvin-play.sh <clip> <pid_file> [cancel_file]
CLIP="$1"
PID_FILE="$2"
CANCEL_FILE="$3"

if [ -z "$CLIP" ] || [ ! -f "$CLIP" ]; then
    exit 0
fi

python3 -c "
import subprocess, sys, os, signal, shutil, fcntl

clip = sys.argv[1]
pid_file = sys.argv[2] if len(sys.argv) > 2 else None
cancel_file = sys.argv[3] if len(sys.argv) > 3 else None

LOCK_FILE = '/tmp/marvin-audio.lock'

# Acquire global audio lock - blocks until any other clip finishes
lock_fd = open(LOCK_FILE, 'w')
fcntl.flock(lock_fd, fcntl.LOCK_EX)

# If a cancel file was provided, check it after acquiring the lock.
# This handles the case where permission was accepted while we were queued.
if cancel_file and os.path.exists(cancel_file):
    lock_fd.close()
    sys.exit(0)

# Kill previous clip on same pid_file
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
        lock_fd.close()
        sys.exit(0)

# Play in new session (killable by PID from other hooks)
p = subprocess.Popen(
    player,
    stdin=subprocess.DEVNULL,
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
    start_new_session=True
)

# Save PID so kill hooks can stop this clip
if pid_file:
    with open(pid_file, 'w') as f:
        f.write(str(p.pid))

# Wait for playback to finish before releasing the lock.
# This ensures clips from different instances play sequentially.
# If the process is killed (e.g. by marvin-kill-permission.sh), wait() returns
# immediately, releasing the lock for the next queued clip.
p.wait()
lock_fd.close()
" "$CLIP" "$PID_FILE" "$CANCEL_FILE"
