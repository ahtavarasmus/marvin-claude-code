#!/bin/bash
# Play audio clip in a fully detached process (new session/process group)
# Usage: marvin-play.sh <clip> <pid_file>
CLIP="$1"
PID_FILE="$2"

if [ -z "$CLIP" ] || [ ! -f "$CLIP" ]; then
    exit 0
fi

# Kill previous clip if still playing
if [ -n "$PID_FILE" ] && [ -f "$PID_FILE" ]; then
    kill "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null
fi

# Launch afplay in a new session, fully detached from hook runner
perl -e '
use POSIX "setsid";
my $pid = fork;
if ($pid) {
    if ($ARGV[1]) {
        open(F, ">", $ARGV[1]);
        print F $pid;
        close(F);
    }
    exit 0;
}
setsid();
open STDIN, "<", "/dev/null";
open STDOUT, ">", "/dev/null";
open STDERR, ">", "/dev/null";
exec "afplay", $ARGV[0];
' "$CLIP" "$PID_FILE"
