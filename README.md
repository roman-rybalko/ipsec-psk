# IPsec Pre-Shared Key (PSK) Manager
Maintains an encrypted connection to a specific **address:port** with a symmetric **login/password**.
 - Implemented in pure **shell**
 - Uses **iproute2** - `ip xfrm`

## Concept
**SPI** is a **login** (user name).
**[ALGO-KEYMAT](http://man7.org/linux/man-pages/man8/ip-xfrm.8.html)** is a **password**.
The same **SPI** value is used for both **in** & **out** directions.
Due to **IPv6** [temporary address](https://tools.ietf.org/html/rfc4941#section-1.2) changes **SAD** entries need to be periodically updated.
Uses `ip xfrm monitor acquire` notifications to update **SAD** entries.

Maintaining different **SPI** values (different logins) for a single listening port requires additional support by OS framework (either **xfrm** or **iptables**).

Considered **xfrm** [internal](https://paulgorman.org/technical/ipsec.txt.html) index:
  1. Hash table by (spi,daddr,ah/esp) to find SA by SPI. (input,ctl)
  2. Hash table by (daddr,family,reqid) to find what SAs exist for given
     destination/tunnel endpoint. (output)

## Limitations
 - Supports **ESP** encryption only (neither **AH** nor **ESP auth**)
 - Supports **transport** mode only
 - Supports only a single **SPI** (single login but multiple users allowed) per a distinct listening port
 - Network Address Translation (**NAT**) is not supported
 - Due to limited event poll frequency initial connection establishing takes at least 2 seconds
 - Stale **SAD** entries are not cleared
 - Tested with **IPv6** only
 - Tested on **Linux** 3.1x.x & **Android** 7 only

## Usage
There are two components: **monitor** & **manager**.

### Client
Start:
```
# ./monitor.sh ./common.conf &
# ./manager.sh ./account1.conf ./common.conf &
# ./manager.sh ./account2.conf ./common.conf &
# ./manager.sh ./account3.conf ./common.conf &
```
Stop:
```
# ./stop.sh ./common.sh
```

### Server
Start:
```
# ./monitor.sh ./common.conf &
# SERVER=1 ./manager.sh ./account1.conf ./common.conf &
# SERVER=1 ./manager.sh ./account2.conf ./common.conf &
# SERVER=1 ./manager.sh ./account3.conf ./common.conf &
```
Stop:
```
# ./stop.sh ./common.sh
```

### Sample configuration: common.conf
```
MONITOR_PID=/tmp/ipsec-psk-mgr.pid
MONITOR_JOURNAL=/tmp/ipsec-psk-mgr.jnl
# CLEAR_ONLY=1
# SERVER=1
```

### Sample configuration: account1.conf
```
SRV_ADDR=2a04:ac00:4:5fbb:5054:ff:fe01:bab1
SRV_PROTO=tcp
SRV_PORT=10000

# spi - use the same format as provided by `ip xfrm policy show`
USER=0x00000001

# encryption key - strictly 16 chars (for ENC_ALG=aes)
PASSWORD=1234567890123456

# ALGO-LIST - http://man7.org/linux/man-pages/man8/ip-xfrm.8.html
ENC_ALG="cbc(aes)"
```
