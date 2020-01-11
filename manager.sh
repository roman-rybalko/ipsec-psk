#!/bin/sh

set -e
set -x

conf="$1"
cconf="$2"
if [ -z "$conf" -o -z "$cconf" ]; then
	echo "USAGE: $0 account.conf common.conf"
	exit 1
fi

. "$conf"
. "$cconf"

if [ -z "$SERVER" ]; then
	# client
	dir1="out"
	dir2="in"
	dir="src"
else
	# server
	dir1="in"
	dir2="out"
	dir="dst"
fi

ip xfrm state deleteall spi $USER
ip xfrm policy deleteall dst $SRV_ADDR proto $SRV_PROTO dport $SRV_PORT dir $dir1
ip xfrm policy deleteall src $SRV_ADDR proto $SRV_PROTO sport $SRV_PORT dir $dir2

[ -z "$CLEAR_ONLY" ] || exit 0

for i in 1 2 3; do
	! [ -e "$MONITOR_JOURNAL" ] || break
	sleep 1
done

if ! [ -e "$MONITOR_JOURNAL" ]; then
	echo "Please run monitor."
	exit 1
fi

if [ -n "$SERVER" ]; then
	# server
	ip xfrm state add dst $SRV_ADDR proto esp spi $USER enc "$ENC_ALG" "$PASSWORD" mode transport
fi

ip xfrm policy add dst $SRV_ADDR proto $SRV_PROTO dport $SRV_PORT dir $dir1 tmpl proto esp spi $USER mode transport
ip xfrm policy add src $SRV_ADDR proto $SRV_PROTO sport $SRV_PORT dir $dir2 tmpl proto esp spi $USER mode transport

pos=
while [ -e "$MONITOR_JOURNAL" ]; do
	[ -n "$pos" ] || pos=`stat -c %s "$MONITOR_JOURNAL"`
	while [ -e "$MONITOR_JOURNAL" ]; do
		new_pos=`stat -c %s "$MONITOR_JOURNAL"`
		[ -n "$new_pos" ]
		[ $new_pos = $pos ] || break
		sleep 1 # poll 1/freq
	done
	spi=
	dd skip=$pos count=$(($new_pos-$pos)) bs=1 if="$MONITOR_JOURNAL" 2>/dev/null | while read line; do
		if echo $line | grep acquire >/dev/null; then
			spi=`echo "$line" | sed -r "s/.+ spi ([^[:space:]]+).*/\1/"`
			cli_addr=
		elif echo $line | grep "sel src" >/dev/null; then
			cli_addr=`echo $line | sed -r "s/.+ $dir ([0-9a-fA-F:.]+).*/\1/"`
		fi
		if [ -n "$spi" -a -n "$cli_addr" ]; then
			if [ $spi = $USER ]; then
				if [ -z "$SERVER" ]; then
					# client
					ip xfrm state update dst $SRV_ADDR proto esp spi $USER enc "$ENC_ALG" "$PASSWORD" mode transport sel dst $SRV_ADDR proto $SRV_PROTO dport $SRV_PORT
					ip xfrm state get dst $cli_addr proto esp spi $USER >/dev/null 2>&1 ||
						ip xfrm state add dst $cli_addr proto esp spi $USER enc "$ENC_ALG" "$PASSWORD" mode transport
				else
					# server
					ip xfrm state update dst $cli_addr proto esp spi $USER enc "$ENC_ALG" "$PASSWORD" mode transport sel dst $cli_addr proto $SRV_PROTO sport $SRV_PORT
				fi
			fi
			spi=
		fi
	done
	pos=$new_pos
done

exit 0
