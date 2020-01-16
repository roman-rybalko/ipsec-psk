#!/bin/sh

set -e
set -x

cd "`dirname "$0"`"
umask 0077

./stop.sh ./common.conf

./monitor.sh ./common.conf &
./manager.sh ./account1.conf ./common.conf &
./manager.sh ./account2.conf ./common.conf &
./manager.sh ./account3.conf ./common.conf &

exit 0
