#!/bin/sh -e

# into /etc/rc.local

# mount drive
if test "MOUNTPOINT" = "`/bin/lsblk -oMOUNTPOINT /dev/sda5 2>/dev/null`"; then
	/usr/bin/udisksctl mount -b /dev/sda5
fi
