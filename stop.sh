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
	kill `cat "$MONITOR_PID" 2>/dev/null` 2>/dev/null
fi

while kill -0 `cat "$MONITOR_PID" 2>/dev/null` 2>/dev/null; do
	sleep 1
done

for i in 1 2 3; do
	[ -e "$MONITOR_JOURNAL" ] || break
	sleep 1
done

if [ -e "$MONITOR_JOURNAL" ]; then
	echo "The monitor has crashed. Cleaning up."
	rm -f "$MONITOR_JOURNAL" "$MONITOR_PID"
fi

exit 0
