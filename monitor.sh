#!/bin/sh

set -e
set -x

conf="$1"
if [ -z "$conf" ]; then
	echo "USAGE: $0 common.conf"
	exit 1
fi

. "$conf"

if [ -e "$MONITOR_JOURNAL" ]; then
	if kill -0 `cat "$MONITOR_PID" 2>/dev/null` 2>/dev/null; then
		echo "`ip xfrm monitor` seems already running."
		echo "Please kill it & remove $MONITOR_JOURNAL file."
		exit 1
	fi
fi

ip xfrm monitor acquire >"$MONITOR_JOURNAL" &
echo $! >"$MONITOR_PID"

wait || true

rm -f "$MONITOR_JOURNAL" "$MONITOR_PID"

exit 0
